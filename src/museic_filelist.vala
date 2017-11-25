public class MuseicFileList {

    public int filepos = -1;
    private MuseicFile[] files_list = new MuseicFile[4];
    public int nfiles = 0;
    public bool random_state = false;
    private int sorted = 0; // -1 -> desc, 0 -> not sorted, 1 -> asc
    public string sort_field = "name"; // name | artist | album
    public string name;

    public MuseicFileList (string name) {
        this.name = name;
    }

    public void add_files(string[] filenames, bool filter_repeated, string origin) {
        foreach (string filename in filenames) if (!filter_repeated || (filter_repeated && !is_in_filelist(filename))) add_file(filename, origin);
    }

    public bool is_in_filelist(string filename) {
        foreach (MuseicFile file in get_files_list()) if (file.path == filename) return true;
        return false;
    }

    public void add_file(string filename, string origin) {
        if (this.nfiles == this.files_list.length) this.files_list.resize(this.files_list.length*2);
        this.files_list[this.nfiles] = new MuseicFile(filename, origin);
        this.nfiles += 1;
        if (this.nfiles == 1) this.filepos = 0;
    }

    public void add_museic_files(MuseicFile[] files, bool filter_repeated, string origin) {
        foreach (MuseicFile file in files) if (!filter_repeated || (filter_repeated && !is_in_filelist(file.path))) add_museic_file(file, origin);
    }

    public void add_museic_file(MuseicFile afile, string origin) {
        MuseicFile file = new MuseicFile.from_museicfile(afile);
        file.origin = origin;
        if (this.nfiles == this.files_list.length) this.files_list.resize(this.files_list.length*2);
        this.files_list[this.nfiles] = file;
        this.nfiles += 1;
        if (this.nfiles == 1) this.filepos = 0;
    }

    public void add_museic_file_init(MuseicFile afile, string origin) {
        MuseicFile file = new MuseicFile.from_museicfile(afile);
        file.origin = origin;
        MuseicFile[] aux_list = new MuseicFile[this.nfiles+1];
        for (int i=0;i<this.nfiles;i++) aux_list[i+1] = this.files_list[i];
        aux_list[0] = file;
        this.nfiles += 1;
        if (this.nfiles == 1) this.filepos = 0;
        else this.filepos += 1;
        this.files_list = aux_list;
    }

    public MuseicFile get_current_file() {
        if (filepos < 0) return new MuseicFile("", "");
        else return this.files_list[this.filepos];
    }

    public MuseicFile[] get_files_list() {
        return this.files_list[0:this.nfiles];
    }

    public MuseicFile next_file() {
        if (this.random_state){
            this.filepos = Random.int_range (0, this.nfiles);
        }else {
            this.filepos += 1;
            if (this.filepos >= this.nfiles) this.filepos = 0;
        }
        return get_current_file();
    }

    public MuseicFile ant_file() {
        this.filepos -= 1;
        if (this.filepos < 0) this.filepos = this.nfiles-1;
        return get_current_file();
    }

    public MuseicFile get_next_file() {
        int aux_pos = this.filepos;
        if (this.random_state){
            aux_pos = Random.int_range (0, this.nfiles);
        }else {
            aux_pos += 1;
            if (aux_pos >= this.nfiles) aux_pos = 0;
        }
        if (aux_pos < 0) return new MuseicFile("", "");
        else return this.files_list[aux_pos];
    }

    public MuseicFile get_ant_file() {
        int aux_pos = this.filepos;
        aux_pos -= 1;
        if (aux_pos < 0) aux_pos = this.nfiles-1;
        if (aux_pos < 0) return new MuseicFile("", "");
        else return this.files_list[aux_pos];
    }

    public void clean() {
        filepos = -1;
        nfiles = 0;
        files_list = new MuseicFile[4];
    }

    public bool has_next() {
        return (this.nfiles - this.filepos) > 1;
    }

    public bool has_ant() {
        return this.filepos > 0;
    }

    public void sort() {
        // Sort the files_list using the current sort_field.
        // The filepos is updated to continue refering to the same file
        if (this.sorted == 0 || this.sorted == -1) this.sorted = 1;
        else this.sorted = -1;
        if (this.nfiles != 0) {
            MuseicFile current = this.files_list[this.filepos];
            quicksort(ref files_list, 0, this.nfiles-1);
            if (sorted == -1) {
                MuseicFile[] aux = new MuseicFile[this.nfiles];
                for (int i=0; i<this.nfiles; i++) {
                    aux[this.nfiles-i-1] = files_list[i];
                    if (this.files_list[i].name == current.name) this.filepos = this.nfiles-i-1;
                }
                files_list = aux;
            }else {
                for (int i=0; i<this.nfiles; i++) {
                    if (this.files_list[i].name == current.name) {
                        this.filepos = i;
                        i = this.nfiles+1;
                    }
                }
            }
        }
    }

    private MuseicFile[] quicksort(ref MuseicFile[] list, int first, int last) {
        // Set index and pivot
        int i = first;
        int j = last;
        MuseicFile pivot = list[(i+j)/2];
        while (i < j) {
            while (list[i].compare(pivot, this.sort_field) == -1) i++;  // while l[i] < pivot
            while (list[j].compare(pivot, this.sort_field) == 1) j--;  // while l[j] > pivot
            // Check if the indexs have swap
            if (i <= j) {
                MuseicFile aux = list[j];
                list[j] = list[i];
                list[i] = aux;
                i++;
                j--;
            }
        }
        if (first < j) list = quicksort(ref list, first, j);
        if (last > i) list = quicksort(ref list, i, last);
        return list;
    }

}
