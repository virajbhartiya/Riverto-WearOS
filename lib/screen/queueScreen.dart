import 'package:rivertoWearOS/API/saavn.dart';
import 'package:rivertoWearOS/Models/queueModel.dart';
import 'package:rivertoWearOS/Models/recentlyPlayed.dart';
import 'package:rivertoWearOS/style/appColors.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_media_notification/flutter_media_notification.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../const.dart';
import '../music.dart';

class QueueScreen extends StatefulWidget {
  @override
  _QueueScreenState createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  List<QueueModel> songs;
  int index;
  @override
  void initState() {
    super.initState();
    setSongs();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.black,
      statusBarColor: Colors.transparent,
    ));
  }

  void setSongs() {
    setState(() {
      songs = Const.queueSongs;
    });
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

      // recentSongs.add(recentlyPlayed);
      await Const.insertRecent(recentlyPlayed);
      Const.change();
    } catch (e) {
      artist = "Unknown";
    }
    setState(() {
      checker = "yes";
    });
    kUrl = songs[index].url;
    // image = songs[index].image;
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
    return Container(
      child: Scaffold(
        backgroundColor: Colors.black,
        bottomNavigationBar: kUrl != ""
            ? Container(
                height: 75,
                //color: Color(0xff1c252a),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18)),
                  color: Colors.black,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 5.0, bottom: 2),
                  child: GestureDetector(
                    onTap: () {
                      checker = "no";
                      if (kUrl != "") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => AudioApp(songs, index)),
                        );
                      }
                    },
                    child: Row(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 8.0,
                          ),
                          child: IconButton(
                            icon: Icon(
                              MdiIcons.appleKeyboardControl,
                              size: 22,
                            ),
                            onPressed: null,
                            disabledColor: accent,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 0.0, top: 7, bottom: 7, right: 15),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: CachedNetworkImage(
                              imageUrl: image,
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 0.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                title,
                                style: TextStyle(
                                    color: accent,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600),
                              ),
                              Text(
                                artist,
                                style:
                                    TextStyle(color: accentLight, fontSize: 15),
                              )
                            ],
                          ),
                        ),
                        Spacer(),
                        IconButton(
                          icon: playerState == PlayerState.playing
                              ? Icon(MdiIcons.pause)
                              : Icon(MdiIcons.playOutline),
                          color: accent,
                          splashColor: Colors.transparent,
                          onPressed: () {
                            setState(() {
                              if (playerState == PlayerState.playing) {
                                audioPlayer.pause();
                                playerState = PlayerState.paused;
                                MediaNotification.showNotification(
                                    title: title,
                                    author: artist,
                                    artUri: image,
                                    isPlaying: false);
                              } else if (playerState == PlayerState.paused) {
                                audioPlayer.play(kUrl);
                                playerState = PlayerState.playing;
                                MediaNotification.showNotification(
                                    title: title,
                                    author: artist,
                                    artUri: image,
                                    isPlaying: true);
                              }
                            });
                          },
                          iconSize: 45,
                        )
                      ],
                    ),
                  ),
                ),
              )
            : SizedBox.shrink(),
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
                            "Queue.",
                            style: TextStyle(
                              color: Color(0xff61e88a),
                              fontSize: 45,
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
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: songs.length,
                          itemBuilder: (BuildContext ctxt, int index) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 5, bottom: 5),
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
                                        leading: Padding(
                                          padding: const EdgeInsets.all(.0),
                                          child: Icon(
                                            MdiIcons.musicNoteOutline,
                                            size: 30,
                                            color: accent,
                                          ),
                                          // Icon(
                                          //   MdiIcons.musicNoteOutline,
                                          //   size: 30,
                                          //   color: accent,
                                          // ),
                                        ),
                                        title: Text(
                                          (songs[index].title)
                                              .toString()
                                              .split("(")[0]
                                              .replaceAll("&quot;", "\"")
                                              .replaceAll("&amp;", "&"),
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        subtitle: Text(
                                          songs[index].artist,
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              color: accent,
                                              icon: Icon(
                                                  MdiIcons.downloadOutline),
                                              onPressed: () async {
                                                Const.toast(
                                                    "Starting Download!");
                                                Const.downloadSong(
                                                    songs[index].id, context);
                                              },
                                            ),
                                            IconButton(
                                              color: Colors.red[600],
                                              icon: Icon(MdiIcons.delete),
                                              onPressed: () async {
                                                Const.queueSongs
                                                    .remove(songs[index]);
                                                setSongs();
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
    );
  }
}
