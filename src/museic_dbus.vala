[DBus(name = "org.mpris.MediaPlayer2")]
public class MprisRoot : GLib.Object {

    MuseIC app;

    public MprisRoot(MuseIC app) {
        this.app = app;
    }

    public bool CanQuit {
        get {return true;}
    }

    public bool CanRaise {
        get {return true;}
    }

    public bool HasTrackList {
        get {return false;}
    }
    public string DesktopEntry {
        get {return "com.github.bcedu.museic";}
    }

    public string Identity {
        get {return "MuseIC";}
    }

    public string[] SupportedUriSchemes {
        owned get {
            string[] sa = {"http", "file", "https", "ftp"};
            return sa;
        }
    }

    public string[] SupportedMimeTypes {
        owned get {
            string[] sa = {"x-content/audio-player", "x-content/audio-cdda", "application/ogg", "application/x-extension-m4a", "application/x-extension-mp4", "application/x-flac", "application/x-ogg", "audio/3gpp", "audio/aac", "audio/ac3", "audio/AMR", "audio/AMR-WB", "audio/basic", "audio/flac", "audio/midi", "audio/mp2", "audio/mp4", "audio/mpeg", "audio/ogg", "audio/vnd.rn-realaudio", "audio/x-aiff", "audio/x-ape", "audio/x-flac", "audio/x-gsm", "audio/x-it", "audio/x-m4a", "audio/x-matroska", "audio/x-mod", "audio/x-mp3", "audio/x-mpeg", "audio/x-mpegurl", "audio/x-ms-asf", "audio/x-ms-asx", "audio/x-ms-wax", "audio/x-ms-wma", "audio/x-musepack", "audio/x-opus+ogg", "audio/x-pn-aiff", "audio/x-pn-au", "audio/x-pn-realaudio", "audio/x-pn-realaudio-plugin", "audio/x-pn-wav", "audio/x-pn-windows-acm", "audio/x-realaudio", "audio/x-real-audio", "audio/x-sbc", "audio/x-scpls", "audio/x-speex", "audio/x-tta", "audio/x-vorbis", "audio/x-vorbis+ogg", "audio/x-wav", "audio/x-wavpack", "audio/x-xm"};
            return sa;
        }
    }

    public void Quit () {
        this.app.main_window.destroy ();
    }

    public void Raise () {
        this.app.main_window.present ();
    }
}

[DBus(name = "org.mpris.MediaPlayer2.Player")]
public class MprisPlayer : GLib.Object {

    MuseIC app;
    private unowned DBusConnection conn;

    public MprisPlayer(MuseIC app, DBusConnection conn) {
        this.app = app;
        this.conn = conn;
    }

    private bool send_property_change(string property, Variant variant) {
        var builder = new VariantBuilder(VariantType.ARRAY);
        var invalidated_builder = new VariantBuilder(new VariantType("as"));
        builder.add("{sv}", property, variant);

        try {
            conn.emit_signal (null,
                              "/org/mpris/MediaPlayer2",
                              "org.freedesktop.DBus.Properties",
                              "PropertiesChanged",
                              new Variant("(sa{sv}as)",
                                         "org.mpris.MediaPlayer2.Player",
                                         builder,
                                         invalidated_builder)
                             );
        }
        catch(Error e) {
            print("Could not send MPRIS property change: %s\n", e.message);
        }
        return false;
    }

    public void update_properties() {
        send_property_change("PlaybackStatus", this.PlaybackStatus);
        send_property_change("Metadata", get_metadata());
    }

    public void Next() {
        this.app.play_next_file();
        this.app.main_window.update_stream_status();
        this.app.main_window.update_playlist_to_tree();
        update_properties();
    }

    public void Previous() {
        this.app.play_ant_file();
        this.app.main_window.update_stream_status();
        this.app.main_window.update_playlist_to_tree();
        update_properties();
    }

    public void Pause() {
        this.app.main_window.update_play_button();
        this.app.pause_file();
        update_properties();
    }

    public void PlayPause() {
        this.app.main_window.update_play_button();
        if (this.app.state() != "play") this.app.play_file();
        else this.app.pause_file();
        update_properties();
    }

    public void Stop() {
        this.app.main_window.update_play_button();
        this.app.pause_file();
        update_properties();
    }

    public void Play() {
        this.app.main_window.update_play_button();
        this.app.play_file();
        update_properties();
    }

    public void Seek(int64 Offset) {
        long pos =  ((long) Offset * 1000) + (long) this.app.get_position();

        if (pos < 0) pos = 0;
        else if (pos > (long)this.app.get_duration()) Next();
        else this.app.set_position(pos/(long)this.app.get_duration());
    }

    public void SetPosition(string dobj, int64 Position) {
        long pos =  ((long) Position * 1000);

        if (pos < 0) return;
        else if (pos > (long)this.app.get_duration()) return;
        else this.app.set_position(pos/(long)this.app.get_duration());
    }

    public void OpenUri(string Uri) {
        stdout.printf("URI TO OPEN: %s\n", Uri);
    }

    public signal void Seeked(int64 Position);

    public string PlaybackStatus {
        get {
            if (!this.app.has_files()) return "Stopped";
            else if(this.app.state() == "play") return "Playing";
            else return "Paused";
        }
    }

    public double Rate {
        get {return (double)1.0;}
        set {}
    }

    public HashTable<string,Variant>? Metadata {
        owned get {
            return get_metadata();
        }
    }

    private static string[] get_simple_string_array (string? text) {
        if (text == null)
            return new string [0];
        string[] array = new string[0];
        array += text;
        return array;
    }

    private HashTable<string,Variant>? get_metadata() {
        MuseicFile act = this.app.get_current_file();
        HashTable<string,Variant> _metadata = new HashTable<string, Variant> (null, null);

        _metadata.insert("mpris:trackid", new ObjectPath ("/org/museic/Track/%s".printf (act.path)));
        _metadata.insert("mpris:length", (int64) (this.app.get_duration()/1000));
        _metadata.insert("xesam:title", act.name);
        _metadata.insert("xesam:album", get_simple_string_array(act.album)); // Why is needed a list of fucking arrays?!
        _metadata.insert("xesam:artist", get_simple_string_array(act.artist));
        _metadata.insert("xesam:url", act.path);
        _metadata.insert("mpris:artUrl", "file://"+Constants.ICON);

        return _metadata;
    }

    public double Volume {
        get{
            return 1;
        }
        set {}
    }

    public int64 Position {
        get {
            return (int64) (this.app.get_position()/1000);
        }
    }


    public bool CanGoNext {
        get {
            return true;
        }
    }

    public bool CanGoPrevious {
        get {
            return true;
        }
    }

    public bool CanPlay {
        get {
            return true;
        }
    }

    public bool CanPause {
        get {
            return true;
        }
    }

    public bool CanSeek {
        get {
            return true;
        }
    }

    public bool CanControl {
        get {
            return true;
        }
    }

}
