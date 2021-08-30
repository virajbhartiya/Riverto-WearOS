import 'package:rivertoWearOS/API/saavn.dart';
import 'package:rivertoWearOS/Models/queueModel.dart';
import 'package:rivertoWearOS/const.dart';
import 'package:rivertoWearOS/screen/playlistScreen.dart';
import 'package:rivertoWearOS/style/appColors.dart';

import 'package:flutter/cupertino.dart';
import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
// import '../music.dart';
import '../music.dart';

class Playlists extends StatefulWidget {
  @override
  _PlaylistsState createState() => _PlaylistsState();
}

class _PlaylistsState extends State<Playlists> {
  List<String> playlistNames = [];
  List<QueueModel> songs = [];
  int i;

  void setnames() {
    setState(() {
      playlistNames = Playlist.playlists;
    });
  }

  @override
  void initState() {
    super.initState();
    Playlist.playlistSongs = [];
    setnames();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.black,
      statusBarColor: Colors.transparent,
    ));

    Const.change();
    // Const.recentSongs = Const.recentSongs.reversed;
    Const.recentSongs.forEach((element) {
      QueueModel s = QueueModel()
        ..album = element.album
        ..artist = element.artist
        ..id = element.id
        ..lyrics = element.lyrics
        ..title = element.title
        ..url = element.url;
      songs.add(s);
    });
  }

  getSongDetails(String id, var context, int index) async {
    try {
      await fetchSongDetails(id);
      // recentSongs.add(recentlyPlayed);
      Const.change();
    } catch (e) {
      artist = "Unknown";
    }
    setState(() {
      checker = "yes";
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AudioApp(this.songs, index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    Padding(padding: EdgeInsets.only(top: 30, bottom: 20.0)),
                    Center(
                      child: Row(children: <Widget>[
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10.0),
                            child: Text(
                              "Playlists.",
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
                    Playlist.playlists != null
                        //searched songs
                        ? ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: Playlist.playlists.length,
                            itemBuilder: (BuildContext ctxt, int index) {
                              return Container(
                                height:
                                    MediaQuery.of(context).size.height * 0.3,
                                child: Card(
                                  margin: EdgeInsets.all(10),
                                  color: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    side: new BorderSide(
                                        color: accent, width: 1.0),
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  elevation: 0,
                                  child: InkWell(
                                    onTap: () async {
                                      // try {
                                      await Playlist.playlistList(
                                          playlistNames[index]);

                                      return Navigator.of(context).push(
                                          CupertinoPageRoute(
                                              builder: (context) =>
                                                  PlaylistScreen(Playlist
                                                      .playlists[index])));
                                      // } catch (e) {
                                      // Const.toast("Playlist empty");
                                      // }
                                    },
                                    borderRadius: BorderRadius.circular(10.0),
                                    splashColor: accent,
                                    hoverColor: accent,
                                    focusColor: accent,
                                    highlightColor: accent,
                                    child: Column(
                                      children: <Widget>[
                                        ListTile(
                                          title: Text(
                                            (playlistNames[index])
                                                .toString()
                                                .split("(")[0]
                                                .replaceAll("&quot;", "\"")
                                                .replaceAll("&amp;", "&"),
                                            style: TextStyle(
                                                color: accent, fontSize: 15),
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                color: Colors.red[600],
                                                icon: Icon(MdiIcons.delete,
                                                    size: 15),
                                                onPressed: () async {
                                                  await Playlist.playlistList(
                                                      playlistNames[index]);

                                                  Playlist.playlists.remove(
                                                      playlistNames[index]);
                                                  setnames();
                                                  Playlist.sharedPrefs();
                                                  Const.toast(
                                                      "Playlist deleated");
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
