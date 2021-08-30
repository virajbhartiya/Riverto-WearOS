import 'package:rivertoWearOS/API/saavn.dart';
import 'package:rivertoWearOS/Models/queueModel.dart';
import 'package:rivertoWearOS/Models/recentlyPlayed.dart';
import 'package:rivertoWearOS/style/appColors.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../const.dart';
import '../music.dart';

class PlaylistScreen extends StatefulWidget {
  final String song;
  PlaylistScreen(this.song);
  @override
  _PlaylistScreenState createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  List<QueueModel> songs;
  int index;
  void setSongs() {
    setState(() {
      songs = Playlist.playlistSongs;
    });
  }

  @override
  void initState() {
    super.initState();
    setSongs();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.black,
      statusBarColor: Colors.transparent,
    ));
  }

  getSongDetails(String id, int index) async {
    try {
      await fetchSongDetails(id);
      RecentlyPlayed recentlyPlayed = new RecentlyPlayed()
        ..title = title
        ..url = kUrl
        ..album = album
        ..artist = artist
        ..lyrics = lyrics
        ..image = image
        ..id = id;

      await Const.insertRecent(recentlyPlayed);
      Const.change();
    } catch (e) {
      artist = "Unknown";
    }
    setState(() {
      checker = "yes";
    });
    title = songs[index].title;
    album = songs[index].album;
    artist = songs[index].artist;
    lyrics = songs[index].lyrics;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AudioApp(songs, index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    return GestureDetector(
      onPanUpdate: (details) {
        // Swiping in right direction.
        if (details.delta.dx < 0) {
          Navigator.pop(context);
        }
      },
      child: Container(
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.all(12.0),
                child: Column(
                  children: <Widget>[
                    Padding(padding: EdgeInsets.only(top: 20, bottom: 20.0)),
                    Center(
                      child: Row(children: <Widget>[
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10.0),
                            child: Text(
                              widget.song + ".",
                              style: TextStyle(
                                color: Color(0xff61e88a),
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),

                        //recentlyPlayed button
                      ]),
                    ),
                    Padding(padding: EdgeInsets.only(top: 20)),
                    //Search bar
                    songs != null
                        //searched songs
                        ? ListView.builder(
                            reverse: true,
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: songs.length,
                            itemBuilder: (BuildContext ctxt, int index) {
                              return Container(
                                height: screenHeight * 0.3,
                                width: screenWidth * 0.9,
                                padding:
                                    const EdgeInsets.only(top: 5, bottom: 5),
                                child: Card(
                                  color: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  elevation: 0,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(10.0),
                                    onTap: () =>
                                        getSongDetails(songs[index].id, index),
                                    onLongPress: () => topSongs(),
                                    splashColor: accent,
                                    hoverColor: accent,
                                    focusColor: accent,
                                    highlightColor: accent,
                                    child: Column(
                                      children: <Widget>[
                                        ListTile(
                                          title: Text(
                                            (songs[index].title)
                                                .toString()
                                                .split("(")[0]
                                                .replaceAll("&quot;", "\"")
                                                .replaceAll("&amp;", "&"),
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 13),
                                          ),
                                          subtitle: Text(
                                            songs[index].artist,
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                color: Colors.red[600],
                                                icon: Icon(MdiIcons.delete),
                                                onPressed: () async {
                                                  songs.remove(
                                                      songs[index].title);
                                                  await Playlist
                                                      .deleteDbElement(
                                                          Playlist
                                                              .playlistSongs[
                                                                  index]
                                                              .id,
                                                          widget.song);
                                                  Const.toast(
                                                      songs[index].title +
                                                          " removed");
                                                  setSongs();
                                                  if (songs.length == 0) {
                                                    Navigator.of(context).pop();
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          )

                        //No search
                        : Container()
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
