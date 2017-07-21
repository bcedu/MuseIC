public class MuseicFileList {

    public int filepos = -1;
    private MuseicFile[] files_list = new MuseicFile[4];
    public int nfiles = 0;

    public MuseicFileList () {}

    public void add_files(string[] filenames, bool clean_filelist) {
        if (clean_filelist) {
            this.files_list = new MuseicFile[filenames.length+1];
            this.filepos = 0;
        }
        foreach (string filename in filenames) add_file(filename);
    }

    public void add_file(string filename) {
        if (this.nfiles == this.files_list.length) this.files_list.resize(this.files_list.length*2);
        this.files_list[this.nfiles] = new MuseicFile(filename);
        this.nfiles += 1;
    }

    public MuseicFile get_current_file() {
        if (filepos < 0) return new MuseicFile("");
        else return this.files_list[this.filepos];
    }

    public MuseicFile[] get_files_list() {
        return this.files_list[0:this.nfiles];
    }

    public MuseicFile seg_file() {
        this.filepos += 1;
        if (this.filepos >= this.nfiles) this.filepos = 0;
        return get_current_file();
    }

    public MuseicFile ant_file() {
        this.filepos -= 1;
        if (this.filepos < 0) this.filepos = this.nfiles-1;
        return get_current_file();
    }

}
