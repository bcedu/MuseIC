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

    
    public class MuseIC : Gtk.Application {

        public MuseIC () {
            Object (application_id: "com.github.bcedu.MuseIC",
            flags: ApplicationFlags.FLAGS_NONE);
        }

        protected override void activate () {
            var app_window = new Gtk.ApplicationWindow (this);
            
            var grid = new Gtk.Grid ();
            grid.orientation = Gtk.Orientation.VERTICAL;
            grid.row_spacing = 6;
            
            var title_label = new Gtk.Label (_("Notifications"));
            
            var show_button = new Gtk.Button.with_label (_("Show"));
            show_button.clicked.connect (() => {
                var notification = new Notification (_("Hello World"));
                
                var image = new Gtk.Image.from_icon_name ("dialog-warning", Gtk.IconSize.DIALOG);
                notification.set_icon (image.gicon);
                
                notification.set_body (_("This is my first notification!"));
                this.send_notification ("notify.app", notification);
            });
            
            var replace_button = new Gtk.Button.with_label (_("Replace"));
            replace_button.clicked.connect (() => {
                var notification = new Notification (_("Hello Again"));
                notification.set_body (_("This is my second Notification!"));
            
                var image = new Gtk.Image.from_icon_name ("dialog-warning", Gtk.IconSize.DIALOG);
                notification.set_icon (image.gicon);
            
                this.send_notification ("com.github.bcedu.MuseIC", notification);
            });
            
            grid.add (title_label);
            grid.add (show_button);
            grid.add (replace_button);
            
            app_window.add (grid);
            app_window.show_all ();

            app_window.show ();
        }

        public static int main (string[] args) {
            var app = new MuseIC ();
            return app.run (args);
        }
    }

    