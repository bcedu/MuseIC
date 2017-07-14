public class MuseicGui : Gtk.ApplicationWindow {

    private MuseIC museic_app;
    private Gtk.Builder builder;

    public MuseicGui(MuseIC app) {
        Object (application: app, title: "MuseIC");
        museic_app = app;
        // Define main window
        this.set_position (Gtk.WindowPosition.CENTER);
        // Load interface from file
        this.builder = new Gtk.Builder ();
        builder.add_from_file ("/home/bcedu/Documents/Projects/MuseIC/src/museic_window.glade");
        // Connect signals
        builder.connect_signals (this);
        // Add main box to window
        this.add (builder.get_object ("mainBox") as Gtk.Box);
        // Show window
        this.show_all ();
        this.show ();
    }

    [CCode(instance_pos=-1)]
    public void action_ant_file (Gtk.Button button) {
        var notification = new Notification ("MuseIC");
        var image = new Gtk.Image.from_icon_name ("dialog-warning", Gtk.IconSize.DIALOG);
        notification.set_icon (image.gicon);
        notification.set_body ("Previous File");
        this.museic_app.send_notification (this.museic_app.application_id, notification);
    }

    [CCode(instance_pos=-1)]
    public void action_seg_file (Gtk.Button button) {
        var notification = new Notification ("MuseIC");
        var image = new Gtk.Image.from_icon_name ("dialog-warning", Gtk.IconSize.DIALOG);
        notification.set_icon (image.gicon);
        notification.set_body ("Next File");
        this.museic_app.send_notification (this.museic_app.application_id, notification);
    }

    [CCode(instance_pos=-1)]
    public void action_play_file (Gtk.Button button) {
        if (this.museic_app.file != null) {
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
        var file_chooser = new Gtk.FileChooserDialog ("Open File", this, Gtk.FileChooserAction.OPEN, "_Cancel", Gtk.ResponseType.CANCEL, "_Open", Gtk.ResponseType.ACCEPT);
        if (file_chooser.run () == Gtk.ResponseType.ACCEPT) {
            // Pass file to prepare it for stream
            this.museic_app.open_file(file_chooser.get_filename ());
            // Update status label with filename
            (builder.get_object ("statusLabel") as Gtk.Label).set_label (this.museic_app.get_current_file());
            // Update info about duration and position each second
            GLib.Timeout.add_seconds (1, update_stream_status);
        }
        file_chooser.destroy ();
    }

    [CCode(instance_pos=-1)]
    public void action_change_time (Gtk.Scale slider) {

    }

    private bool update_stream_status() {
        // Update time label
        (this.builder.get_object ("timeLabel") as Gtk.Label).set_label (this.museic_app.get_position_str()+"/"+this.museic_app.get_duration_str());
        // Update progres bar
        ulong position = this.museic_app.get_position();
        ulong duration = this.museic_app.get_duration();
        double progres = (double)position/(double)duration;
        (this.builder.get_object ("scalebar") as Gtk.Scale).set_value (progres);
        // Check if stream, has ended
        if ((duration-position) < 100) return false;
        else return true;
    }

}
