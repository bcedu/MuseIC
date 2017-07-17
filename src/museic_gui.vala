public class MuseicGui : Gtk.ApplicationWindow {

    private MuseIC museic_app;
    private Gtk.Builder builder;

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
        this.add (builder.get_object ("mainBox") as Gtk.Box);
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
        var file_chooser = new Gtk.FileChooserDialog ("Open File", this, Gtk.FileChooserAction.OPEN, "_Cancel", Gtk.ResponseType.CANCEL, "_Open File", Gtk.ResponseType.ACCEPT);
        file_chooser.add_button("_Open Folder", Gtk.ResponseType.ACCEPT);
        file_chooser.set_select_multiple (true);
        if (file_chooser.run () == Gtk.ResponseType.ACCEPT) {
            // If we were playing, pause
            if (this.museic_app.state() == "play") action_play_file((builder.get_object ("playButton") as Gtk.Button));
            // Pass files to prepare it for stream
            string[] sfiles = {};
            foreach (string aux in file_chooser.get_filenames ()) sfiles += aux;
            this.museic_app.open_files(sfiles, true);
            update_stream_status();
        }
        file_chooser.destroy ();
    }

    [CCode(instance_pos=-1)]
    public void action_add_file (Gtk.Button button) {
        var file_chooser = new Gtk.FileChooserDialog ("Add File", this, Gtk.FileChooserAction.OPEN, "_Cancel", Gtk.ResponseType.CANCEL, "_Add File", Gtk.ResponseType.ACCEPT);
        file_chooser.add_button("_Add Folder", Gtk.ResponseType.ACCEPT);
        file_chooser.set_select_multiple (true);
        if (file_chooser.run () == Gtk.ResponseType.ACCEPT) {
            // Pass files to prepare it for stream
            string[] sfiles = {};
            foreach (string aux in file_chooser.get_filenames ()) sfiles += aux;
            this.museic_app.open_files(sfiles, !this.museic_app.has_files());
            update_stream_status();
        }
        file_chooser.destroy ();
    }

    [CCode(instance_pos=-1)]
    public bool action_change_time (Gtk.Scale slider, Gtk.ScrollType scroll, double new_value) {
        this.museic_app.set_position((float)new_value);
        slider.adjustment.value = new_value;
        return true;
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
