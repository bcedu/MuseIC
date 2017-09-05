public class MuseicServer : GLib.Object {

    private MuseIC app;
    private SocketService service;
    private Cancellable cancellable;

    public MuseicServer(MuseIC app) {
        this.app = app;

		// Create a new SocketService:
		this.service = new SocketService ();

		// Listen on port 1024 and 1025.
		// Source is used as source-identifier.
		service.add_inet_port (1024, new Source (1024));
		service.add_inet_port (1025, new Source (1025));

		// Used to shutdown the program:
		this.cancellable = new Cancellable ();
		this.cancellable.cancelled.connect(close_connection);

		this.service.incoming.connect(accept_connection);

		this.service.start ();
    }

    private bool accept_connection(SocketConnection connection, Object? source_object) {
        Source source = source_object as Source;

        stdout.printf ("Accepted! (Source: %d)\n", source.port);
        worker_func.begin (connection, source, cancellable);
        return false;
    }

    public void close_connection() {
        this.service.stop ();
        this.app.quit();
    }

    public async void worker_func (SocketConnection connection, Source source, Cancellable cancellable) {
    	try {
    		DataInputStream istream = new DataInputStream (connection.input_stream);
    		DataOutputStream ostream = new DataOutputStream (connection.output_stream);

    		// Get the received message:
    		string message = yield istream.read_line_async (Priority.DEFAULT, cancellable);
    		message._strip ();
    		stdout.printf ("Received: %s\n", message);
    		if (message == "GET /shutdown HTTP/1.1") {
    			cancellable.cancel ();
    		}else if (message == "GET /play HTTP/1.1") {
    			this.app.mpris_player.PlayPause();
                this.send_current_status(ostream);
    		}else if (message == "GET /next HTTP/1.1") {
    			this.app.mpris_player.Next();
                this.app.main_window.notify(this.app.get_current_file().name);
                this.send_current_status(ostream);
    		}else if (message == "GET /prev HTTP/1.1") {
    			this.app.mpris_player.Previous();
                this.app.main_window.notify(this.app.get_current_file().name);
                this.send_current_status(ostream);
            }else if (message == "GET /info HTTP/1.1") {
                this.send_current_status(ostream);
            }else if (message == "GET /player HTTP/1.1" || message == "GET / HTTP/1.1") {
                this.send_html_player(ostream);
            }else if (message == "GET /random HTTP/1.1") {
                this.app.main_window.toggle_random();
                this.send_current_status(ostream);
            }else if (message == "GET /filelist HTTP/1.1") {
                this.send_museic_list(ostream, this.app.get_all_filelist_files());
            }else if (message == "GET /playlist HTTP/1.1") {
                this.send_museic_list(ostream, this.app.get_all_playlist_files());
            }else if (message == "GET /info-ant-next HTTP/1.1") {
                /* Returns info about previous (if any) and next (if any) files */
                this.send_prev_next_info(ostream);
            }else if (message.split("/").length > 3 && message.split("/")[0] == "GET " && message.split("/")[1] == "search")  // search request
                /*
                    Check if split by '/' is len > 3: we need "GET ", "search" and "{text_to_search} HTTP"
                    Split by " " and get first elem to get only the {text_to_search} instead of the hole "{text_to_search} HTTP".
                    The {text_to_search} has "_" instead of spaces, so we replace them when searching for files.

                    Example of search request: "GET /search/Muse_Knights_Cydonia HTTP/1.1"
                */
                this.send_search_results(ostream, message.split("/")[2].split(" ")[0].replace("_", " "));
            else if (message.split("/").length > 3 && message.split("/")[0] == "GET " && message.split("/")[1] == "play-file") { // play-file request
                /*
                    Check if split by '/' is len > 3: we need "GET ", "ply-file" and "{name--artist--album} HTTP"
                    Split by " " and get first elem to get only the {name--artist--album} instead of the hole "{name--artist--album} HTTP".
                    The {name--artist--album} has "_" instead of spaces, so we replace them when searching for files.
                    Finnaly we split by "--" to get the name, artist and album.

                    Example of search request: "GET /play-file/Knights_Of_Cydonia--Muse--Black_Holes_And_Revelations HTTP/1.1"
                */
                string aux = message.split("/")[2].split(" ")[0].replace("_", " ").replace("&amp;", "&");
                this.play_file(aux.split("--")[0], aux.split("--")[1], aux.split("--")[2]);
                this.send_current_status(ostream);
            }else if (message.split("/").length > 3 && message.split("/")[0] == "GET " && message.split("/")[1] == "queque-file") { // queque-file request
                /*
                    Check if split by '/' is len > 3: we need "GET ", "queque-file" and "{name--artist--album} HTTP"
                    Split by " " and get first elem to get only the {name--artist--album} instead of the hole "{name--artist--album} HTTP".
                    The {name--artist--album} has "_" instead of spaces, so we replace them when searching for files.
                    Finnaly we split by "--" to get the name, artist and album.

                    Example of search request: "GET /queque-file/Knights_Of_Cydonia--Muse--Black_Holes_And_Revelations HTTP/1.1"
                */
                string aux = message.split("/")[2].split(" ")[0].replace("_", " ").replace("&amp;", "&");
                this.queque_file(aux.split("--")[0], aux.split("--")[1], aux.split("--")[2]);
                this.send_prev_next_info(ostream);
            }
    	}catch (Error e) {
            stdout.printf ("Error! %s\n", e.message);
    	}
    }

    private void send_current_status(DataOutputStream ostream) {
        // Response: json with info about current file
        ostream.write (this.get_current_data_json(this.app.get_current_file(), this.app.state(), this.app.is_random()).data);
        ostream.flush ();
    }

    private void send_html_player(DataOutputStream ostream) {
        // Response: html page with player
        ostream.write (this.get_html_player(this.app.get_current_file()).data);
        ostream.flush ();
    }

    private void send_museic_list(DataOutputStream ostream, MuseicFile[] fileslist) {
        // Response: json with list of Museic files
        var res = new StringBuilder ();
        res.append ("HTTP/1.0 200 OK\r\n");
        res.append ("Content-Type: application/json\r\n");
        var content = new StringBuilder ();
        content.append("{\"museic_list\": [");
        foreach (MuseicFile file in fileslist[0:fileslist.length-1])
            content.append(this.get_file_data_json(file)+",");
        // Don't add "," in last file
        content.append(this.get_file_data_json(fileslist[fileslist.length-1]));
        content.append("]}");
        res.append_printf ("Content-Length: %lu\r\n\r\n", content.str.length);
        res.append(content.str);
        ostream.write (res.data);
        ostream.flush ();
    }

    private void send_prev_next_info(DataOutputStream ostream) {
        // Response: json with info about next abd previous files
        var res = new StringBuilder ();
        res.append ("HTTP/1.0 200 OK\r\n");
        res.append ("Content-Type: application/json\r\n");
        var content = new StringBuilder ();
        content.append("{");

        MuseicFile next = this.app.get_next_file();
        if (next.name != "unknown") {
            content.append("\"next_file\": "+this.get_file_data_json(next));
        }

        MuseicFile ant = this.app.get_ant_file();
        if (ant.name != "unknown") {
            if (next.name != "unknown") content.append(",");
            content.append("\"ant_file\": "+this.get_file_data_json(ant));
        }

        content.append("}");
        res.append_printf ("Content-Length: %lu\r\n\r\n", content.str.length);
        res.append(content.str);
        ostream.write (res.data);
        ostream.flush ();
    }

    private void send_search_results(DataOutputStream ostream, string search_text) {
        // Response: json with list of Museic files which contains search_text
        MuseicFile[] filtered_list = new MuseicFile[4];
        int nfiles = 0;
        foreach (MuseicFile file in this.app.get_all_filelist_files()) {
            if (pass_filter(search_text, file)) {
                filtered_list[nfiles] = file;
                nfiles += 1;
                if (nfiles == filtered_list.length) filtered_list.resize(filtered_list.length*2);
            }
        }
        if (nfiles == 0) {
            MuseicFile aux = new MuseicFile("", "");
            aux.name = "No results :(";
            aux.artist = "";
            aux.album = "";
            filtered_list[0] = aux;
            this.send_museic_list(ostream, filtered_list[0:1]);
        }else this.send_museic_list(ostream, filtered_list[0:nfiles]);
    }

    private bool pass_filter(string text, MuseicFile file) {
        if (text == "") return true;
        bool filter_passed = true;
        foreach (string aux in text.split(" ")) {
            if ((file.name.contains(aux) || file.artist.contains(aux) || file.album.contains(aux)) && filter_passed) filter_passed = true;
            else filter_passed = false;
        }
        if (file.artist == "Muse") stdout.printf("TEXT: |%s|, FILE:|%s|%s|%s|, succes:%s\n", text, file.name, file.artist, file.album, filter_passed.to_string());
        return filter_passed;
    }

    private string get_current_data_json(MuseicFile file, string status, bool random) {
        var res = new StringBuilder ();
        res.append ("HTTP/1.0 200 OK\r\n");
        res.append ("Content-Type: application/json\r\n");
        string srandom = random.to_string();
        string file_json = this.get_file_data_json(file);
        string content = @"{\"status\": \"$status\", \"random\": \"$srandom\", \"file\": $file_json}";
        res.append_printf ("Content-Length: %lu\r\n\r\n", content.length);
        res.append(content);
        return res.str;
    }

    private string get_file_data_json(MuseicFile file) {
        string name = this.clean_string(file.name);
        string artist = this.clean_string(file.artist);
        string album = this.clean_string(file.album);
        return @"{\"name\":\"$name\", \"artist\": \"$artist\", \"album\": \"$album\"}";
    }

    public string clean_string(string text) {
        string aux = text.strip();
        aux = aux.replace("\"", "''");
        aux = aux.replace("\t", "");
        return aux;
    }

    private string get_html_player(MuseicFile file) {
        var res = new StringBuilder ();
        res.append ("HTTP/1.0 200 OK\r\n");
        res.append ("Content-Type: text/html\r\n");

        File aux = File.new_for_path(Constants.HTMLDIR+"client.html");
        DataInputStream reader = new DataInputStream(aux.read());
        string line;
        var aux_content = new StringBuilder ();
        while ((line=reader.read_line(null)) != null) aux_content.append(line);

        string content = aux_content.str.replace("*TITLE*", file.name);
        content = content.replace("*ARTIST*", file.artist);
        content = content.replace("*ALBUM*", file.album);
        res.append_printf ("Content-Length: %lu\r\n\r\n", content.length);
        res.append(content);
        return res.str;
    }

    public string get_server_info() {
        return this.resolve_server_address()+":1025";
    }

    public string resolve_server_address() {
        // Resolve hostname to IP address
       var resolver = Resolver.get_default ();
       var addresses = resolver.lookup_by_name ("www.google.com", null);
       var address = addresses.nth_data (0);

       var client = new SocketClient ();
       var conn = client.connect (new InetSocketAddress (address, 80));
       InetSocketAddress local = conn.get_local_address() as InetSocketAddress;
       return local.get_address().to_string();
    }

    private void play_file(string name, string artist, string album) {
        MuseicFile[] files = this.app.get_all_filelist_files();
        for (int index=0; index < files.length; index++) {
            if (pass_filter(name+" "+artist+" "+album, files[index])) {
                this.app.main_window.action_play_selected_file_filelist(new Gtk.TreeView(), new Gtk.TreePath.from_string(index.to_string()), new Gtk.TreeViewColumn());
                index = files.length;
            }
        }
    }

    private void queque_file(string name, string artist, string album) {
        MuseicFile[] files = this.app.get_all_filelist_files();
        for (int index=0; index < files.length; index++) {
            if (pass_filter(name+" "+artist+" "+album, files[index])) {
                int[] files_to_queque = new int[1];
                files_to_queque[0] = index;
                this.app.add_files_to_playlist(files_to_queque);
                this.app.main_window.update_playlist_to_tree();
                index = files.length;
            }
        }
    }

}


public class Source : Object {
	public uint16 port { private set; get; }

	public Source (uint16 port) {
		this.port = port;
	}
}
