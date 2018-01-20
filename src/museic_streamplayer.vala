using Gst;

public class MuseicStreamPlayer {
    private MainLoop loop;
    public dynamic Element player;
    private ClockTime duration = Gst.CLOCK_TIME_NONE;
    public string state = "pause";
    public StreamMetadata? metadata = null;
    public string n;
    public double volume = 1.0;

    public MuseicStreamPlayer (string[]? args, string name) {
        if (args != null) Gst.init (ref args);
        if (name != null) this.n = name;
        else  this.n = "MAIN";
    }

    private static inline bool GST_CLOCK_TIME_IS_VALID (ClockTime time) {
		return ((time) != CLOCK_TIME_NONE);
	}

    private bool bus_callback (Gst.Bus bus, Gst.Message message) {
        switch (message.type) {
        case MessageType.ERROR:
            GLib.Error err;
            string debug;
            message.parse_error (out err, out debug);
            stdout.printf ("Error: %s\n", err.message);
            loop.quit ();
            break;
        case MessageType.EOS:
            this.state = "endstream";
            break;
        case MessageType.STATE_CHANGED:
            Gst.State oldstate;
            Gst.State newstate;
            Gst.State pending;
            message.parse_state_changed (out oldstate, out newstate, out pending);
            // stdout.printf ("state changed: %s->%s:%s\n", oldstate.to_string (), newstate.to_string (), pending.to_string ());
            break;
        case MessageType.TAG:
            if (this.metadata == null) {
                this.metadata = StreamMetadata();
                Gst.TagList tag_list;
                message.parse_tag (out tag_list);
                tag_list.get_string ("title", out this.metadata.title);
                tag_list.get_string ("album", out this.metadata.album);
                tag_list.get_string ("artist", out this.metadata.artist);
                tag_list = null;
                // stdout.printf(this.n+" -> STREAM Metadates: "+this.metadata.artist+"\n");
            }
        break;
        case Gst.MessageType.DURATION_CHANGED :
			// The duration has changed, mark the current one as invalid:
			this.duration = Gst.CLOCK_TIME_NONE;
			break;
        default:
            break;
        }
        return true;
    }

    public void play_file () {
        this.player.set_state (State.PLAYING);
        this.state = "play";
    }

    public void pause_file () {
        this.player.set_state (State.PAUSED);
        this.state = "pause";
    }

    public void exit () {
        this.player.set_state (State.READY);
    }

    public void ready_file(string stream) {
        pause_file();
        this.player.set_state (State.NULL);
        this.player = ElementFactory.make ("playbin", "play");
        this.player.uri = stream;
        this.player["volume"] = this.volume;
        this.metadata = null;
        this.state = "pause";
        Gst.Bus bus = this.player.get_bus ();
        bus.add_watch (0, bus_callback);
        play_file();
        // Dummy operations to wait enought time in order to make the streamer
        // be able to get duration of file.
        // Ugly AF. To improve.
        int aux = 0;
        while (aux<10000000) {
            aux = aux+1;
        }
        pause_file();
    }

    public ulong get_duration () {
        // Returns duration in nanoseconds
        if (!GST_CLOCK_TIME_IS_VALID (this.duration) && !this.player.query_duration (Gst.Format.TIME, out this.duration)) {
            stderr.puts ("Could not query current duration.\n");
            return (ulong) 0;
        }
        return (ulong) this.duration;
    }

    public ulong get_position () {
        // Returns position in nanoseconds
        int64 current = 0;
        if (!this.player.query_position (Gst.Format.TIME, out current)) {
            stderr.puts ("Could not query current position.\n");
        }
        return (ulong) current;
    }

    public void set_position(float fvalue) {
        this.player.seek_simple (Gst.Format.TIME, Gst.SeekFlags.FLUSH | Gst.SeekFlags.KEY_UNIT, (int64)(fvalue * this.get_duration()));
    }

    public void set_volume(double level) {
        if (level < 0) level = 0;
        else if (level > 2) level = 2;
        this.volume = level;
        this.player["volume"] = this.volume;
    }

}
