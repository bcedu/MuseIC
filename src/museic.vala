/*
    * Copyright (c) 2011-2017 Your Organization (https://yourwebsite.com)
    *
    * This program is free software; you can redistribute it and/or
    * modify it under the terms of the GNU General Public
    * License as published by the Free Software Foundation; either
    * version 2 of the License, or (at your option) any later version.
    *
    * This program is distributed in the hope that it will be useful,
    * but WITHOUT ANY WARRANTY; without even the implied warranty of
    * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    * General Public License for more details.
    *
    * You should have received a copy of the GNU General Public
    * License along with this program; if not, write to the
    * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
    * Boston, MA 02110-1301 USA
    *
    * Authored by: Eduard Berloso Clarà <eduard.bc.95@gmail.com>
    */

public struct StreamTimeInfo {
    public ulong nanoseconds;
    public string minutes;
}

public class MuseIC : Gtk.Application {

    public string[] argsv;
    private MuseicStreamPlayer streamplayer;
    public string file = "";

    public MuseIC (string[] args) {
        Object (application_id: "com.github.bcedu.MuseIC", flags: ApplicationFlags.FLAGS_NONE);
        argsv = args;
    }

    protected override void activate () {
        this.streamplayer = new MuseicStreamPlayer(this.argsv);
        new MuseicGui (this);
    }

    public static int main (string[] args) {
        return new MuseIC (args).run (args);
    }

    public void play_file () {
        if (this.file != "") this.streamplayer.play_file ();
    }

    public void pause_file () {
        if (this.file != "") this.streamplayer.pause_file ();
    }

    public string state() {
        // Returns state of streamplayer. It can be: "play" or "pause"
        return this.streamplayer.state;
    }

    public void open_file (string filename) {
        // store filename
        this.file = filename;
        // preapre file in streamplayer
        this.streamplayer.ready_file("file://"+this.file);
    }

    public StreamTimeInfo get_duration_str() {
        // Returns a struct with duration of current file in nanoseconds and string format %M:%S
        ulong dur = this.streamplayer.get_duration();
        return {dur, nanoseconds_to_minutes_string(dur)};
    }

    public StreamTimeInfo get_position_str() {
        // Returns a struct with position of current file in nanoseconds and string format %M:%S
        ulong pos = this.streamplayer.get_position();
        return {pos, nanoseconds_to_minutes_string(pos)};
    }

    public ulong get_duration() {
		// Returns duration
        return this.streamplayer.get_duration();
    }

    public ulong get_position() {
        // Returns position
        return this.streamplayer.get_position();
    }

    private string nanoseconds_to_minutes_string(ulong nanoseconds) {
        // Given nanoseconds, transform to minutes and seconds and returns in string with format %M:%S
        int total_seconds = (int)(nanoseconds / 1000000000);
        int minutes = total_seconds / 60;
        int seconds = total_seconds % 60;
        string smin = minutes < 10 ? "0"+minutes.to_string () : minutes.to_string ();
        string ssec = seconds < 10 ? "0"+seconds.to_string () : seconds.to_string ();
        return smin+":"+ssec;
    }

    public string get_current_file() {
        return this.file.split("/")[this.file.split("/").length-1];
    }

    public void set_position(float value) {
        this.streamplayer.player.seek_simple (Gst.Format.TIME, Gst.SeekFlags.FLUSH | Gst.SeekFlags.KEY_UNIT, (int64)(value * get_duration()));
    }
}
