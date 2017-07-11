using Gst;
public class StreamPlayer {
    private MainLoop loop;
    public dynamic Element player;

    public StreamPlayer (string[] args) {
        Gst.init (ref args);
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
        default:
            break;
        }
        return true;
    }

    public void play_file (string stream) {
        if (this.player == null) {
            this.player = ElementFactory.make ("playbin", "play");
            this.player.uri = stream;

            Gst.Bus bus = this.player.get_bus ();
            bus.add_watch (0, bus_callback);

            this.player.set_state (State.PLAYING);

        }else {
            this.player.uri = stream;
            this.player.set_state (State.PLAYING);
        }
    }

    public void pause_file () {
        this.player.set_state (State.PAUSED);
    }

    public void exit () {
        this.player.set_state (Gst.State.READY);
    }
}
