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
            }else if (message == "GET /info HTTP/1.1") correct_request = true;

            if (correct_request) {
                // Response: info about current file
                MuseicFile file = this.app.get_current_file();
                string content = @"{\"name\":\"$(file.name)\", \"artist\": \"$(file.artist)\", \"album\": \"$(file.album)\"}";
                var header = new StringBuilder ();
                header.append ("HTTP/1.0 200 OK\r\n");
                header.append ("Content-Type: application/json\r\n");
                header.append_printf ("Content-Length: %lu\r\n\r\n", content.length);

                ostream.write (header.str.data);
                ostream.write (content.data);
                ostream.flush ();
            }

    	}catch (Error e) {
            stdout.printf ("Error! %s\n", e.message);
    	}
    }

}

public class Source : Object {
	public uint16 port { private set; get; }

	public Source (uint16 port) {
		this.port = port;
	}
}
