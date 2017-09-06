
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
        var file_stream = file.read ();
        var data_stream = new DataInputStream (file_stream);
        data_stream.set_byte_order (DataStreamByteOrder.LITTLE_ENDIAN);

        // Read signature (check if file is ID3)
        BytesInfo info = get_rep_of_bytes(data_stream, 3);
        if (info.rep != "ID3") {
            stderr.printf ("Error: %s is not a valid ID3 file\n", file.get_basename ());
            if (path.split("/").length > 1) this.name = path.split("/")[path.split("/").length-1];
            else this.name = path;
            stdout.printf("INFO: %s processed\n", this.path);
            return;
        }
        // Read ID3 version (check if file is v2.3)
        info = get_rep_of_bytes(data_stream, 2);
        if (info.bytes_str != ".3.0") {
            stderr.printf ("Error: %s is not ID3v2.3 version file\n", file.get_basename ());
            if (path.split("/").length > 1) this.name = path.split("/")[path.split("/").length-1];
            else this.name = path;
            stdout.printf("INFO: %s processed\n", this.path);
            return;
        }
        // Read flags (don't used)
        get_rep_of_bytes(data_stream, 1);

        // Read and calc. tags size
        info = get_rep_of_bytes(data_stream, 4);
        long size = calc_id3_tag_size(info);

        // Read all the frames of the tag and fill used information.
        long readed_bytes = 0;
        int found = 0;
        BytesInfo tag_header, tag_size;
        long tsize;
        int count = 0;
        while (readed_bytes < size) {
            // tag name
            tag_header = get_rep_of_bytes(data_stream, 4);
            // tag size
            tag_size = get_rep_of_bytes(data_stream, 4);
            tsize = bytes_to_dec(tag_size.bytes);
            if (tsize > 0) { // I don't know why but this happens...
                // tag flags (don't used)
                get_rep_of_bytes(data_stream, 2);
                // read tag content
                info = get_rep_of_bytes(data_stream, tsize);
                // update readed bytes
                readed_bytes += (10 + tsize);
                if (tag_header.rep == "TOPE") { // artist
                    this.artist = info.rep[3:info.rep.length];found+=1;
                    // stdout.printf("TOPE:\n    rep=|"+info.rep+"|\n    bytes=|"+info.bytes_str+"|\n");
                }else if (tag_header.rep == "TALB") { // album
                    this.album = info.rep[3:info.rep.length];found+=1;
                    // stdout.printf("TALB:\n    rep=|"+info.rep+"|\n    bytes=|"+info.bytes_str+"|\n");
                }else if (tag_header.rep == "TOAL") { // album2
                    if (this.album == "unknown") {this.album = info.rep[3:info.rep.length];found+=1;}
                    // stdout.printf("TOAL:\n    rep=|"+info.rep+"|\n    bytes=|"+info.bytes_str+"|\n");
                }else if (tag_header.rep == "TIME") { // time
                    // stdout.printf("TIME:\n    rep=|"+info.rep+"|\n    bytes=|"+info.bytes_str+"|\n");
                }else if (tag_header.rep == "TLEN") { // length
                    this.duration = info.rep;
                    // stdout.printf("TLEN:\n    rep=|"+info.rep+"|\n    bytes=|"+info.bytes_str+"|\n");
                }else if(tag_header.rep == "TPE1") { // leader
                    if (this.artist == "unknown") {this.artist = info.rep[3:info.rep.length];found+=1;}
                    // stdout.printf("TPE1:\n    rep=|"+info.rep+"|\n    bytes=|"+info.bytes_str+"|\n");
                }else if(tag_header.rep == "TPOS") { // part of set
                    // stdout.printf("TPOS:\n    rep=|"+info.rep+"|\n    bytes=|"+info.bytes_str+"|\n");
                }else if(tag_header.rep == "APIC") { // image
                    this.image = info.rep;
                    //stdout.printf("APIC:\n    rep=|"+info.rep+"|\n    bytes=|"+info.bytes_str+"|\n");
                }else if(tag_header.rep == "TIT1") { // group desc.
                    // stdout.printf("TIT1:\n    rep=|"+info.rep+"|\n    bytes=|"+info.bytes_str+"|\n");
                }else if(tag_header.rep == "TIT2") { // songname desc.
                    if (this.name == "unknown") {this.name = info.rep[3:info.rep.length];found+=1;}
                    // stdout.printf("TIT2:\n    rep=|"+info.rep+"|\n    bytes=|"+info.bytes_str+"|\n");
                }else if(tag_header.rep == "TIT3") { // subtitle refinement
                    // stdout.printf("TIT3:\n    rep=|"+info.rep+"|\n    bytes=|"+info.bytes_str+"|\n");
                }else if (tag_header.rep != "" && tag_header.rep != "TXXX") {
                    // stdout.printf("OTHER:\n    rep=|"+info.rep+"|\n    bytes=|"+info.bytes_str+"|\n");
                }
            }else {
                count ++;
            }
            // Check if we already have all the information that we want
            if (found == 3 || count > 3) readed_bytes = size;
        }
        if (this.name == "unknown") {
            if (path.split("/").length > 1) this.name = path.split("/")[path.split("/").length-1];
            else this.name = path;
        }
        stdout.printf("INFO: %s processed\n", this.path);
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

}
