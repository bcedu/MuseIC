public class MuseicLibrary {

    private string path;
    private File file;

    public MuseicLibrary (string path) {
        // Check if file exists. If it doesn't, create it.
        this.path = path;
        this.file = File.new_for_path(path);

        if (!file.query_exists()) file.create(FileCreateFlags.NONE);
    }

    public MuseicFile[] get_library_files_by_artist(string artist) {
        // Returns thhe files from library of the passed artist. If the passed artist
        // is "all", returns all files
        MuseicFile[] museic_files = new MuseicFile[5];
        int nfiles = 0;
        try {
            DataInputStream reader = new DataInputStream(this.file.read());
            string line;
            File aux;
            while ((line=reader.read_line(null)) != null) {
                aux = File.new_for_path(line.split(";")[0]);
                if (aux.query_exists()) {
                    if (museic_files.length == nfiles) museic_files.resize(museic_files.length*2);
                    if (artist == "all" || line.split(";")[2] == artist) {
                        museic_files[nfiles] = new MuseicFile.from_data(line.split(";")[0], line.split(";")[1], line.split(";")[2], line.split(";")[3], line.split(";")[4], "unknown", "filelist");
                        nfiles++;
                    }
                }
            }
        }catch (Error e){
            error("%s", e.message);
        }
        return museic_files[0:nfiles];
    }

    public void add_files(string[] files, bool filter_repeated) {
        foreach (string file in files) if (!filter_repeated || (filter_repeated && !is_in_filelist(file))) add_file(file);
    }

    public void add_file(string filename) {
        if (File.new_for_path(filename).query_exists()) {
            MuseicFile aux = new MuseicFile(filename, "filelist");
            FileIOStream io = this.file.open_readwrite();
            io.seek (0, SeekType.END);
            var writer = new DataOutputStream(io.output_stream);
            writer.put_string(aux.path+";"+aux.name+";"+aux.artist+";"+aux.album+";"+aux.duration+"\n");
        }else stdout.printf("ERROR: %s doesn't exist\n", filename);
    }

    public bool is_in_filelist(string filename) {
        foreach (MuseicFile file in get_library_files_by_artist("all")) if (file.path == filename) return true;
        return false;
    }

    public void clear() {
        this.file.delete();
        file.create(FileCreateFlags.NONE);
    }

    public void delete_files(MuseicFile[] mfiles) {
        // delete files from library
        try {
            DataInputStream reader = new DataInputStream(this.file.read());
            DataOutputStream writer = new DataOutputStream (this.file.replace (null, false, FileCreateFlags.NONE));
            string line;
            bool deleted = false;
            while ((line=reader.read_line(null)) != null) {
                foreach (MuseicFile mfile in mfiles) {
                    if (mfile.path == line.split(";")[0]) {
                        deleted = true;
                        break;
                    }
                }
                if (!deleted) writer.put_string(line+"\n");
                deleted = false;
            }
        }catch (Error e){
            error("%s", e.message);
        }
    }

    public string[] get_artists() {
        // Returns a list with all artists of library
        MuseicFileList aux = new MuseicFileList("aux");
        aux.add_museic_files(this.get_library_files_by_artist("all"), true, "filelist");
        aux.sort_field = "artist";
        aux.sort();
        string[] artists = new string[aux.nfiles];
        int nartists = 0;
        foreach (MuseicFile mfile in aux.get_files_list()) {
            if (nartists == 0 || mfile.artist != artists[nartists-1]) {
                artists[nartists] = mfile.artist;
                nartists++;
            }
        }
        return artists[0:nartists];
    }

    public MuseicFile[] get_library_files_by_search(string search_text) {
        MuseicFile[] museic_files = new MuseicFile[5];
        int nfiles = 0;
        try {
            DataInputStream reader = new DataInputStream(this.file.read());
            string line;
            File aux;
            MuseicFile mfile;
            while ((line=reader.read_line(null)) != null) {
                aux = File.new_for_path(line.split(";")[0]);
                if (aux.query_exists()) {
                    if (museic_files.length == nfiles) museic_files.resize(museic_files.length*2);
                    mfile = new MuseicFile.from_data(line.split(";")[0], line.split(";")[1], line.split(";")[2], line.split(";")[3], line.split(";")[4], "unknown", "filelist");
                    if (this.pass_filter(search_text, mfile)) {
                        museic_files[nfiles] = mfile;
                        nfiles++;
                    }
                }
            }
        }catch (Error e){
            error("%s", e.message);
        }
        return museic_files[0:nfiles];
    }

    private bool pass_filter(string text, MuseicFile file) {
        if (text == "") return true;
        bool filter_passed = true;
        foreach (string aux in text.split(" ")) {
            if ((file.name.down().contains(aux.down()) || file.artist.down().contains(aux.down()) || file.album.down().contains(aux.down())) && filter_passed) filter_passed = true;
            else filter_passed = false;
        }
        return filter_passed;
    }

    public void update_files(MuseicFile[] mfiles, string? new_name, string? new_album, string? new_artist) {
        try {
            DataInputStream reader = new DataInputStream(this.file.read());
            DataOutputStream writer = new DataOutputStream (this.file.replace (null, false, FileCreateFlags.NONE));
            string line;
            File aux;
            string new_line = "";
            bool changed = false;
            while ((line=reader.read_line(null)) != null) {
                foreach (MuseicFile mfile in mfiles) {
                    if (mfile.path == line.split(";")[0]) {
                        new_line = mfile.path+";";
                        if (new_name == null) new_line += mfile.name+";";
                        else new_line += new_name+";";
                        if (new_artist == null) new_line += mfile.artist+";";
                        else new_line += new_artist+";";
                        if (new_album == null) new_line += mfile.album+";";
                        else new_line += new_album+";";
                        changed = true;
                        break;
                    }
                }
                if (changed) writer.put_string(new_line+"\n");
                else writer.put_string(line+"\n");
                changed = false;
            }
        }catch (Error e){
            error("%s", e.message);
        }
    }

}
