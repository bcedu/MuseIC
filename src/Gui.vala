
public class AppWindow : Gtk.ApplicationWindow {

    public Gtk.Button play_button;
    public Gtk.Button pause_button;
    public Gtk.Button seg_button;
    public Gtk.Button ant_button;
    public Gtk.Label status_label;
    public Gtk.ToolButton open_button_file;
    public Gtk.ToolButton open_button_folder;
    public Gtk.ListStore filelist;
    public string file_selected;
    public string[] files;
    public string folder;
    public int act_file = 0;
    public int nfiles = 0;
    public StreamPlayer streamplayer;

    public AppWindow(Gtk.Application app, string[] args) {
        Object (application: app, title: "museIC");
        this.set_border_width (10);
        this.set_position (Gtk.WindowPosition.CENTER);

        // Create grid
        var grid = new Gtk.Grid();
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.row_spacing = 10;
        grid.column_spacing = 2;

        // Open file and folder buttons
        var toolbar = new Gtk.Toolbar ();
        toolbar.get_style_context ().add_class (Gtk.STYLE_CLASS_PRIMARY_TOOLBAR);
        this.open_button_file = new Gtk.ToolButton (new Gtk.Image.from_icon_name ("document-open", Gtk.IconSize.SMALL_TOOLBAR), "Open File");
        this.open_button_folder = new Gtk.ToolButton (new Gtk.Image.from_icon_name ("folder-open", Gtk.IconSize.SMALL_TOOLBAR), "Open Folder");
        toolbar.add (this.open_button_file);
   		  toolbar.add (this.open_button_folder);
   		  this.open_button_file.show ();
   		  this.open_button_folder.show ();
        toolbar.set_hexpand(true);
        grid.add (toolbar);

        // Status label
        this.status_label = new Gtk.Label ("Stoped");
        grid.add (status_label);

        // Play and Pause buttons
        this.play_button = new Gtk.Button.with_label ("Play");
        this.pause_button = new Gtk.Button.with_label ("Pause");
        // Seg and Ant buttons
        this.seg_button = new Gtk.Button.with_label ("Seg");
        this.ant_button = new Gtk.Button.with_label ("Ant");
        var button_grid = new Gtk.Grid();
        button_grid.orientation = Gtk.Orientation.HORIZONTAL;
        button_grid.column_spacing = 10;
        button_grid.add (this.play_button);
        button_grid.add (this.pause_button);
        button_grid.add (this.seg_button);
        button_grid.add (this.ant_button);
        grid.add (button_grid);

        // File Tree
        var tree_view = new Gtk.TreeView ();
        this.filelist = new Gtk.ListStore (4, typeof (string), typeof (string), typeof (string), typeof (string));
        tree_view.set_model (this.filelist);
        tree_view.insert_column_with_attributes (-1, "File Name", new Gtk.CellRendererText (), "text", 0);
        var scroll = new Gtk.ScrolledWindow (null, null);
        scroll.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
        scroll.set_min_content_height (400);
        scroll.add (tree_view);
        grid.add (scroll);

        this.add (grid);
        set_button_actions(args);
    }

    private void set_button_actions(string[] args) {
         this.streamplayer = new StreamPlayer (args);
         this.play_button.clicked.connect (action_play_file);
         this.pause_button.clicked.connect (action_pause_file);
         this.seg_button.clicked.connect (action_seg_file);
         this.ant_button.clicked.connect (action_ant_file);
         this.destroy.connect (action_destroy);
         this.open_button_file.clicked.connect (action_open_file);
         this.open_button_folder.clicked.connect (action_open_folder);
    }

    private void action_open_file () {
        var file_chooser = new Gtk.FileChooserDialog ("Open File", this, Gtk.FileChooserAction.OPEN, "_Cancel", Gtk.ResponseType.CANCEL, "_Open", Gtk.ResponseType.ACCEPT);

        if (file_chooser.run () == Gtk.ResponseType.ACCEPT) {
            var aux = file_chooser.get_filename ().split("/");
            this.folder = string.joinv("/", aux[0:aux.length-1])+"/";
            this.files = new string[1];
            this.files[0] = aux[aux.length-1];
            this.nfiles = 1;
            this.act_file = 0;
            this.status_label.label = this.file_selected;
            this.streamplayer.exit ();
        }
        file_chooser.destroy ();
    }

    private void action_open_folder () {
        var file_chooser = new Gtk.FileChooserDialog ("Open File", this, Gtk.FileChooserAction.OPEN, "_Cancel", Gtk.ResponseType.CANCEL, "_Open", Gtk.ResponseType.ACCEPT);
        file_chooser.action = Gtk.FileChooserAction.SELECT_FOLDER;

        if (file_chooser.run () == Gtk.ResponseType.ACCEPT) {
            var aux = file_chooser.get_filename ().split("/");
            this.folder = string.joinv("/", aux)+"/";
            this.file_selected = "";
            this.status_label.label = aux[aux.length-1];
            this.streamplayer.exit ();
            this.files = get_files_from_folder(this.folder);
        }
        file_chooser.destroy ();
    }

    private string[] get_files_from_folder(string folder) {
        string[] files = new string[2000];
        try {
            var directory = File.new_for_path (folder);
            var enumerator = directory.enumerate_children (FileAttribute.STANDARD_NAME, 0);
            FileInfo file_info;
            this.filelist.clear ();
            int i = 0;
            while ((file_info = enumerator.next_file ()) != null) {
                if (file_info.get_name ().split (".")[1] == "mp3") {
                    files[i] = file_info.get_name ();
                    i = i + 1;
                    Gtk.TreeIter iter;
                    this.filelist.append (out iter);
                    this.filelist.set (iter, 0, file_info.get_name ());
                }
            }
            this.nfiles = i;
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
        }
        return files;
    }

    private void action_play_file () {
        this.file_selected = this.files[this.act_file];
        this.status_label.label = this.file_selected;
        this.play_button.set_sensitive (false);
        this.streamplayer.play_file ("file://"+this.folder+this.file_selected);
    }

    private void action_pause_file () {
        this.status_label.label = "Paused";
        this.play_button.set_sensitive (true);
        this.streamplayer.pause_file ();
    }

    private void action_seg_file () {
        this.streamplayer.exit ();
        this.act_file = this.act_file + 1;
        if (this.act_file >= this.nfiles) {
            this.act_file = 0;
        }
        action_play_file ();
    }

    private void action_ant_file () {
        this.streamplayer.exit ();
        this.act_file = this.act_file - 1;
        if (this.act_file < 0) {
            this.act_file = this.nfiles-1;
        }
        action_play_file ();
    }

    private void action_destroy () {
        this.streamplayer.exit ();
        Gtk.main_quit();
    }

    public void start () {
        this.show_all ();
    }
}
