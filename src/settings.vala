public class Museic.Settings : Granite.Services.Settings {

    public int window_width { get; set; }
    public int window_height { get; set; }
    public int window_posx { get; set; }
    public int window_posy { get; set; }
    public int window_state { get; set; }

    private static Settings _settings;

    public static unowned Settings get_default () throws Error {
        if (_settings == null) _settings = new Settings ();
        return _settings;
    }

    private Settings () throws Error {
        base ("com.github.bcedu.museic.settings");
    }
}
