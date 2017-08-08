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

public struct StreamMetadata {
    public string title;
    public string album;
    public string artist;
}

public class MuseIC : Gtk.Application {

    public string[] argsv;
    private MuseicStreamPlayer streamplayer;
    private MuseicFileList museic_filelist;
    private MuseicFileList museic_playlist;

    public MuseIC (string[] args) {
        Object (application_id: "com.github.bcedu.MuseIC", flags: ApplicationFlags.FLAGS_NONE);
        argsv = args;
    }

    protected override void activate () {
        this.streamplayer = new MuseicStreamPlayer(this.argsv, "MAIN");
        this.museic_filelist = new MuseicFileList();
        this.museic_playlist = new MuseicFileList();
        new MuseicGui (this);
    }

    public static int main (string[] args) {
        return new MuseIC (args).run (args);
    }

    public void play_file (int? index_file) {
        if (index_file != null && this.museic_playlist.nfiles > index_file) {
            this.museic_playlist.filepos = index_file;
            this.streamplayer.ready_file("file://"+this.museic_playlist.get_current_file().path);
        }
        if (this.museic_playlist.get_current_file().path != "") this.streamplayer.play_file ();
        else if (this.museic_filelist.get_current_file().path != "") {
            ready_file_to_play();
            this.streamplayer.play_file ();
        }
    }

    public void pause_file () {
        if (this.museic_playlist.get_current_file().path != "") this.streamplayer.pause_file ();
    }

    public string state() {
        // Returns state of streamplayer. It can be: "play", "pause" or "endstream"
        return this.streamplayer.state;
    }

    public void open_files (string[] filenames, bool clean_museic_filelist) {
        this.museic_filelist.add_files(filenames, clean_museic_filelist, true);
        if (clean_museic_filelist) {
            this.museic_playlist.clean();
            ready_file_to_play();
        }
    }

    public void ready_file_to_play() {
        this.museic_playlist.add_museic_file(this.museic_filelist.get_current_file());
        this.streamplayer.ready_file("file://"+this.museic_playlist.get_current_file().path);
    }

    public void ready_seg_file_to_play() {
        if (!this.museic_playlist.has_next()) this.museic_playlist.add_museic_file(this.museic_filelist.seg_file());
        this.museic_playlist.seg_file();
        this.streamplayer.ready_file("file://"+this.museic_playlist.get_current_file().path);
    }

    public void ready_ant_file_to_play() {
        this.museic_playlist.ant_file();
        this.streamplayer.ready_file("file://"+this.museic_playlist.get_current_file().path);
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

    public string get_current_filename() {
        return this.museic_playlist.get_current_file().name;
    }

    public MuseicFile get_current_file() {
        return this.museic_playlist.get_current_file();
    }

    public int get_current_file_pos() {
        return this.museic_playlist.filepos;
    }

    public int get_next_filelist_pos() {
        int pos = this.museic_filelist.filepos + 1;
        if (pos >= this.museic_filelist.nfiles) pos = 0;
        return pos;
    }

    public int get_filelist_len() {
        return this.museic_filelist.get_files_list().length;
    }

    public string[] get_all_filenames() {
        string[] sfiles = {};
        foreach (MuseicFile file in this.museic_filelist.get_files_list()) {
            sfiles += file.name;
        }
        return sfiles;
    }

    public MuseicFile[] get_all_files() {
        return this.museic_filelist.get_files_list();
    }


    public MuseicFile[] get_all_playlist_files() {
        return this.museic_playlist.get_files_list();
    }

    public void set_position(float value) {
        this.streamplayer.player.seek_simple (Gst.Format.TIME, Gst.SeekFlags.FLUSH | Gst.SeekFlags.KEY_UNIT, (int64)(value * get_duration()));
    }

    public bool has_files() {
        return get_current_filename() != "unknown";
    }

    public void seg_file() {
        if (has_files()) {
            bool play = (state() == "play") || (state() == "endstream");
            pause_file();
            ready_seg_file_to_play();
            if (play) play_file(null);
        }
    }

    public void ant_file() {
        if (has_files()) {
            bool play = (state() == "play") || (state() == "endstream");
            pause_file();
            ready_ant_file_to_play();
            if (play) play_file(null);
        }
    }

    public void set_random(bool random) {
        this.museic_filelist.random_state = random;
    }

    public bool is_random() {
        return this.museic_filelist.random_state;
    }

    public void add_files_to_play(int[] file_indexs) {
        MuseicFile[] files = this.museic_filelist.get_files_list();
        foreach (int i in file_indexs) this.museic_playlist.add_museic_file(files[i]);
    }
}
