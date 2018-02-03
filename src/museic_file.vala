
public struct BytesInfo {
    public string rep;
    public string bytes_str;
    public uint[] bytes;
}

public class MuseicFile {

    public string path;
    public string name = "unknown";
    public string artist = "unknown";
    public string album = "unknown";
    public string duration = "unknown";
    public string image = "unknown";
    public string origin = "unknown";

    public MuseicFile (string path, string origin) {
        this.path = path;
        if (path=="") return;
        this.origin = origin;
        var file = File.new_for_path (path);

        this.duration = this.calc_duration(this.path);
        // stdout.printf("Duration: %s\n", this.duration);

        var file_stream = file.read ();
        var data_stream = new DataInputStream (file_stream);
        data_stream.set_byte_order (DataStreamByteOrder.LITTLE_ENDIAN);

        // Read signature (check if file is ID3)
        BytesInfo info = get_rep_of_bytes(data_stream, 3);
        // stdout.printf("Is ID3?: |%s|\n", info.rep);
        if (info.rep != "ID3") {
            stderr.printf ("Error: %s is not a valid ID3 file\n", file.get_basename ());
            if (path.split("/").length > 1) this.name = path.split("/")[path.split("/").length-1];
            else this.name = path;
            // stdout.printf("INFO: %s processed\n", this.path);
            return;
        }
        // Read ID3 version (check if file is v2.3)
        info = get_rep_of_bytes(data_stream, 2);
        // stdout.printf("Is ID3 v3.0?: |%s||%s|\n", info.rep, info.bytes_str);
        if (info.bytes_str != ".3.0") {
            stderr.printf ("Error: %s is not ID3v2.3 version file\n", file.get_basename ());
            if (path.split("/").length > 1) this.name = path.split("/")[path.split("/").length-1];
            else this.name = path;
            // stdout.printf("INFO: %s processed\n", this.path);
            return;
        }
        // Read flags (don't used)
        info = get_rep_of_bytes(data_stream, 1);
        // stdout.printf("Unused bytes: |%s||%s|\n", info.rep, info.bytes_str);
        // Read and calc. tags size
        info = get_rep_of_bytes(data_stream, 4);
        long size = calc_id3_tag_size(info);
        // stdout.printf("Tags size: bytes:|%s||%s|, calculated:|%s|\n", info.rep, info.bytes_str, size.to_string());

        // Read all the frames of the tag and fill used information.
        long readed_bytes = 0;
        int found = 0;
        BytesInfo tag_header, tag_size;
        long tsize;
        string content;
        while (readed_bytes < size) {
            // tag name
            tag_header = get_rep_of_bytes(data_stream, 4);
            // tag size
            tag_size = get_rep_of_bytes(data_stream, 4);
            tsize = bytes_to_dec(tag_size.bytes);
            if (tsize > 0) { // I don't know why but this happens...
                // stdout.printf("Tags:|%s||%s|, size:|%s|\n", tag_header.rep, tag_header.bytes_str, tsize.to_string());
                // tag flags (don't used)
                info = get_rep_of_bytes(data_stream, 2);
                // stdout.printf("    unused flags: |%s||%s|\n", info.rep, info.bytes_str);
                // read tag content
                if (tsize > 10000) {
                    // Currently tags with a large size aren't suported because in get_rep_of_bytes() make program stop responding, so I skip them.
                    readed_bytes += (10 + tsize);
                }else {
                    info = get_rep_of_bytes(data_stream, tsize);
                    // stdout.printf("    tag content: |%s||%s|\n", info.rep, info.bytes_str);
                    // update readed bytes
                    readed_bytes += (10 + tsize);
                    // For some reason there are tags contents that start with bytes 1 255 254 (unprintable bytes), I skip them;
                    if (info.bytes_str.length > 10 && info.bytes_str[0:10] == ".1.255.254") content = info.rep[3:info.rep.length];
                    else if (info.rep == "") content = "unknown"; // some tags are fucking bullshit and they are empty....
                    else content = info.rep;
                    if (tag_header.rep == "TOPE") { // artist
                        this.artist = content;found+=1;
                        // stdout.printf("TOPE:\n    rep=|"+info.rep+"|\n    bytes=|"+info.bytes_str+"|\n");
                    }else if (tag_header.rep == "TALB") { // album
                        this.album = content;found+=1;
                        // stdout.printf("TALB:\n    rep=|"+info.rep+"|\n    bytes=|"+info.bytes_str+"|\n");
                    }else if (tag_header.rep == "TOAL") { // album2
                        if (this.album == "unknown") {this.album = content;found+=1;}
                        // stdout.printf("TOAL:\n    rep=|"+info.rep+"|\n    bytes=|"+info.bytes_str+"|\n");
                    }else if (tag_header.rep == "TIME") { // time
                        // stdout.printf("TIME:\n    rep=|"+info.rep+"|\n    bytes=|"+info.bytes_str+"|\n");
                    }else if (tag_header.rep == "TLEN") { // length
                        // this.duration = info.rep;
                        // stdout.printf("TLEN:\n    rep=|"+info.rep+"|\n    bytes=|"+info.bytes_str+"|\n");
                    }else if(tag_header.rep == "TPE1") { // leader
                        if (this.artist == "unknown") {this.artist = content;found+=1;}
                        // stdout.printf("TPE1:\n    rep=|"+info.rep+"|\n    bytes=|"+info.bytes_str+"|\n");
                    }else if(tag_header.rep == "TPOS") { // part of set
                        // stdout.printf("TPOS:\n    rep=|"+info.rep+"|\n    bytes=|"+info.bytes_str+"|\n");
                    }else if(tag_header.rep == "APIC") { // image
                        this.image = info.rep;
                        //stdout.printf("APIC:\n    rep=|"+info.rep+"|\n    bytes=|"+info.bytes_str+"|\n");
                    }else if(tag_header.rep == "TIT1") { // group desc.
                        // stdout.printf("TIT1:\n    rep=|"+info.rep+"|\n    bytes=|"+info.bytes_str+"|\n");
                    }else if(tag_header.rep == "TIT2") { // songname desc.
                        if (this.name == "unknown") {this.name = content;found+=1;}
                        // stdout.printf("TIT2:\n    rep=|"+info.rep+"|\n    bytes=|"+info.bytes_str+"|\n");
                    }else if(tag_header.rep == "TIT3") { // subtitle refinement
                        // stdout.printf("TIT3:\n    rep=|"+info.rep+"|\n    bytes=|"+info.bytes_str+"|\n");
                    }else if (tag_header.rep != "" && tag_header.rep != "TXXX") {
                        // stdout.printf("OTHER:\n    rep=|"+info.rep+"|\n    bytes=|"+info.bytes_str+"|\n");
                    }
                }
            }
            // Check if we already have all the information that we want
            // if (found == 3) readed_bytes = size;
        }
        if (this.name == "unknown") {
            if (path.split("/").length > 1) this.name = path.split("/")[path.split("/").length-1];
            else this.name = path;
        }
        if (this.artist != "unknown") this.artist = this.clean_name(this.artist);
        if (this.album == "unknown") this.album = this.artist;
    }

    public MuseicFile.from_museicfile (MuseicFile file) {
        this.path = file.path;
        this.name = file.name;
        this.artist = file.artist;
        this.album = file.album;
        this.duration = file.duration;
        this.image = file.image;
        this.origin = file.origin;
    }

    public MuseicFile.from_data (string apath, string aname, string aartist, string aalbum, string aduration, string aimage, string aorigin) {
        this.path = apath;
        this.name = aname;
        this.artist = aartist;
        this.album = aalbum;
        this.duration = aduration;
        this.image = aimage;
        this.origin = aorigin;
    }

    private BytesInfo get_rep_of_bytes(DataInputStream src, long nbytes) {
        string rep = "";
        string str = "";
        uint[] bytes = new uint[nbytes];
        for (int i=0;i<nbytes;i++) {
            bytes[i] = src.read_byte();
            rep = rep + ((char)bytes[i]).to_string();
            str = str +"."+ bytes[i].to_string();
        }
        return {rep, str, bytes};
    }

    private long calc_id3_tag_size(BytesInfo info) {
        string final_bin = "0000";
        string aux;
        for (int i=0;i<4;i++) {
            aux = dec_to_bin(info.bytes[i]);
            final_bin += aux[1:aux.length];
        }
        return bin_to_dec(final_bin);
    }

    private string dec_to_bin(uint num) {
        if (num <= 1) return "0000000"+num.to_string();
        uint res;
        string bin = "";
        while (num > 1) {
            res = num%2;
            num = num/2;
            bin = res.to_string() + bin;
        }
        bin = num.to_string() + bin;
        while (bin.length % 8 != 0) bin = "0"+bin;
        return bin;
    }

    private long bin_to_dec(string bin) {
        long num = 0;
        long pot;
        for (int i=0;i<bin.length;i++) {
            if (bin.get_char(i).to_string() == "1"){
                pot = 1;
                for (int y=0; y < (bin.length-1-i); y++) pot = pot*2;
                num += pot;
            }
        }
        return num;
    }

    private long bytes_to_dec(uint[] bytes) {
        string bin = "";
        for (int i=0;i<bytes.length;i++) bin += dec_to_bin(bytes[i]);
        return bin_to_dec(bin);
    }

    private string calc_duration(string path) {
        int64 aux_duration = 0;
        dynamic Gst.Element aux_player = Gst.ElementFactory.make ("playbin", "play");
        aux_player.uri = "file://"+path;
        aux_player.set_state (Gst.State.PAUSED);
        int aux = 0;
        bool success = aux_player.query_duration (Gst.Format.TIME, out aux_duration);
        int atempts = 0;
        while (!success && atempts < 10000) {
            if (!success) while (aux<100) aux = aux+1;
            aux = 0;
            success = aux_player.query_duration (Gst.Format.TIME, out aux_duration);
            atempts += 1;
        }
        aux_player.set_state (Gst.State.NULL);
        aux_player = null;
        return nanoseconds_to_minutes_string((ulong)aux_duration);
    }

    private string nanoseconds_to_minutes_string(ulong nanoseconds) {
        // Given nanoseconds, transform to minutes and seconds and returns in string with format %M:%S
        int total_seconds = (int)(nanoseconds / 1000000000);
        int minutes = total_seconds / 60;
        int seconds = total_seconds % 60;
        string smin = minutes < 10 ? "0"+minutes.to_string () : minutes.to_string ();
        string ssec = seconds < 10 ? "0"+seconds.to_string () : seconds.to_string ();
        return smin+":"+ssec;
    }

    public int compare(MuseicFile file, string field) {
        // Returns 1 if this is greater, 0 if thery are equal and -1 if this is smaller.
        // Comparations is made using the atribut named like "field"
        if (field == "album") {
            if (this.album > file.album) return 1;
            else if (this.album == file.album) return this.compare(file, "name");
            else return -1;
        }else if (field == "artist") {
            if (this.artist > file.artist) return 1;
            else if (this.artist == file.artist) return this.compare(file, "album");
            else return -1;
        }else { // "name" (it is also the default for unreconized passed field)
            if (this.name > file.name) return 1;
            else if (this.name == file.name) return 0;
            else return -1;
        }
    }

    public string clean_name(string name) {
        string aux = name.strip();
        if (!aux.validate()) return aux;
        string res = "";
        bool previous_is_space = true;
        unichar c = 0;
        int index = 0;
        for (int cnt = 0; aux.get_next_char (ref index, out c); cnt++) {
            if (previous_is_space && c != ' ') c = c.toupper();
            if (c.validate()) res = "%s%s".printf(res, c.to_string());
            previous_is_space = c == ' ';
        }
        return res;
    }

}
