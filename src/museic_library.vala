public class MuseicLibrary {

    private string path;
    private File file;
    private MuseicFile[] museic_files;
    private int nfiles=0;

    public MuseicLibrary (string path) {
        // Check if file exists. If it doesn't, create it.
        this.path = path;
        this.file = File.new_for_path(path);

        if (!file.query_exists()) file.create(FileCreateFlags.NONE);
    }

    public MuseicFile[] get_library_files() {
        if (this.museic_files != null) return this.museic_files[0:this.nfiles];
        this.museic_files = new MuseicFile[5];
        this.nfiles = 0;
        try {
            DataInputStream reader = new DataInputStream(this.file.read());
            string line;
            File aux;
            while ((line=reader.read_line(null)) != null) {
                aux = File.new_for_path(line.split(";")[0]);
                if (aux.query_exists()) {
                    if (this.museic_files.length == this.nfiles) this.museic_files.resize(this.museic_files.length*2);
                    this.museic_files[this.nfiles] = new MuseicFile.from_data(line.split(";")[0], line.split(";")[1], line.split(";")[2], line.split(";")[3], "unknown", "unknown", "filelist");
                    this.nfiles++;
                }
            }
        }catch (Error e){
            error("%s", e.message);
        }
        return this.museic_files[0:nfiles];
    }

    public void add_files(string[] files, bool filter_repeated) {
        foreach (string file in files) if (!filter_repeated || (filter_repeated && !is_in_filelist(file))) add_file(file);
    }

    public void add_file(string filename) {
        if (this.nfiles == this.museic_files.length) this.museic_files.resize(this.museic_files.length*2);
        MuseicFile aux = new MuseicFile(filename, "filelist");
        this.museic_files[this.nfiles] = aux;
        this.nfiles += 1;
        FileIOStream io = this.file.open_readwrite();
        io.seek (0, SeekType.END);
        var writer = new DataOutputStream(io.output_stream);
        writer.put_string(aux.path+";"+aux.name+";"+aux.artist+";"+aux.album+"\n");

    }

    public bool is_in_filelist(string filename) {
        foreach (MuseicFile file in this.museic_files[0:this.nfiles]) if (file.path == filename) return true;
        return false;
    }

    public void clear() {
        this.file.delete();
        file.create(FileCreateFlags.NONE);
    }


}
