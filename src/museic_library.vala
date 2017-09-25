public class MuseicLibrary {

    private string path;
    private File file;

    public MuseicLibrary (string path) {
        // Check if file exists. If it doesn't, create it.
        this.path = path;
        this.file = File.new_for_path(path);

        if (!file.query_exists()) file.create(FileCreateFlags.NONE);
    }

    public MuseicFile[] get_library_files() {
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
                    museic_files[nfiles] = new MuseicFile.from_data(line.split(";")[0], line.split(";")[1], line.split(";")[2], line.split(";")[3], "unknown", "unknown", "filelist");
                    nfiles++;
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
            writer.put_string(aux.path+";"+aux.name+";"+aux.artist+";"+aux.album+"\n");
        }else stdout.printf("ERROR: %s doesn't exist\n", filename);
    }

    public bool is_in_filelist(string filename) {
        foreach (MuseicFile file in get_library_files()) if (file.path == filename) return true;
        return false;
    }

    public void clear() {
        this.file.delete();
        file.create(FileCreateFlags.NONE);
    }

    public string[] get_artists() {
        // Returns a list with all artists of library
        MuseicFileList aux = new MuseicFileList();
        aux.add_museic_files(this.get_library_files(), true, "filelist");
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

}
