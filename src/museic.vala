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

const string DEFAULT_STREAM = "file:///home/bcedu/Projects/museIC/src/ex.mp3";
public class MuseIC : Gtk.Application {

    public string[] argsv;
    public MuseicStreamPlayer streamplayer;
    public string file;

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
        if (this.file != null) this.streamplayer.play_file ("file://"+this.file);
    }

    public void pause_file () {
        if (this.file != null) this.streamplayer.pause_file ();
    }

    public string state() {
        // Returns state of streamplayer. It can be: "play" or "pause"
        return this.streamplayer.state;
    }
}
