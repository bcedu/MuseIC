public class MuseicLibrary {

    private string path;
    private File file;
    private string[] filenames;
    private int nfiles=0;

    public MuseicLibrary (string path) {
        // Check if file exists. If it doesn't, create it.
        this.path = path;
        this.file = File.new_for_path(path);

        if (!file.query_exists()) file.create(FileCreateFlags.NONE);
    }

    public string[] get_library_filenames() {
        if (this.filenames != null) return this.filenames[0:this.nfiles];
        this.filenames = new string[5];
        this.nfiles = 0;
        try {
            DataInputStream reader = new DataInputStream(this.file.read());
            string line;
            while ((line=reader.read_line(null)) != null) {
                if (this.filenames.length == this.nfiles) this.filenames.resize(this.filenames.length*2);
                this.filenames[this.nfiles] = line;
                this.nfiles++;
            }
        }catch (Error e){
            error("%s", e.message);
        }
        return this.filenames[0:nfiles];
    }

    public void add_files(string[] files, bool filter_repeated) {
        foreach (string file in files) if (!filter_repeated || (filter_repeated && !is_in_filelist(file))) add_file(file);
    }

    public void add_file(string filename) {
        if (this.nfiles == this.filenames.length) this.filenames.resize(this.filenames.length*2);
        this.filenames[this.nfiles] = filename;
        this.nfiles += 1;
        FileIOStream io = this.file.open_readwrite();
        io.seek (0, SeekType.END);
        var writer = new DataOutputStream(io.output_stream);
        writer.put_string(filename+"\n");

    }

    public bool is_in_filelist(string filename) {
        foreach (string file in this.filenames[0:this.nfiles]) if (file == filename) return true;
        return false;
    }

    public void clear() {
        this.file.delete();
        file.create(FileCreateFlags.NONE);
    }


}
