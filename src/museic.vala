/*
    * Copyright (c) 2011-2017 Eduard Berloso Clarà
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
    public MuseicStreamPlayer streamplayer;
    public MuseicFileList museic_filelist;
    public MuseicFileList museic_playlist;
    public MuseicLibrary museic_library;
    public MuseicGui main_window;
    public MprisPlayer mpris_player;
    public MuseicServer museic_server;
    public bool closed;

    public MuseIC (string[] args) {
        Object (application_id: "com.github.bcedu.museic", flags: ApplicationFlags.HANDLES_OPEN);
        argsv = args;
        // Create museic dir in home
        try {
            File file = File.new_for_path (Environment.get_home_dir()+"/.museic");
            if (!file.query_exists()) file.make_directory ();
        } catch (Error e) {
            stdout.printf ("Error: %s\n", e.message);
        }
    }

    public void action_open (File[] files, string hint) {
        // Activate, then play files
        this.activate ();
        string[] sfiles = {};
        foreach (unowned File file in files) sfiles += file.get_path();
        this.add_files_to_filelist(sfiles);
        this.play_filelist_file(0);
    }

    protected override void activate () {
        if (!this.closed) {
            this.streamplayer = new MuseicStreamPlayer(this.argsv, "MAIN");
            this.museic_filelist = new MuseicFileList("all");
            this.museic_playlist = new MuseicFileList("playlist");
            this.museic_library = new MuseicLibrary(Environment.get_home_dir()+"/.museic/museic_library_v2_0");
            this.museic_filelist.add_museic_files(this.museic_library.get_library_files_by_artist("all"), true, "filelist");
            setup_dbus();
            this.museic_server = new MuseicServer(this);
            this.main_window = new MuseicGui (this);
        }
        this.main_window.present();
        closed = false;
    }

    private void setup_dbus() {
        Bus.own_name(BusType.SESSION,
                    "org.mpris.MediaPlayer2.MuseIC",
                    GLib.BusNameOwnerFlags.NONE,
                    on_bus_acquired,
                    on_name_acquired,
                    on_name_lost);
    }

    private void on_bus_acquired (DBusConnection connection, string name) {
        stdout.printf("bus acquired\n");
        try {
            this.mpris_player = new MprisPlayer(this, connection);
            connection.register_object ("/org/mpris/MediaPlayer2", new MprisRoot(this));
            connection.register_object ("/org/mpris/MediaPlayer2", this.mpris_player);
        }
        catch(IOError e) {
            warning("could not create MPRIS player: %s\n", e.message);
        }
    }

    private void on_name_acquired(DBusConnection connection, string name) {
        stdout.printf("name acquired\n");
    }

    private void on_name_lost(DBusConnection connection, string name) {
        stdout.printf("name_lost\n");
    }

    public void update_dbus_status() {
        this.mpris_player.update_properties();
    }

    public static int main (string[] args) {
        GLib.Environ.set_variable ({"PULSE_PROP_media.role"}, "audio", "true");
        MuseIC app =  new MuseIC (args);
        app.open.connect(app.action_open);
        return app.run (args);
    }


    //// PLAYLIST AND FILELIST RELATED METHODS

    public void play_ant_file() {
        // Set the playlist pos to the ant file and ready it in stream.
        // If the origin of the new playlist file is "filelist", set filelist,
        // set filelist pos to ant file (of filelist).
        // If there isn't ant file in playlist, add the ant file of filelist
        // to the playlist and play it.
        if (!this.museic_playlist.has_ant()) this.museic_playlist.add_museic_file_init(this.museic_filelist.ant_file(), "filelist");
        else if (this.museic_playlist.get_ant_file().origin == "filelist") this.museic_filelist.ant_file();
        ready_file(this.museic_playlist.ant_file());
    }

    public void play_next_file() {
        // Set the playlist pos to the next file and ready it in stream.
        // If there isn't next file in playlist, add the next file of filelist
        // to the playlist and play it.
        if (!this.museic_playlist.has_next()) this.museic_playlist.add_museic_file(this.museic_filelist.next_file(), "filelist");
        else if (this.museic_playlist.get_next_file().origin == "filelist") this.museic_filelist.next_file();
        ready_file(this.museic_playlist.next_file());
    }

    public void play_playlist_file(int index) {
        // Set the playlist pos to the passed index and ready it in stream.
        this.museic_playlist.filepos = index;
        ready_file(this.museic_playlist.get_current_file());
    }

    public void play_filelist_file(int index) {
        // Set the filelist pos to the passed index, add it to playlist and ready it in stream.
        this.museic_filelist.filepos = index;
        int [] aux = new int[1];
        aux[0] = index;
        add_files_to_playlist(aux);
        play_playlist_file(0);
    }

    public void play_file () {
        // If there is a file in playlist, set streamplayer state to play
        if (this.museic_playlist.get_current_file().path != "") this.streamplayer.play_file ();
    }

    public void pause_file () {
        // If there is a file in playlist, set streamplayer state to pause
        if (this.museic_playlist.get_current_file().path != "") this.streamplayer.pause_file ();
    }

    public MuseicFile get_current_file() {
        // Returns current file from playlist
        return this.museic_playlist.get_current_file();
    }

    public MuseicFile get_ant_file() {
        // Returns the previous played file (ant file in playlist from current playlist file)
        // If no prevous file returns a MuseicFile with name "unknown"
        return this.museic_playlist.get_ant_file();
    }

    public MuseicFile get_next_file() {
        // Returns the next file to play (next on playlist if any, otherwise next from filelist)
        // If no next file or we are in random state returns a MuseicFile with name "unknown"
        if (this.museic_playlist.has_next()) return this.museic_playlist.get_next_file();
        else if (!this.is_random()) return this.museic_filelist.get_next_file();
        else return new MuseicFile("", "");
    }

    public MuseicFile get_current_filelist_file() {
        // Returns current file from filelist
        return this.museic_filelist.get_current_file();
    }

    public bool has_files() {
        // True if there is any file in playlist
        return get_current_file().name != "unknown";
    }

    public void add_files_to_filelist(string[] filenames) {
        // Store them on library
        this.museic_library.add_files(filenames, true);
        // Add the files from filenames to the filelist
        this.museic_filelist.add_museic_files(this.museic_library.get_library_files_by_artist("all"), true, "filelist");
    }

    public void add_files_to_playlist(int[] file_indexs) {
        // Add the files from filelist referenced with file_index to the playlist
        MuseicFile[] files = this.museic_filelist.get_files_list();
        foreach (int i in file_indexs) this.museic_playlist.add_museic_file(files[i], "quequed");
    }

    public void add_museic_files_to_playlist(MuseicFile[] files) {
        // Add the files from filelist to the playlist
        foreach (MuseicFile i in files) this.museic_playlist.add_museic_file(i, "quequed");
    }

    public void clear_filelist() {
        // Delete all files from the filelist.
        this.museic_filelist.clean();
    }

    public void clear_playlist() {
        // Delete all files from the playist.
        this.museic_playlist.clean();
    }

    public void delete_from_filelist(MuseicFile[] mfiles) {
        this.museic_filelist.delete_files(mfiles);
    }

    public void delete_from_playlist(MuseicFile[] mfiles) {
        this.museic_playlist.delete_files(mfiles);
    }

    public MuseicFile[] get_all_filelist_files() {
        // Get all files from filelist
        return this.museic_filelist.get_files_list();
    }

    public MuseicFileList get_active_filelist() {
        return this.museic_filelist.copy();
    }

    public MuseicFile[] get_all_playlist_files() {
        // Get all files from playlist
        return this.museic_playlist.get_files_list();
    }

    public int get_next_filelist_pos() {
        // Get position of next file in filelist
        int pos = this.museic_filelist.filepos + 1;
        if (pos >= this.museic_filelist.nfiles) pos = 0;
        return pos;
    }

    public int get_playlist_pos() {
        // Get position of file in playlist
        return this.museic_playlist.filepos;
    }

    public int get_filelist_len() {
        // Get number of files in filelist
        return this.museic_filelist.get_files_list().length;
    }

    public int get_playlist_len() {
        // Get number of files in playlist
        return this.museic_playlist.get_files_list().length;
    }

    public bool is_random() {
        // True if filelist is in random mode
        return this.museic_filelist.random_state;
    }

    public void set_random(bool random) {
        // Set the random state of filelist with the passed value
        this.museic_filelist.random_state = random;
    }

    public void set_filelist_sort_field(string field) {
        // Sets the name of the fields used to sort the filelist
        this.museic_filelist.sort_field = field;
    }

    public void sort_filelist() {
        // Sorts the filelist
        this.museic_filelist.sort();
    }

    public void clear_library() {
        this.museic_library.clear();
    }

    public void delete_from_library(MuseicFile[] mfiles) {
        this.museic_library.delete_files(mfiles);
    }

    public void reload_library() {
        // Stop stream
        this.pause_file();
        // Get all filelist files
        MuseicFile[] files = this.museic_filelist.get_files_list();
        // Get the paths
        string [] filenames = new string[files.length];
        for (int i=0;i<filenames.length;i++) filenames[i] = files[i].path;
        // Clear library, filelist and playlist
        this.clear_library();
        this.clear_filelist();
        this.clear_playlist();
        // Add files to library and filelist
        this.museic_library.add_files(filenames, true);
        this.museic_filelist.add_museic_files(this.museic_library.get_library_files_by_artist("all"), true, "filelist");
    }

    public string[] get_all_artists() {
        return this.museic_library.get_artists();
    }

    public void change_filelist(MuseicFileList flist) {
        // Change current filelist to a filelist with only files of passed artist.
        // If passed artist is "all", filelist will have all files.
        // After changing filelits, playlist is cleaned.
        pause_file();
        clear_playlist();
        clear_filelist();
        this.museic_filelist = flist.copy();
    }


    //// STREAM RELATED METHODS

    public void set_position(float fvalue) {
        this.streamplayer.set_position (fvalue);
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

    public string state() {
        // Returns state of streamplayer. It can be: "play", "pause" or "endstream"
        return this.streamplayer.state;
    }

    private void ready_file(MuseicFile file) {
        // Add the file to the stream. If previous state was "play", play the new file
        if (state() == "play" || state() == "endstream") {
            this.streamplayer.ready_file("file://"+file.path);
            play_file();
        }else this.streamplayer.ready_file("file://"+file.path);
    }

    public void set_stream_volume(double level) {
        this.streamplayer.set_volume(level);
    }

    public double get_stream_volume() {
        return this.streamplayer.volume;
    }

    public int get_used_port() {
        return (int)this.museic_server.get_used_port();
    }

    public void save_used_port(int new_port){
        this.museic_server.save_used_port((uint16)new_port);
    }

}
