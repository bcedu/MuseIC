public class MuseicFile {

    public string path;
    public string name;
    public string artist;
    public string album;
    public string duration;

    public MuseicFile (string path, MuseicStreamPlayer? auxplayer=null) {
        this.path = path;
        if (path != "") {
            // MuseicStreamPlayer? auxplayer = new MuseicStreamPlayer(null, "AUX");
            // auxplayer.ready_file("file://"+path);
            // if (auxplayer != null && auxplayer.metadata != null) {
            //     if (auxplayer.metadata.title != null) this.name = auxplayer.metadata.title;
            //     else if (path.split("/").length >= 1) this.name = path.split("/")[path.split("/").length-1];
            //     else this.name = path;
            //     this.artist = auxplayer.metadata.artist;
            //     this.album = auxplayer.metadata.album;
            //     this.duration = "some mm:ss";
            //     stdout.printf(this.path+"-> Metadates: "+this.artist+"\n");
            // }else {stdout.printf("AUX: still no mETADATES :(\n");}
        }
        if (path.split("/").length >= 1) this.name = path.split("/")[path.split("/").length-1];
        else this.name = path;
    }

}
