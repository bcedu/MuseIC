public class MuseicGui : Gtk.ApplicationWindow {

    private MuseIC museic_app;
    private Gtk.Builder builder;
    private Gtk.ListStore fileListStore;
    // Aux variables needed to open files
    private Gtk.Window files_window;
    private Gtk.FileChooserWidget chooser;
    private bool is_open = false;

    public MuseicGui(MuseIC app) {
        Object (application: app, title: "MuseIC");
        museic_app = app;
        // Define main window
        this.set_position (Gtk.WindowPosition.CENTER);
        try {
            this.icon = new Gdk.Pixbuf.from_file ("data/museic_logo_64.png");
        }catch (GLib.Error e) {
            stdout.printf("Logo not found. Error: %s\n", e.message);
        }
        // Load interface from file
        this.builder = new Gtk.Builder ();
        try {
            builder.add_from_file ("src/museic_window.glade");
        }catch (GLib.Error e) {
            stdout.printf("Glade file not found. Error: %s\n", e.message);
        }
        // Connect signals
        builder.connect_signals (this);
        // Add main box to window
        this.add (builder.get_object ("mainW") as Gtk.Grid);
        // Set fileListStore
        this.fileListStore = new Gtk.ListStore (2, typeof (string), typeof (string));
        var tree = (this.builder.get_object ("fileTree") as Gtk.TreeView);
        tree.set_model (this.fileListStore);
        tree.insert_column_with_attributes (-1, "File Name", new Gtk.CellRendererText (), "text", 0);
        tree.insert_column_with_attributes (-1, "Duration", new Gtk.CellRendererText (), "text", 1);
        // Show window
        this.show_all ();
        this.show ();
        // Start time function to update info about stream duration and position each second
        GLib.Timeout.add_seconds (1, update_stream_status);
    }

    [CCode(instance_pos=-1)]
    public void action_ant_file (Gtk.Button button) {
        if (this.museic_app.has_files()) {
            this.museic_app.ant_file();
            var notification = new Notification ("MuseIC");
            // Doesn't work :(
            try {
                notification.set_icon ( new Gdk.Pixbuf.from_file ("data/museic_logo_64.png"));
            }catch (GLib.Error e) {
                stdout.printf("Notification logo not found. Error: %s\n", e.message);
            }
            notification.set_body ("Previous File\n"+this.museic_app.get_current_file());
            this.museic_app.send_notification (this.museic_app.application_id, notification);
            update_stream_status();
        }
    }

    [CCode(instance_pos=-1)]
    public void action_seg_file (Gtk.Button button) {
        if (museic_app.has_files()) {
            this.museic_app.seg_file();
            var notification = new Notification ("MuseIC");
            // Doesn't work :(
            try {
                notification.set_icon ( new Gdk.Pixbuf.from_file ("data/museic_logo_64.png"));
            }catch (GLib.Error e) {
                stdout.printf("Notification logo not found. Error: %s\n", e.message);
            }
            notification.set_body ("Next File\n"+this.museic_app.get_current_file());
            this.museic_app.send_notification (this.museic_app.application_id, notification);
            update_stream_status();
        }
    }

    [CCode(instance_pos=-1)]
    public void action_play_file (Gtk.Button button) {
        if (this.museic_app.get_current_file() != "") {
            if (museic_app.state() == "pause")  {
                this.museic_app.play_file();
                button.set_label("gtk-media-pause");
            }else {
                this.museic_app.pause_file();
                button.set_label("gtk-media-play");
            }
        }
    }

    [CCode(instance_pos=-1)]
    public void action_open_file (Gtk.Button button) {
        // If we were playing, pause
        if (this.museic_app.state() == "play") action_play_file((builder.get_object ("playButton") as Gtk.Button));
        create_file_open_window(true);
    }

    [CCode(instance_pos=-1)]
    public void action_add_file (Gtk.Button button) {
        create_file_open_window(!this.museic_app.has_files());
    }

    private void create_file_open_window(bool is_open_files) {
        this.files_window = new Gtk.Window();
        this.files_window.window_position = Gtk.WindowPosition.CENTER;
        this.files_window.destroy.connect (Gtk.main_quit);
        // VBox:
        Gtk.Box vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 5);
        this.files_window.add (vbox);
        // HeaderBar:
        Gtk.HeaderBar hbar = new Gtk.HeaderBar ();
        hbar.set_title ("Open Files");
        hbar.set_subtitle ("Select Files and Folders to open");
        this.files_window.set_titlebar (hbar);
        // Add a chooser:
        this.chooser = new Gtk.FileChooserWidget (Gtk.FileChooserAction.OPEN);
        vbox.pack_start (this.chooser, true, true, 0);
        // Multiple files can be selected:
        this.chooser.select_multiple = true;
        // Buttons
        Gtk.Box hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 2);
        hbox.set_halign(Gtk.Align.CENTER);
        hbox.set_border_width(5);
        Gtk.Button cancel = new Gtk.Button.with_label ("Cancel");
        Gtk.Button select = new Gtk.Button.with_label ("Select");
        hbox.add (select);
        hbox.add (cancel);
        vbox.add(hbox);
        // Setup buttons callbacks
        cancel.clicked.connect (() => {this.files_window.destroy ();});
        this.is_open = is_open_files;
        select.clicked.connect (open_files);
        this.files_window.show_all ();
    }

    private void open_files () {
        string[] sfiles = {};
        SList<File> files = this.chooser.get_files ();
        foreach (unowned File file in files) {
            if (file.query_file_type(FileQueryInfoFlags.NOFOLLOW_SYMLINKS) == FileType.REGULAR) sfiles += file.get_path();
            else if (file.query_file_type(FileQueryInfoFlags.NOFOLLOW_SYMLINKS) == FileType.DIRECTORY) {
                string[] folder_files = rec_open(file);
                foreach (unowned string aux_file in folder_files) sfiles += file.get_path()+"/"+aux_file;
            }
        }
        this.museic_app.open_files(sfiles, this.is_open);
        update_files_to_tree();
        update_stream_status();
        this.files_window.destroy ();
        this.files_window = null;
        this.chooser = null;
        this.is_open = false;
    }

    private string[] rec_open(File file) {
        FileEnumerator enumerator = file.enumerate_children ("standard::*", FileQueryInfoFlags.NOFOLLOW_SYMLINKS, null);
        string[] sfiles = {};
        FileInfo info = null;
        while ((info = enumerator.next_file (null)) != null) {
            if (info.get_file_type () == FileType.DIRECTORY) {
                string[] folder_files = rec_open(file.resolve_relative_path (info.get_name ()));
                foreach (unowned string aux_file in folder_files) sfiles += info.get_name ()+"/"+aux_file;
            }else sfiles += info.get_name();
        }
        return sfiles;
    }

    [CCode(instance_pos=-1)]
    public bool action_change_time (Gtk.Scale slider, Gtk.ScrollType scroll, double new_value) {
        this.museic_app.set_position((float)new_value);
        slider.adjustment.value = new_value;
        return true;
    }

    private void update_files_to_tree() {
        this.fileListStore.clear ();
        Gtk.TreeIter iter;
        foreach (string filename in this.museic_app.get_all_files()) {
            this.fileListStore.append (out iter);
            this.fileListStore.set (iter, 0, filename, 1, "min:sec");
        }
    }

    private bool update_stream_status() {
        if (!this.museic_app.has_files()) return true;
        StreamTimeInfo pos_info = this.museic_app.get_position_str();
        StreamTimeInfo dur_info = this.museic_app.get_duration_str();
        // Update time label
        (this.builder.get_object ("timeLabel") as Gtk.Label).set_label (pos_info.minutes+"/"+dur_info.minutes);
        // Update progres bar
        double progres = (double)pos_info.nanoseconds/(double)dur_info.nanoseconds;
        (this.builder.get_object ("scalebar") as Gtk.Scale).set_value (progres);
        // Update status label with filename
        (builder.get_object ("statusLabel") as Gtk.Label).set_label (this.museic_app.get_current_file());
        // Check if stream, has ended
        if (this.museic_app.state() == "endstream") action_seg_file((builder.get_object ("segButton") as Gtk.Button));
        return true;
    }

}
