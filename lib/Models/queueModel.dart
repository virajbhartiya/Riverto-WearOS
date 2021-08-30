class QueueModel {
  String title, url, album, artist, id, lyrics;
  QueueModel(
      {this.title, this.url, this.album, this.artist, this.id, this.lyrics});
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'url': url,
      'album': album,
      'artist': artist,
      'lyrics': lyrics,
      'id': id,
    };
  }
}
