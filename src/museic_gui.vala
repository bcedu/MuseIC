public class MuseicGui : Gtk.ApplicationWindow {

    private MuseIC museic_app;
    private Gtk.Builder builder;
    private Museic.Settings saved_state;
    private Gtk.ListStore fileListStore;
    private Gtk.ListStore playListStore;
    private MuseicFileList museic_shown_filelist;
    // Aux variables needed to open files
    private Gtk.Window files_window;
    private Gtk.FileChooserWidget chooser;
    private bool is_open = false;
    private Gtk.ProgressBar progress_bar;
    private Gtk.Label progress_label;

    public MuseicGui(MuseIC app) {
        Object (application: app, title: "MuseIC");
        museic_app = app;
        // Define main window
        this.load_window_state();
        this.delete_event.connect(save_window_state);
        // Load interface from file
        this.builder = new Gtk.Builder ();
        try {
            builder.add_from_file (Constants.PKGDATADIR+"/data/com.github.bcedu.museic.glade");
        }catch (GLib.Error e) {
            stdout.printf("Glade file not found. Error: %s\n", e.message);
        }
        // Load CSS
        string css_file = Constants.CSSDIR + "/main.css";
        var provider = new Gtk.CssProvider();
        try {
            provider.load_from_path(css_file);
            Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
        } catch (Error e) {
            stderr.printf("Error: %s\n", e.message);
        }
        // Connect signals
        builder.connect_signals (this);
        // Add HeaderBar
        var header_bar = new Gtk.HeaderBar ();
        header_bar.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        header_bar.show_close_button = true;
        header_bar.pack_start  ((builder.get_object ("openFile") as Gtk.ToolButton));
        header_bar.pack_start  ((builder.get_object ("addFile") as Gtk.ToolButton));
        header_bar.pack_start  ((builder.get_object ("helpRemote") as Gtk.ToolButton));
        // header_bar.pack_end  ((builder.get_object ("reload") as Gtk.ToolButton));
        header_bar.set_title("MuseIC");
        header_bar.get_style_context().add_class ("headerbar");
        this.set_titlebar (header_bar);
        // Add main box to window
        this.add (builder.get_object ("mainW") as Gtk.Grid);
        // Set fileListStore
        this.fileListStore = new Gtk.ListStore (5, typeof (string), typeof (string), typeof (string), typeof (string), typeof (Gdk.RGBA));
        var tree = (this.builder.get_object ("fileTree") as Gtk.TreeView);
        tree.get_style_context().add_class ("fileListStore");
        tree.set_model (this.fileListStore);
        tree.insert_column_with_attributes (-1, "Song", new Gtk.CellRendererText (), "text", 0, "background-rgba", 4);
        tree.get_column(0).set_resizable(true);
        tree.get_column(0).set_clickable(true);
        tree.get_column(0).set_min_width(200);
        tree.get_column(0).clicked.connect (sort_by_song);
        tree.insert_column_with_attributes (-1, "Artist", new Gtk.CellRendererText (), "text", 1, "background-rgba", 4);
        tree.get_column(1).set_resizable(true);
        tree.get_column(1).set_clickable(true);
        tree.get_column(1).set_min_width(200);
        tree.get_column(1).clicked.connect (sort_by_artist);
        tree.insert_column_with_attributes (-1, "Album", new Gtk.CellRendererText (), "text", 2, "background-rgba", 4);
        tree.get_column(2).set_resizable(true);
        tree.get_column(2).set_clickable(true);
        tree.get_column(2).set_min_width(200);
        tree.get_column(2).clicked.connect (sort_by_album);
        tree.insert_column_with_attributes (-1, "Status", new Gtk.CellRendererText (), "text", 3, "background-rgba", 4);
        // Set playListStore
        this.playListStore = new Gtk.ListStore (5, typeof (string), typeof (string), typeof (string), typeof (string), typeof (Gdk.RGBA));
        tree = (this.builder.get_object ("playTree") as Gtk.TreeView);
        tree.get_style_context().add_class ("playListStore");
        tree.set_model (this.playListStore);
        tree.insert_column_with_attributes (-1, "Song", new Gtk.CellRendererText (), "text", 0, "background-rgba", 4);
        tree.get_column(0).set_resizable(true);
        tree.get_column(0).set_min_width(200);
        tree.insert_column_with_attributes (-1, "Artist", new Gtk.CellRendererText (), "text", 1, "background-rgba", 4);
        tree.get_column(1).set_resizable(true);
        tree.get_column(1).set_min_width(200);
        tree.insert_column_with_attributes (-1, "Album", new Gtk.CellRendererText (), "text", 2, "background-rgba", 4);
        tree.get_column(2).set_resizable(true);
        tree.get_column(2).set_min_width(200);
        tree.insert_column_with_attributes (-1, "Status", new Gtk.CellRendererText (), "text", 3, "background-rgba", 4);
        tree.get_column(3).set_resizable(true);
        // Show window
        this.show_all ();
        this.show ();
        // Set some more css classes
        (this.builder.get_object ("statusLabel") as Gtk.Label).get_style_context().add_class ("songtitle");
        (this.builder.get_object ("statusLabel1") as Gtk.Label).get_style_context().add_class ("songartist");
        (this.builder.get_object ("scalebar") as Gtk.Scale).get_style_context().add_class ("streamprogresbar");
        (this.builder.get_object ("timeLabel") as Gtk.Label).get_style_context().add_class ("streamtime");
        (this.builder.get_object ("antButton") as Gtk.Button).get_style_context().add_class ("antButton");
        (this.builder.get_object ("playButton") as Gtk.Button).get_style_context().add_class ("playButton");
        (this.builder.get_object ("segButton") as Gtk.Button).get_style_context().add_class ("segButton");
        (this.builder.get_object ("randButton") as Gtk.Button).get_style_context().add_class ("randButton");
        (this.builder.get_object ("volumebar") as Gtk.Scale).get_style_context().add_class ("volumebar");
        (this.builder.get_object ("label1") as Gtk.Label).get_style_context().add_class ("filelisttitle");
        (this.builder.get_object ("label2") as Gtk.Label).get_style_context().add_class ("playlisttitle");
        (this.builder.get_object ("addToPlay") as Gtk.Button).get_style_context().add_class ("addToPlayButton");
        (this.builder.get_object ("separator1") as Gtk.Separator).get_style_context().add_class ("separator1");
        (this.builder.get_object ("statusBox") as Gtk.Box).get_style_context().add_class ("statusBox");
        (this.builder.get_object ("progresBox") as Gtk.Box).get_style_context().add_class ("progresBox");
        (this.builder.get_object ("statusButtons") as Gtk.Box).get_style_context().add_class ("statusButtons");
        (this.builder.get_object ("filelist_chooser") as Gtk.ComboBoxText).get_style_context().add_class ("filelist_chooser");

        this.museic_shown_filelist = this.museic_app.get_active_filelist();
        // Start time function to update info about stream duration and position each second
        GLib.Timeout.add_seconds (1, update_stream_status);
        // Update tree view with files from library
        if (this.museic_app.get_filelist_len() > 0) {
            update_files_to_tree();
            update_stream_status();
            update_playlist_to_tree();
        }
    }

    private void load_window_state() {
        this.saved_state = Museic.Settings.get_default();
        // Load size
        this.set_default_size (this.saved_state.window_width, this.saved_state.window_height);
        // Load position
        this.move(this.saved_state.window_posx, this.saved_state.window_posy);
        // Maximize window if necessary
        if (this.saved_state.window_state == 1) this.maximize ();
        // Load position
        this.set_position (Gtk.WindowPosition.CENTER);

        // Set logo
        try {
            this.icon = new Gdk.Pixbuf.from_file (Constants.ICON);
        }catch (GLib.Error e) {
            stdout.printf("Logo not found. Error: %s\n", e.message);
        }
    }

    private bool save_window_state(Gdk.EventAny event) {
        int aux1;
        int aux2;
        this.get_size (out aux1, out aux2);
        saved_state.window_width = aux1;
        saved_state.window_height = aux2;
        this.get_position (out aux1, out aux2);
        saved_state.window_posx = aux1;
        saved_state.window_posy = aux2;
        if (this.is_maximized) saved_state.window_state = 1;
        else saved_state.window_state = 0;

        if (this.museic_app.state() == "play") {
            this.museic_app.closed = true;
            return this.hide_on_delete ();
        }else return false;
    }

    public void notify(string text) {
        var notification = new Notification ("MuseIC");
        try {
            notification.set_icon ( new Gdk.Pixbuf.from_file (Constants.ICON));
        }catch (GLib.Error e) {
            stdout.printf("Notification logo not found. Error: %s\n", e.message);
        }
        notification.set_body (text);
        this.museic_app.send_notification (this.museic_app.application_id, notification);
    }

    [CCode(instance_pos=-1)]
    public void action_ant_file (Gtk.Button button) {
        if (this.museic_app.has_files()) {
            this.museic_app.play_ant_file();
            this.notify(this.museic_app.get_current_file().name);
            update_stream_status();
            update_files_to_tree();
            update_playlist_to_tree();
            this.museic_app.update_dbus_status();
        }
    }

    [CCode(instance_pos=-1)]
    public void action_seg_file (Gtk.Button button) {
        if (this.museic_app.has_files()) {
            this.museic_app.play_next_file();
            this.notify(this.museic_app.get_current_file().name);
            update_stream_status();
            update_files_to_tree();
            update_playlist_to_tree();
            this.museic_app.update_dbus_status();
        }
    }

    [CCode(instance_pos=-1)]
    public void action_play_file (Gtk.Button button) {
        if (this.museic_app.has_files()) {
            if (museic_app.state() == "pause")  {
                this.museic_app.play_file();
                button.set_label("gtk-media-pause");
            }else {
                this.museic_app.pause_file();
                button.set_label("gtk-media-play");
            }
            this.museic_app.update_dbus_status();
        }
    }

    [CCode(instance_pos=-1)]
    public void action_open_file (Gtk.Button button) {
        // If we were playing, pause
        if (museic_app.state() != "pause") action_play_file((builder.get_object ("playButton") as Gtk.Button));
        create_file_open_window(true);
    }

    [CCode(instance_pos=-1)]
    public void action_add_file (Gtk.Button button) {
        create_file_open_window(!this.museic_app.has_files());
    }

    public void update_play_button() {
        Gtk.Button button = (builder.get_object ("playButton") as Gtk.Button);
        if (museic_app.state() != "play")  button.set_label("gtk-media-pause");
        else button.set_label("gtk-media-play");
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
        // proogress bar
        this.progress_bar = new Gtk.ProgressBar();
        this.progress_bar.set_text ("");
        this.progress_bar.set_show_text (true);
        vbox.add(this.progress_bar);
        // Setup buttons callbacks
        cancel.clicked.connect (() => {this.files_window.destroy ();});
        this.is_open = is_open_files;
        select.clicked.connect (open_files);
        this.files_window.show_all ();
    }

    private async void open_files () {
        string[] sfiles = {};
        SList<File> files = this.chooser.get_files ();
        foreach (unowned File file in files) {
            if (file.query_file_type(FileQueryInfoFlags.NONE) == FileType.REGULAR) sfiles += file.get_path();
            else if (file.query_file_type(FileQueryInfoFlags.NONE) == FileType.DIRECTORY) {
                string[] folder_files = rec_open(file);
                foreach (unowned string aux_file in folder_files) sfiles += file.get_path()+"/"+aux_file;
            }
        }
        if (this.is_open) {
            this.museic_app.clear_playlist();
            this.museic_app.clear_filelist();
            this.museic_app.clear_library();
        }

        double fraction = 0.0;
        this.progress_bar.set_fraction (fraction);
        int processed_files = 0;
        string[] aux = new string[1];
        foreach (string sfile in sfiles) {
            aux[0] = sfile;
            this.progress_bar.set_text (sfile);
            Idle.add(open_files.callback);
            yield;
            this.museic_app.add_files_to_filelist(aux);
            processed_files += 1;
            fraction = (double)processed_files/(double)sfiles.length;
            this.progress_bar.set_fraction (fraction);
        }
        if (this.is_open) this.museic_app.play_filelist_file(0);
        this.museic_shown_filelist = this.museic_app.get_active_filelist();
        update_files_to_tree();
        update_stream_status();
        if (this.is_open) {
            update_playlist_to_tree();
            var notification = new Notification ("MuseIC");
            try {
                notification.set_icon ( new Gdk.Pixbuf.from_file (Constants.ICON));
            }catch (GLib.Error e) {
                stdout.printf("Notification logo not found. Error: %s\n", e.message);
            }
            notification.set_body ("Playing:\n"+this.museic_app.get_current_file().name);
            this.museic_app.send_notification (this.museic_app.application_id, notification);
        }
        this.files_window.destroy ();
        this.files_window = null;
        this.chooser = null;
        this.is_open = false;
    }

    private string[] rec_open(File file) {
        FileEnumerator enumerator = file.enumerate_children ("standard::*", FileQueryInfoFlags.NONE, null);
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

    public void update_files_to_tree() {
        this.fileListStore.clear ();
        Gtk.TreeIter iter;
        Gdk.RGBA rgba_default = Gdk.RGBA ();
        rgba_default.parse ("#ffffff");
        foreach (MuseicFile file in this.museic_shown_filelist.get_files_list()) {
            this.fileListStore.append (out iter);
            this.fileListStore.set (iter, 0, file.name, 1, file.artist, 2, file.album, 3, "", 4, rgba_default);
        }
    }

    public void update_playlist_to_tree() {
        this.playListStore.clear ();
        Gtk.TreeIter iter;
        Gtk.TreeIter iterfile;
        MuseicFile[] aux = this.museic_app.get_all_playlist_files();
        MuseicFile file;
        Gdk.RGBA rgba_act = Gdk.RGBA ();
        rgba_act.parse ("#d0e5e3");
        Gdk.RGBA rgba_next = Gdk.RGBA ();
        rgba_next.parse ("#e7f2f1");
        Gdk.RGBA rgba_default = Gdk.RGBA ();
        rgba_default.parse ("#ffffff");
        Gdk.RGBA rgba_quequed = Gdk.RGBA ();
        rgba_quequed.parse ("#ebebe0");
        int pos = museic_app.get_playlist_pos();
        for (int i=aux.length-1;i>=0;i--) {
            file = aux[i];
            this.playListStore.append (out iter);
            if (file.origin == "filelist") this.playListStore.set (iter, 0, file.name, 1, file.artist, 2, file.album, 3, "", 4, rgba_default);
            else this.playListStore.set (iter, 0, file.name, 1, file.artist, 2, file.album, 3, "", 4, rgba_quequed);
            if (i == pos) {
                this.playListStore.set (iter, 3, "Playing...", 4, rgba_act);
                if (this.playListStore.iter_previous(ref iter)) {
                    this.playListStore.set (iter, 3, "Next", 4, rgba_next);
                    this.fileListStore.get_iter_from_string(out iterfile, this.museic_app.get_next_filelist_pos().to_string());
                    this.fileListStore.set (iterfile, 3, "", 4, rgba_default);
                }else if (!this.museic_app.is_random() && this.museic_shown_filelist.name == this.museic_app.get_active_filelist().name) {
                    int filepos = this.museic_app.get_next_filelist_pos();
                    this.fileListStore.get_iter_from_string(out iterfile, filepos.to_string());
                    this.fileListStore.set (iterfile, 3, "Next", 4, rgba_next);
                    if (this.museic_app.get_filelist_len() != 1) {
                        if (filepos == 0) filepos = this.museic_app.get_filelist_len()-1;
                        else filepos = filepos -1;
                        this.fileListStore.get_iter_from_string(out iterfile, filepos.to_string());
                        this.fileListStore.set (iterfile, 3, "", 4, rgba_default);
                    }
                }
                this.playListStore.iter_next(ref iter);
            }
        }
    }

    public bool update_stream_status() {
        if (!this.museic_app.has_files()) return true;
        StreamTimeInfo pos_info = this.museic_app.get_position_str();
        StreamTimeInfo dur_info = this.museic_app.get_duration_str();
        // Update time label
        (this.builder.get_object ("timeLabel") as Gtk.Label).set_label (pos_info.minutes+"/"+dur_info.minutes);
        // Update progres bar
        double progres = (double)pos_info.nanoseconds/(double)dur_info.nanoseconds;
        (this.builder.get_object ("scalebar") as Gtk.Scale).set_value (progres);
        // Update status label with filename and album
        MuseicFile faux = this.museic_app.get_current_file();
        string aux;
        if (faux.album != "unknown") aux = faux.name +" - "+ faux.album;
        else aux = faux.name;
        (builder.get_object ("statusLabel") as Gtk.Label).set_label (aux);
        // Update status label 2 with artist
        if (faux.artist != "unknown") aux = faux.artist;
        else aux = "";
        (builder.get_object ("statusLabel1") as Gtk.Label).set_label (aux);
        // Update volume bar
        (this.builder.get_object ("volumebar") as Gtk.Scale).set_value (this.museic_app.get_stream_volume());
        // Check if stream, has ended
        if (this.museic_app.state() == "endstream") action_seg_file((builder.get_object ("segButton") as Gtk.Button));
        return true;
    }

    [CCode(instance_pos=-1)]
    public void action_random (Gtk.ToggleButton button) {
        this.museic_app.set_random(button.active);
        if (button.active) {
            Gdk.RGBA rgba = Gdk.RGBA ();
            rgba.parse ("#CCCCCC");
            button.override_background_color (Gtk.StateFlags.NORMAL,rgba);
        }else button.override_background_color (Gtk.StateFlags.NORMAL, null);
        update_files_to_tree();
        update_playlist_to_tree();
    }

    public void toggle_random() {
        Gtk.ToggleButton button = (builder.get_object ("randButton") as Gtk.ToggleButton);
        button.active = !button.active;
        action_random(button);
    }

    [CCode(instance_pos=-1)]
    public void action_add_to_play (Gtk.Button button) {
        List<Gtk.TreePath> selected = (this.builder.get_object ("fileTree") as Gtk.TreeView).get_selection().get_selected_rows(null);
        MuseicFile[] files_to_add = new MuseicFile[selected.length()];
        int i = 0;
        MuseicFile[] files = this.museic_shown_filelist.get_files_list();
        foreach (Gtk.TreePath p in selected) {
            files_to_add[i] = files[int.parse(p.to_string())];
            i++;
        }
        this.museic_app.add_museic_files_to_playlist(files_to_add);
        update_files_to_tree();
        update_playlist_to_tree();
    }

    [CCode(instance_pos=-1)]
    public void action_play_selected_file_playlist (Gtk.TreeView view, Gtk.TreePath path, Gtk.TreeViewColumn column) {
        this.museic_app.play_playlist_file(this.museic_app.get_all_playlist_files().length-1-int.parse(path.to_string()));
        if (museic_app.state() == "pause") action_play_file((builder.get_object ("playButton") as Gtk.Button));
        update_files_to_tree();
        update_playlist_to_tree();
        this.museic_app.update_dbus_status();
    }

    [CCode(instance_pos=-1)]
    public void action_play_selected_file_filelist (Gtk.TreeView view, Gtk.TreePath path, Gtk.TreeViewColumn column) {
        this.museic_app.change_filelist(this.museic_shown_filelist);
        update_files_to_tree();
        this.museic_app.clear_playlist();
        this.museic_app.play_filelist_file(int.parse(path.to_string()));
        if (museic_app.state() == "pause") action_play_file((builder.get_object ("playButton") as Gtk.Button));
        update_playlist_to_tree();
        this.museic_app.update_dbus_status();
    }

    private void sort_by_song() {
        if (this.museic_app.get_filelist_len() > 1) sort_filelist("name");
    }
    private void sort_by_artist() {
        if (this.museic_app.get_filelist_len() > 1) sort_filelist("artist");
    }
    private void sort_by_album() {
        if (this.museic_app.get_filelist_len() > 1) sort_filelist("album");
    }

    private void sort_filelist(string field) {
        this.museic_shown_filelist.sort_field = field;
        this.museic_shown_filelist.sort();
        if (this.museic_shown_filelist.name == this.museic_app.get_active_filelist().name) {
            // Sort filelist
            this.museic_app.set_filelist_sort_field(field);
            this.museic_app.sort_filelist();
            // Set status of next file if necessari
            if (this.museic_app.get_playlist_pos() == this.museic_app.get_playlist_len()-1 & !this.museic_app.is_random()) {
                Gtk.TreeIter iterfile;
                Gdk.RGBA rgba_next = Gdk.RGBA ();
                rgba_next.parse ("#e7f2f1");
                Gdk.RGBA rgba_default = Gdk.RGBA ();
                rgba_default.parse ("#ffffff");
                int filepos = this.museic_app.get_next_filelist_pos();
                this.fileListStore.get_iter_from_string(out iterfile, filepos.to_string());
                this.fileListStore.set (iterfile, 3, "Next", 4, rgba_next);
                if (this.museic_app.get_filelist_len() != 1) {
                    if (filepos == 0) filepos = this.museic_app.get_filelist_len()-1;
                    else filepos = filepos -1;
                    this.fileListStore.get_iter_from_string(out iterfile, filepos.to_string());
                    this.fileListStore.set (iterfile, 3, "", 4, rgba_default);
                }
            }
        }
        // Update tree view
        update_files_to_tree();
    }

    [CCode(instance_pos=-1)]
    public void action_help_remote(Gtk.Button button) {
        string help_string = "Control MuseIC from any device!\n1. Open your favourite browser\n2. Type "+this.museic_app.museic_server.get_server_info()+"\n3. Control MuseIC playback: play/pause, next, previous, etc.\n\nIn order to be able to connect to MuseIC, both devices must be in the same Wifi network.\n";

        var helpw = new Gtk.Popover(button);

        Gtk.Box vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 1);
        vbox.margin = 20;
        var helptext = new Gtk.Label(help_string);
        helptext.set_line_wrap(true);
        helptext.set_justify(Gtk.Justification.LEFT);
        vbox.add(helptext);
        helpw.add (vbox);

        helpw.show_all();
    }
    [CCode(instance_pos=-1)]
    public void action_reload_library(Gtk.Button button) {
        this.museic_app.reload_library();
        this.update_files_to_tree();
        this.update_playlist_to_tree();
    }

    [CCode(instance_pos=-1)]
    public bool action_change_volume (Gtk.Scale slider, Gtk.ScrollType scroll, double new_value) {
        this.museic_app.set_stream_volume((double)new_value);
        slider.adjustment.value = new_value;
        return true;
    }

    [CCode(instance_pos=-1)]
    public void action_show_filelist_options(Gtk.Button artists_button) {
        var helpw = new Gtk.Popover(artists_button);
        /*
        Ha de haverhi un tree amb els artistes. A dalt de tot un cercador
        */
        Gtk.ListStore list_store = new Gtk.ListStore (1, typeof (string));
    	Gtk.TreeIter iter;

        list_store.append (out iter);
        list_store.set (iter, 0, "All Artists");

        foreach (string artist_name in this.museic_app.get_all_artists()) {
            list_store.append (out iter);
            list_store.set (iter, 0, artist_name);
        }

        Gtk.TreeView view = new Gtk.TreeView.with_model (list_store);
        Gtk.CellRendererText cell = new Gtk.CellRendererText ();
		view.insert_column_with_attributes (-1, "Artist", cell, "text", 0);
        view.row_activated.connect((path, column) => {
            Value val;
            list_store.get_iter (out iter, path);
            list_store.get_value (iter, 0, out val);
            artists_button.set_label((string)val);
            this.change_shown_filelist((string)val);
            helpw.destroy();
        });

        Gtk.ScrolledWindow scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
        scrolled.min_content_width = 500;
        scrolled.expand = true;
        helpw.vexpand = true;
        helpw.set_position (Gtk.PositionType.BOTTOM);

        scrolled.add(view);
		helpw.add (scrolled);
        helpw.show_all();
    }

    private void change_shown_filelist(string artist) {
        if (artist == "All Artists") artist = "all";

        if (this.museic_app.museic_filelist.name == artist) this.museic_shown_filelist = this.museic_app.get_active_filelist();
        else {
            this.museic_shown_filelist.clean();
            this.museic_shown_filelist.add_museic_files(this.museic_app.museic_library.get_library_files(artist), true, "filelist");
            this.museic_shown_filelist.name = artist;
        }

        update_files_to_tree();
        update_playlist_to_tree();
    }

}
