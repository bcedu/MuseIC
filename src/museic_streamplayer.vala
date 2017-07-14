using Gst;
public class MuseicStreamPlayer {
    private MainLoop loop;
    public dynamic Element player;
    private ClockTime duration = Gst.CLOCK_TIME_NONE;
    public string state = "pause";

    public MuseicStreamPlayer (string[] args) {
        Gst.init (ref args);
    }

    private static inline bool GST_CLOCK_TIME_IS_VALID (ClockTime time) {
		return ((time) != CLOCK_TIME_NONE);
	}

    private void foreach_tag (Gst.TagList list, string tag) {
        switch (tag) {
        case "title":
            string tag_string;
            list.get_string (tag, out tag_string);
            stdout.printf ("tag: %s = %s\n", tag, tag_string);
            break;
        default:
        break;
        }
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
            stdout.printf ("end of stream\n");
            break;
        case MessageType.STATE_CHANGED:
            Gst.State oldstate;
            Gst.State newstate;
            Gst.State pending;
            message.parse_state_changed (out oldstate, out newstate, out pending);
            stdout.printf ("state changed: %s->%s:%s\n", oldstate.to_string (), newstate.to_string (), pending.to_string ());
            break;
        case MessageType.TAG:
            Gst.TagList tag_list;
            stdout.printf ("taglist found\n");
            message.parse_tag (out tag_list);
            tag_list.foreach ((TagForeachFunc) foreach_tag);
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
        this.player = ElementFactory.make ("playbin", "play");
        this.player.uri = stream;
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
        // Returns duration in nanoseconds
        int64 current = 0;
        if (!this.player.query_position (Gst.Format.TIME, out current)) {
            stderr.puts ("Could not query current position.\n");
        }
        return (ulong) current;
    }

}
