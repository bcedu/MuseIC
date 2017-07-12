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
            this.museic_app.file = file_chooser.get_filename ();
            (builder.get_object ("statusLabel") as Gtk.Label).set_label (this.museic_app.file);
        }
        file_chooser.destroy ();
    }

}
