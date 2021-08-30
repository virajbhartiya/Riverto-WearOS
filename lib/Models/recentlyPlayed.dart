class RecentlyPlayed {
  String title, url, image, album, artist, lyrics, id;
  RecentlyPlayed(
      {this.title,
      this.url,
      this.image,
      this.album,
      this.artist,
      this.lyrics,
      this.id});
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'url': url,
      'image': image,
      'album': album,
      'artist': artist,
      'lyrics': lyrics,
      'id': id,
    };
  }
}
