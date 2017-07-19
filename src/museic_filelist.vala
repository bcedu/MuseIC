public class FileList {

    public int filepos = -1;
    public string[] files_list = new string[4];
    public int nfiles = 0;

    public FileList () {}

    public void add_files(string[] filenames, bool clean_filelist) {
        if (!clean_filelist) {
            foreach (string filename in filenames) add_file(filename);
        }else {
            if (this.files_list.length < filenames.length) this.files_list.resize(filenames.length+1);
            this.files_list = filenames;
            this.nfiles = filenames.length;
            this.filepos = 0;
        }
    }

    public void add_file(string filename) {
        if (this.nfiles == this.files_list.length) this.files_list.resize(this.files_list.length*2);
        this.files_list[this.nfiles] = filename;
        this.nfiles += 1;
    }

    public string get_current_file() {
        if (filepos < 0) return "";
        else return this.files_list[this.filepos];
    }

    public string seg_file() {
        this.filepos += 1;
        if (this.filepos >= this.nfiles) this.filepos = 0;
        return get_current_file();
    }

    public string ant_file() {
        this.filepos -= 1;
        if (this.filepos < 0) this.filepos = this.nfiles-1;
        return get_current_file();
    }

}
