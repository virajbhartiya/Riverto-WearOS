import 'dart:convert';
import 'dart:ui';
import 'package:rivertoWearOS/Models/queueModel.dart';
import 'package:rivertoWearOS/Models/recentlyPlayed.dart';
import 'package:rivertoWearOS/screen/playlist.dart';
import 'package:rivertoWearOS/screen/queueScreen.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:des_plugin/des_plugin.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_media_notification/flutter_media_notification.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:rivertoWearOS/API/saavn.dart';
import 'package:rivertoWearOS/style/appColors.dart';
import 'package:rivertoWearOS/const.dart';
import 'package:http/http.dart' as http;

import '../music.dart';

class Riverto extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return AppState();
  }
}

class AppState extends State<Riverto> {
  TextEditingController searchBar = TextEditingController();
  TextEditingController addPlaylist = TextEditingController();
  bool fetchingSongs = false;
  List<QueueModel> songs = [];
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.black,
      statusBarColor: Colors.transparent,
    ));

    //=============================================================================
    //Notifications
    MediaNotification.setListener('play', () {
      setState(() {
        playerState = PlayerState.playing;
        status = 'play';
        audioPlayer.play(kUrl);
      });
    });

    MediaNotification.setListener('pause', () {
      setState(() {
        status = 'pause';
        audioPlayer.pause();
      });
    });

    MediaNotification.setListener("close", () {
      audioPlayer.stop();
      dispose();
      checker = "no";
      MediaNotification.hideNotification();
    });
  }
  //====================================================

  search() async {
    String searchQuery = searchBar.text;
    if (searchQuery.isEmpty) return;

    setState(() {
      fetchingSongs = true;
    });
    await fetchSongsList(searchQuery);
    setState(() {
      fetchingSongs = false;
    });
    searchedList.forEach((element) {
      QueueModel s = new QueueModel()
        ..title = element['title']
        ..album = element['more_info']['album']
        ..artist = element['more_info']["singers"]
        ..id = element["id"];

      this.songs.add(s);
    });
  }

  getSongDetails(String id, var context, int index) async {
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

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AudioApp(this.songs, index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    String lyr, url;
    Future fetchLyrics(id, art, tit) async {
      String songUrl =
          "https://www.jiosaavn.com/api.php?app_version=5.18.3&api_version=4&readable_version=5.18.3&v=79&_format=json&__call=song.getDetails&pids=" +
              id;
      var res =
          await http.get(songUrl, headers: {"Accept": "application/json"});
      var resEdited = (res.body).split("-->");
      var getMain = json.decode(resEdited[1]);

      title = (getMain[id]["title"])
          .toString()
          .split("(")[0]
          .replaceAll("&amp;", "&")
          .replaceAll("&#039;", "'")
          .replaceAll("&quot;", "\"");
      image = (getMain[id]["image"]).replaceAll("150x150", "500x500");
      album = (getMain[id]["more_info"]["album"])
          .toString()
          .replaceAll("&quot;", "\"")
          .replaceAll("&#039;", "'")
          .replaceAll("&amp;", "&");

      try {
        artist =
            getMain[id]['more_info']['artistMap']['primary_artists'][0]['name'];
      } catch (e) {
        artist = "-";
      }
      if (getMain[id]["more_info"]["has_lyrics"] == "true") {
        String lyricsUrl =
            "https://www.jiosaavn.com/api.php?__call=lyrics.getLyrics&lyrics_id=" +
                id +
                "&ctx=web6dot0&api_version=4&_format=json";
        var lyricsRes =
            await http.get(lyricsUrl, headers: {"Accept": "application/json"});
        var lyricsEdited = (lyricsRes.body).split("-->");
        var fetchedLyrics = json.decode(lyricsEdited[1]);
        lyr = fetchedLyrics["lyrics"].toString().replaceAll("<br>", "\n");
      } else {
        lyr = "null";
        String lyricsApiUrl =
            "https://sumanjay.vercel.app/lyrics/" + artist + "/" + title;
        var lyricsApiRes = await http
            .get(lyricsApiUrl, headers: {"Accept": "application/json"});
        var lyricsResponse = json.decode(lyricsApiRes.body);
        if (lyricsResponse['status'] == true &&
            lyricsResponse['lyrics'] != null) {
          lyr = lyricsResponse['lyrics'];
        }
      }

      url = await DesPlugin.decrypt(
          key, getMain[id]["more_info"]["encrypted_media_url"]);

      final client = http.Client();
      final request = http.Request('HEAD', Uri.parse(url))
        ..followRedirects = false;
      final response = await client.send(request);
      url = (response.headers['location']);
      artist = (getMain[id]["more_info"]["artistMap"]["primary_artists"][0]
              ["name"])
          .toString()
          .replaceAll("&quot;", "\"")
          .replaceAll("&#039;", "'")
          .replaceAll("&amp;", "&");
    }

    return GestureDetector(
      onPanUpdate: (details) {
        if (details.delta.dx < 0) {
          print("Swipe Right");
          Navigator.of(context).push(MaterialPageRoute(builder: (context) {
            return Playlists();
          }));
        }
      },
      child: Container(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          bottomNavigationBar: kUrl != ""
              ? Container(
                  height: 20,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(18),
                          topRight: Radius.circular(18)),
                      color: Colors.black),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 5.0, bottom: 2),
                    child: GestureDetector(
                      onTap: () {
                        checker = "no";
                        if (kUrl != "") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => AudioApp(this.songs, 0)),
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
                                  style: TextStyle(
                                      color: accentLight, fontSize: 15),
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
          body: Container(
            height: screenHeight,
            width: screenWidth,
            child: Stack(
              children: [
                // particle(context),
                SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: Column(
                    children: <Widget>[
                      SizedBox(
                        height: screenHeight * 0.1,
                      ),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.black,
                          ),
                          child: Row(
                            children: [
                              Text(
                                "Riverto.",
                                style: TextStyle(
                                  color: Color(0xff61e88a),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Spacer(),
                              kUrl != null
                                  ? Container(
                                      child: IconButton(
                                        iconSize: 20,
                                        alignment: Alignment.center,
                                        icon: Icon(MdiIcons.play),
                                        color: accent,
                                        onPressed: () => {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    AudioApp(this.songs, 0)),
                                          ),
                                        },
                                      ),
                                    )
                                  : Container(),
                              // Container(
                              //   child: IconButton(
                              //     iconSize: 20,
                              //     alignment: Alignment.center,
                              //     icon: Icon(MdiIcons.apacheKafka),
                              //     color: accent,
                              //     onPressed: () => {
                              //       Navigator.push(
                              //         context,
                              //         MaterialPageRoute(
                              //             builder: (context) => QueueScreen()),
                              //       ),
                              //     },
                              //   ),
                              // )
                            ],
                          ),
                        ),
                        // child: Row(children: <Widget>[

                        //feedback button
                        // Container(
                        //   child: IconButton(
                        //     iconSize: 26,
                        //     alignment: Alignment.center,
                        //     icon: Icon(MdiIcons.messageOutline),
                        //     color: accent,
                        //     onPressed: () => {
                        //       Navigator.push(
                        //         context,
                        //         CupertinoPageRoute(
                        //           builder: (context) => Feed(),
                        //         ),
                        //       ),
                        //     },
                        //   ),
                        // ),
                        // //recentlyPlayed button
                        // Container(
                        //   child: IconButton(
                        //     iconSize: 26,
                        //     alignment: Alignment.center,
                        //     icon: Icon(MdiIcons.playlistMusic),
                        //     color: accent,
                        //     onPressed: () {
                        //       return {
                        //         Navigator.push(
                        //           context,
                        //           CupertinoPageRoute(
                        //             builder: (context) => Playlists(),
                        //           ),
                        //         ),
                        //       };
                        //     },
                        //   ),
                        // ),
                        // //queue button
                        // Container(
                        //   child: IconButton(
                        //     iconSize: 26,
                        //     alignment: Alignment.center,
                        //     icon: Icon(MdiIcons.apacheKafka),
                        //     color: accent,
                        //     onPressed: () => {
                        //       Navigator.push(
                        //         context,
                        //         CupertinoPageRoute(
                        //           builder: (context) => QueueScreen(),
                        //         ),
                        //       ),
                        //     },
                        //   ),
                        // )
                        // ]),
                      ),
                      Container(
                        height: 30,
                        width: screenWidth * .7,
                        child: TextField(
                          onSubmitted: (String value) {
                            search();
                          },
                          controller: searchBar,
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xff61e88a),
                          ),
                          cursorColor: Colors.green[50],
                          decoration: InputDecoration(
                            fillColor: Colors.black,
                            filled: true,
                            enabledBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(100),
                              ),
                              borderSide: BorderSide(
                                color: Color(0xff61e88a),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(100),
                              ),
                              borderSide: BorderSide(color: accent),
                            ),
                            suffixIcon: IconButton(
                              icon: fetchingSongs
                                  ? SizedBox(
                                      height: 15,
                                      width: 15,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  accent),
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      Icons.search,
                                      size: 18,
                                      color: accent,
                                    ),
                              color: accent,
                              onPressed: () {
                                search();
                              },
                            ),
                            border: InputBorder.none,
                            hintStyle: TextStyle(
                              color: accent,
                            ),
                            contentPadding: const EdgeInsets.only(
                              left: 18,
                              right: 20,
                              top: 14,
                              bottom: 14,
                            ),
                          ),
                        ),
                      ),
                      searchedList.isNotEmpty
                          //searched songs
                          ? ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: searchedList.length,
                              itemBuilder: (BuildContext ctxt, int index) {
                                return Container(
                                  padding:
                                      const EdgeInsets.only(top: 5, bottom: 5),
                                  height: screenHeight * 0.3,
                                  width: screenWidth * 0.9,
                                  child: Card(
                                    color: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    elevation: 10,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(10.0),
                                      onTap: () {
                                        getSongDetails(
                                            searchedList[index]["id"],
                                            context,
                                            index);
                                      },
                                      splashColor: accent,
                                      hoverColor: accent,
                                      focusColor: accent,
                                      highlightColor: accent,
                                      child: ListTile(
                                        title: Text(
                                          (searchedList[index]['title'])
                                              .toString()
                                              .split("(")[0]
                                              .replaceAll("&quot;", "\"")
                                              .replaceAll("&amp;", "&"),
                                          style: TextStyle(
                                              color: accent, fontSize: 13),
                                        ),
                                        subtitle: Text(
                                          searchedList[index]['more_info']
                                              ["singers"],
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              color: accent,
                                              icon: Icon(
                                                  MdiIcons.playlistMusicOutline,
                                                  size: 18),
                                              onPressed: () {
                                                return showDialog(
                                                  context: context,
                                                  builder: (ctx) => AlertDialog(
                                                    titlePadding:
                                                        EdgeInsets.all(5),
                                                    backgroundColor:
                                                        Colors.black,
                                                    title: Text("Playlists.",
                                                        style: TextStyle(
                                                            color: accent,
                                                            fontSize: 14)),
                                                    content: ListView.builder(
                                                        shrinkWrap: true,
                                                        itemCount: Playlist
                                                            .playlists.length,
                                                        itemBuilder:
                                                            (BuildContext
                                                                    context,
                                                                int ind) {
                                                          return TextButton(
                                                              clipBehavior: Clip
                                                                  .antiAlias,
                                                              child: Text(
                                                                  Playlist.playlists[
                                                                      ind],
                                                                  style: TextStyle(
                                                                      color:
                                                                          accent,
                                                                      fontSize:
                                                                          10)),
                                                              onPressed:
                                                                  () async {
                                                                QueueModel s =
                                                                    new QueueModel()
                                                                      ..title = searchedList[index]['title']
                                                                          .toString()
                                                                          .split("(")[
                                                                              0]
                                                                          .replaceAll(
                                                                              "&quot;", "\"")
                                                                          .replaceAll(
                                                                              "&amp;", "&")
                                                                      ..album = searchedList[index]
                                                                              ['more_info'][
                                                                          "album"]
                                                                      ..artist =
                                                                          searchedList[index]['more_info']
                                                                              [
                                                                              "singers"]
                                                                      ..id = searchedList[index]
                                                                          ['id']
                                                                      ..lyrics =
                                                                          lyr
                                                                      ..url =
                                                                          url;
                                                                Playlist.insertSong(
                                                                    s,
                                                                    Playlist.playlists[
                                                                        ind]);

                                                                Navigator.of(
                                                                        context)
                                                                    .pop();
                                                              });
                                                        }),
                                                    actions: <Widget>[
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.of(ctx)
                                                              .pop();
                                                          showDialog(
                                                            barrierDismissible:
                                                                false,
                                                            context: context,
                                                            builder: (ct) =>
                                                                AlertDialog(
                                                              title: Text(
                                                                  "Create Playlist.",
                                                                  style: TextStyle(
                                                                      color:
                                                                          accent)),
                                                              backgroundColor:
                                                                  Colors.black,
                                                              content:
                                                                  Container(
                                                                child:
                                                                    TextField(
                                                                  onSubmitted:
                                                                      (String
                                                                          value) async {
                                                                    Playlist
                                                                        .playlists
                                                                        .add(addPlaylist
                                                                            .text);

                                                                    Playlist
                                                                        .sharedPrefs();
                                                                    await fetchLyrics(
                                                                        searchedList[index]
                                                                            [
                                                                            'id'],
                                                                        searchedList[index]['more_info']
                                                                            [
                                                                            "singers"],
                                                                        searchedList[index]['title']
                                                                            .toString()
                                                                            .split("(")[
                                                                                0]
                                                                            .replaceAll("&quot;",
                                                                                "\"")
                                                                            .replaceAll("&amp;",
                                                                                "&"));

                                                                    QueueModel s =
                                                                        new QueueModel()
                                                                          ..title = searchedList[index]['title'].toString().split("(")[0].replaceAll("&quot;", "\"").replaceAll(
                                                                              "&amp;",
                                                                              "&")
                                                                          ..album = searchedList[index]['more_info'][
                                                                              "album"]
                                                                          ..artist = searchedList[index]['more_info']
                                                                              [
                                                                              "singers"]
                                                                          ..id = searchedList[index]
                                                                              [
                                                                              'id']
                                                                          ..lyrics =
                                                                              lyr
                                                                          ..url =
                                                                              url;
                                                                    Playlist.insertSong(
                                                                        s,
                                                                        addPlaylist
                                                                            .text);
                                                                    addPlaylist
                                                                        .text = '';
                                                                    Navigator.of(
                                                                            ct)
                                                                        .pop();
                                                                  },
                                                                  controller:
                                                                      addPlaylist,
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        16,
                                                                    color: Color(
                                                                        0xff61e88a),
                                                                  ),
                                                                  cursorColor:
                                                                      Colors.green[
                                                                          50],
                                                                  decoration:
                                                                      InputDecoration(
                                                                    fillColor:
                                                                        Colors
                                                                            .black,
                                                                    filled:
                                                                        true,
                                                                    enabledBorder:
                                                                        const OutlineInputBorder(
                                                                      borderRadius:
                                                                          BorderRadius
                                                                              .all(
                                                                        Radius.circular(
                                                                            100),
                                                                      ),
                                                                      borderSide:
                                                                          BorderSide(
                                                                        color: Color(
                                                                            0xff61e88a),
                                                                      ),
                                                                    ),
                                                                    focusedBorder:
                                                                        OutlineInputBorder(
                                                                      borderRadius:
                                                                          BorderRadius
                                                                              .all(
                                                                        Radius.circular(
                                                                            100),
                                                                      ),
                                                                      borderSide:
                                                                          BorderSide(
                                                                              color: accent),
                                                                    ),
                                                                    suffixIcon:
                                                                        IconButton(
                                                                      icon:
                                                                          Icon(
                                                                        Icons
                                                                            .add,
                                                                        color:
                                                                            accent,
                                                                      ),
                                                                      color:
                                                                          accent,
                                                                      onPressed:
                                                                          () async {
                                                                        Playlist
                                                                            .playlists
                                                                            .add(addPlaylist.text);

                                                                        Playlist
                                                                            .sharedPrefs();
                                                                        await fetchLyrics(
                                                                            searchedList[index][
                                                                                'id'],
                                                                            searchedList[index]['more_info'][
                                                                                "singers"],
                                                                            searchedList[index]['title'].toString().split("(")[0].replaceAll("&quot;", "\"").replaceAll("&amp;",
                                                                                "&"));

                                                                        QueueModel s = new QueueModel()
                                                                          ..title = searchedList[index]['title'].toString().split("(")[0].replaceAll("&quot;", "\"").replaceAll("&amp;", "&")
                                                                          ..album = searchedList[index]['more_info']["album"]
                                                                          ..artist = searchedList[index]['more_info']["singers"]
                                                                          ..id = searchedList[index]['id']
                                                                          ..lyrics = lyr
                                                                          ..url = url;
                                                                        Playlist.insertSong(
                                                                            s,
                                                                            addPlaylist.text);
                                                                        addPlaylist.text =
                                                                            '';
                                                                        Navigator.of(ct)
                                                                            .pop();
                                                                      },
                                                                    ),
                                                                    border:
                                                                        InputBorder
                                                                            .none,
                                                                    hintText:
                                                                        "Name",
                                                                    hintStyle:
                                                                        TextStyle(
                                                                      color:
                                                                          accent,
                                                                    ),
                                                                    contentPadding:
                                                                        const EdgeInsets
                                                                            .only(
                                                                      left: 18,
                                                                      right: 20,
                                                                      top: 14,
                                                                      bottom:
                                                                          14,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                        child: Text(
                                                            "+ Playlist",
                                                            style: TextStyle(
                                                                fontSize: 10,
                                                                color: accent)),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                            // IconButton(
                                            //   color: accent,
                                            //   icon: Icon(MdiIcons.apacheKafka),
                                            //   onPressed: () async {
                                            //     await fetchLyrics(
                                            //             searchedList[index]["id"],
                                            //             searchedList[index]
                                            //                     ['more_info']
                                            //                 ["singers"],
                                            //             searchedList[index]
                                            //                 ['title'])
                                            //         .then((_) => {});
                                            //     QueueModel queueItem =
                                            //         new QueueModel()
                                            //           ..title =
                                            //               searchedList[index]
                                            //                   ['title']
                                            //           ..album =
                                            //               searchedList[index]
                                            //                       ['more_info']
                                            //                   ['album']
                                            //           ..artist =
                                            //               searchedList[index]
                                            //                       ['more_info']
                                            //                   ["singers"]
                                            //           ..id = searchedList[index]
                                            //               ["id"]
                                            //           ..lyrics = lyr
                                            //           ..url = url;

                                            //     Const.queueSongs.add(queueItem);
                                            //   },
                                            // ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )
                          : Const.recentSongs.length > 0
                              ? Container(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            top: 30.0, bottom: 0, left: 8),
                                        child: Text(
                                          "Recently Played.",
                                          textAlign: TextAlign.left,
                                          style: TextStyle(
                                            fontSize: 22,
                                            color: accent,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        child: SingleChildScrollView(
                                          child: Container(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height -
                                                250,
                                            child: SafeArea(
                                              child: ListView.builder(
                                                shrinkWrap: true,
                                                physics:
                                                    NeverScrollableScrollPhysics(),
                                                itemCount:
                                                    Const.recentSongs.length,
                                                itemBuilder: (BuildContext ctxt,
                                                    int index) {
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 0, bottom: 5),
                                                    child: Card(
                                                      color: Colors.black,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10.0),
                                                      ),
                                                      elevation: 10,
                                                      child: InkWell(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10.0),
                                                        onTap: () {
                                                          getSongDetails(
                                                              Const
                                                                  .recentSongs[
                                                                      index]
                                                                  .id,
                                                              context,
                                                              index);
                                                        },
                                                        splashColor: accent,
                                                        hoverColor: accent,
                                                        focusColor: accent,
                                                        highlightColor: accent,
                                                        child: ListTile(
                                                          leading: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(.0),
                                                            child: Icon(
                                                              MdiIcons
                                                                  .musicNoteOutline,
                                                              size: 30,
                                                              color: accent,
                                                            ),
                                                          ),
                                                          title: Text(
                                                            (Const
                                                                    .recentSongs[
                                                                        index]
                                                                    .title)
                                                                .toString()
                                                                .split("(")[0]
                                                                .replaceAll(
                                                                    "&quot;",
                                                                    "\"")
                                                                .replaceAll(
                                                                    "&amp;",
                                                                    "&"),
                                                            style: TextStyle(
                                                                color: accent),
                                                          ),
                                                          subtitle: Text(
                                                            Const
                                                                .recentSongs[
                                                                    index]
                                                                .artist,
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white),
                                                          ),
                                                          trailing: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              IconButton(
                                                                color: accent,
                                                                icon: Icon(MdiIcons
                                                                    .playlistMusicOutline),
                                                                onPressed: () {
                                                                  return showDialog(
                                                                    context:
                                                                        context,
                                                                    builder:
                                                                        (ctx) =>
                                                                            AlertDialog(
                                                                      backgroundColor:
                                                                          Colors
                                                                              .black,
                                                                      title: Text(
                                                                          "Playlists.",
                                                                          style:
                                                                              TextStyle(color: accent)),
                                                                      content: ListView.builder(
                                                                          shrinkWrap: true,
                                                                          itemCount: Playlist.playlists.length,
                                                                          itemBuilder: (BuildContext context, int ind) {
                                                                            return TextButton(
                                                                                clipBehavior: Clip.antiAlias,
                                                                                child: Text(Playlist.playlists[ind], style: TextStyle(color: accent, fontSize: 25)),
                                                                                onPressed: () async {
                                                                                  fetchLyrics(Const.recentSongs[index].id, Const.recentSongs[index].artist, Const.recentSongs[index].title);
                                                                                  QueueModel s = new QueueModel()
                                                                                    ..title = Const.recentSongs[index].title
                                                                                    ..album = Const.recentSongs[index].album
                                                                                    ..artist = Const.recentSongs[index].artist
                                                                                    ..id = Const.recentSongs[index].id
                                                                                    ..lyrics = lyr
                                                                                    ..url = url;
                                                                                  Playlist.insertSong(s, Playlist.playlists[ind]);

                                                                                  Navigator.of(context).pop();
                                                                                });
                                                                          }),
                                                                      actions: <
                                                                          Widget>[
                                                                        FlatButton(
                                                                          color:
                                                                              accent,
                                                                          onPressed:
                                                                              () {
                                                                            Navigator.of(ctx).pop();
                                                                            showDialog(
                                                                              barrierDismissible: false,
                                                                              context: context,
                                                                              builder: (context) => AlertDialog(
                                                                                title: Text("Create Playlist.", style: TextStyle(color: accent)),
                                                                                backgroundColor: Colors.black,
                                                                                content: TextField(
                                                                                  onSubmitted: (String value) async {
                                                                                    Playlist.playlists.add(addPlaylist.text);

                                                                                    Playlist.sharedPrefs();
                                                                                    await fetchLyrics(Const.recentSongs[index].id, Const.recentSongs[index].artist, Const.recentSongs[index].title);

                                                                                    QueueModel s = new QueueModel()
                                                                                      ..title = Const.recentSongs[index].title
                                                                                      ..album = Const.recentSongs[index].album
                                                                                      ..artist = Const.recentSongs[index].artist
                                                                                      ..id = Const.recentSongs[index].id
                                                                                      ..lyrics = lyr
                                                                                      ..url = url;
                                                                                    Playlist.insertSong(s, addPlaylist.text);
                                                                                    addPlaylist.text = '';
                                                                                    Navigator.of(context).pop();
                                                                                  },
                                                                                  controller: addPlaylist,
                                                                                  style: TextStyle(
                                                                                    fontSize: 16,
                                                                                    color: Color(0xff61e88a),
                                                                                  ),
                                                                                  cursorColor: Colors.green[50],
                                                                                  decoration: InputDecoration(
                                                                                    fillColor: Colors.black,
                                                                                    filled: true,
                                                                                    enabledBorder: const OutlineInputBorder(
                                                                                      borderRadius: BorderRadius.all(
                                                                                        Radius.circular(100),
                                                                                      ),
                                                                                      borderSide: BorderSide(
                                                                                        color: Color(0xff61e88a),
                                                                                      ),
                                                                                    ),
                                                                                    focusedBorder: OutlineInputBorder(
                                                                                      borderRadius: BorderRadius.all(
                                                                                        Radius.circular(100),
                                                                                      ),
                                                                                      borderSide: BorderSide(color: accent),
                                                                                    ),
                                                                                    suffixIcon: IconButton(
                                                                                      icon: Icon(
                                                                                        Icons.add,
                                                                                        color: accent,
                                                                                      ),
                                                                                      color: accent,
                                                                                      onPressed: () async {
                                                                                        Playlist.playlists.add(addPlaylist.text);

                                                                                        Playlist.sharedPrefs();
                                                                                        await fetchLyrics(Const.recentSongs[index].id, Const.recentSongs[index].artist, Const.recentSongs[index].title);
                                                                                        QueueModel s = new QueueModel()
                                                                                          ..title = Const.recentSongs[index].title
                                                                                          ..album = Const.recentSongs[index].album
                                                                                          ..artist = Const.recentSongs[index].artist
                                                                                          ..id = Const.recentSongs[index].id
                                                                                          ..lyrics = lyr
                                                                                          ..url = url;
                                                                                        Playlist.insertSong(s, addPlaylist.text);
                                                                                        addPlaylist.text = '';
                                                                                        Navigator.of(context).pop();
                                                                                      },
                                                                                    ),
                                                                                    border: InputBorder.none,
                                                                                    hintText: "Name",
                                                                                    hintStyle: TextStyle(
                                                                                      color: accent,
                                                                                    ),
                                                                                    contentPadding: const EdgeInsets.only(
                                                                                      left: 18,
                                                                                      right: 20,
                                                                                      top: 14,
                                                                                      bottom: 14,
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            );
                                                                          },
                                                                          child: Text(
                                                                              "+ Playlist",
                                                                              style: TextStyle(fontSize: 15, color: Colors.black)),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  );
                                                                },
                                                              ),
                                                              IconButton(
                                                                color: accent,
                                                                icon: Icon(MdiIcons
                                                                    .apacheKafka),
                                                                onPressed:
                                                                    () async {
                                                                  await fetchLyrics(
                                                                      Const
                                                                          .recentSongs[
                                                                              index]
                                                                          .id,
                                                                      Const
                                                                          .recentSongs[
                                                                              index]
                                                                          .artist,
                                                                      Const
                                                                          .recentSongs[
                                                                              index]
                                                                          .title);

                                                                  QueueModel
                                                                      queueItem =
                                                                      new QueueModel()
                                                                        ..title = Const
                                                                            .recentSongs[
                                                                                index]
                                                                            .title
                                                                        ..album = Const
                                                                            .recentSongs[
                                                                                index]
                                                                            .album
                                                                        ..artist = Const
                                                                            .recentSongs[
                                                                                index]
                                                                            .artist
                                                                        ..id = Const
                                                                            .recentSongs[
                                                                                index]
                                                                            .id
                                                                        ..lyrics = Const
                                                                            .recentSongs[
                                                                                index]
                                                                            .id
                                                                        ..url = Const
                                                                            .recentSongs[index]
                                                                            .url;

                                                                  Const
                                                                      .queueSongs
                                                                      .add(
                                                                          queueItem);
                                                                },
                                                              ),
                                                              IconButton(
                                                                color: accent,
                                                                icon: Icon(MdiIcons
                                                                    .downloadOutline),
                                                                onPressed:
                                                                    () async {
                                                                  Const.toast(
                                                                      "Starting Download!");
                                                                  Const.downloadSong(
                                                                      searchedList[
                                                                              index]
                                                                          [
                                                                          "id"],
                                                                      context);
                                                                },
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Container(
                                  padding: EdgeInsets.all(20),
                                  child: Center(
                                      child: Text("",
                                          style: TextStyle(
                                              color: accent, fontSize: 20))),
                                )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  //Home screen songs
  Widget getTopSong(
      String image, String title, String subtitle, String id, int index) {
    return InkWell(
      onTap: () {
        getSongDetails(id, context, index);
      },
      child: Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.3,
            width: MediaQuery.of(context).size.width / 2,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  image: DecorationImage(
                    fit: BoxFit.fill,
                    image: CachedNetworkImageProvider(image),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 2,
          ),
          Text(
            title
                .split("(")[0]
                .replaceAll("&amp;", "&")
                .replaceAll("&#039;", "'")
                .replaceAll("&quot;", "\""),
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(
            height: 2,
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white38,
              fontSize: 12.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
