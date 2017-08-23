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
            bool correct_request = false;
            bool json_request = true;
    		if (message == "GET /shutdown HTTP/1.1") {
    			cancellable.cancel ();
                correct_request = true;
    		}else if (message == "GET /play HTTP/1.1") {
    			this.app.mpris_player.PlayPause();
                correct_request = true;
    		}else if (message == "GET /next HTTP/1.1") {
    			this.app.mpris_player.Next();
                this.app.main_window.notify(this.app.get_current_file().name);
                correct_request = true;
    		}else if (message == "GET /prev HTTP/1.1") {
    			this.app.mpris_player.Previous();
                this.app.main_window.notify(this.app.get_current_file().name);
                correct_request = true;
            }else if (message == "GET /info HTTP/1.1") {
                correct_request = true;
            }else if (message == "GET /player HTTP/1.1" || message == "GET / HTTP/1.1") {
                correct_request = true;
                json_request = false;
            }else if (message == "GET /random HTTP/1.1") {
                correct_request = true;
                this.app.main_window.toggle_random();
            }

            if (correct_request && json_request) {
                // Response: json with info about current file
                ostream.write (this.get_file_data_json(this.app.get_current_file(), this.app.state(), this.app.is_random()).data);
                ostream.flush ();
            }else if (correct_request) {
                // Response: html page with player
                ostream.write (this.get_html_player(this.app.get_current_file()).data);
                ostream.flush ();
            }
    	}catch (Error e) {
            stdout.printf ("Error! %s\n", e.message);
    	}
    }

    private string get_file_data_json(MuseicFile file, string status, bool random) {
        var res = new StringBuilder ();
        res.append ("HTTP/1.0 200 OK\r\n");
        res.append ("Content-Type: application/json\r\n");
        string srandom = random.to_string();
        string content = @"{\"name\":\"$(file.name)\", \"artist\": \"$(file.artist)\", \"album\": \"$(file.album)\", \"status\": \"$status\", \"random\": \"$srandom\"}";
        res.append_printf ("Content-Length: %lu\r\n\r\n", content.length);
        res.append(content);
        return res.str;
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

}


public class Source : Object {
	public uint16 port { private set; get; }

	public Source (uint16 port) {
		this.port = port;
	}
}
