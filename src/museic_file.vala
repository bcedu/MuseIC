public class MuseicFile {

    public string path;
    public string name;
    public string artist;
    public string album;
    public string duration;

    public MuseicFile (string path) {
        this.path = path;
        if (path.split("/").length > 1) this.name = path.split("/")[path.split("/").length-1];
        else this.name = path;
        this.artist = "some artist";
        this.album = "some album";
        this.duration = "some mm:ss";
    }

}
