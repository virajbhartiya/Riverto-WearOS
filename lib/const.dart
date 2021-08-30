import 'package:rivertoWearOS/Models/queueModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'API/saavn.dart';
import 'Models/recentlyPlayed.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:ext_storage/ext_storage.dart';
import 'package:audiotagger/audiotagger.dart';
import 'package:audiotagger/models/tag.dart';
import 'dart:io';

import 'style/appColors.dart';

class Const {
  static void setValues(String key, String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
    await prefs.setBool("logIn", true);
  }

  static void logIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool("logIn", true);
  }

  static downloadSong(id, context) async {
    String filepath;
    String filepath2;
    var status = await Permission.storage.status;
    if (status.isUndetermined || status.isDenied) {
      //Getting permissions
      await [
        Permission.storage,
      ].request();
    }
    status = await Permission.storage.status;
    await fetchSongDetails(id);
    if (status.isGranted) {
      ProgressDialog pr = ProgressDialog(context);
      pr = ProgressDialog(
        context,
        type: ProgressDialogType.Normal,
        isDismissible: false,
        showLogs: false,
      );

      pr.style(
        // backgroundColor: Color(0xff263238),
        backgroundColor: accent,
        elevation: 4,
        textAlign: TextAlign.left,
        progressTextStyle: TextStyle(color: Colors.white),
        message: "Downloading " + title,
        // messageTextStyle: TextStyle(color: accent),
        messageTextStyle: TextStyle(color: Colors.black),
        progressWidget: Padding(
          padding: const EdgeInsets.all(20.0),
          child: CircularProgressIndicator(
            // valueColor: AlwaysStoppedAnimation<Color>(accent),
            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
          ),
        ),
      );
      await pr.show();

      final filename = title + ".m4a";
      final artname = title + "_artwork.jpg";

      //Path for saving the song
      String dlPath = await ExtStorage.getExternalStoragePublicDirectory(
          ExtStorage.DIRECTORY_MUSIC);
      await File(dlPath + "/" + filename)
          .create(recursive: true)
          .then((value) => filepath = value.path);
      await File(dlPath + "/" + artname)
          .create(recursive: true)
          .then((value) => filepath2 = value.path);

      if (has_320 == "true") {
        kUrl = rawkUrl.replaceAll("_96.mp4", "_320.mp4");
        final client = http.Client();
        final request = http.Request('HEAD', Uri.parse(kUrl))
          ..followRedirects = false;
        final response = await client.send(request);
        kUrl = (response.headers['location']);
        final request2 = http.Request('HEAD', Uri.parse(kUrl))
          ..followRedirects = false;
        final response2 = await client.send(request2);
        if (response2.statusCode != 200) {
          kUrl = kUrl.replaceAll(".mp4", ".mp3");
        }
      }
      var request = await HttpClient().getUrl(Uri.parse(kUrl));
      var response = await request.close();
      var bytes = await consolidateHttpClientResponseBytes(response);
      File file = File(filepath);

      var request2 = await HttpClient().getUrl(Uri.parse(image));
      var response2 = await request2.close();
      var bytes2 = await consolidateHttpClientResponseBytes(response2);
      File file2 = File(filepath2);

      await file.writeAsBytes(bytes);
      await file2.writeAsBytes(bytes2);

      final tag = Tag(
        title: title,
        artist: artist,
        artwork: filepath2,
        album: album,
        lyrics: lyrics,
        genre: null,
      );

      final tagger = Audiotagger();
      await tagger.writeTags(
        path: filepath,
        tag: tag,
      );
      await Future.delayed(const Duration(seconds: 1), () {});
      await pr.hide();

      if (await file2.exists()) await file2.delete();

      toast("Download Complete!");
    } else if (status.isDenied || status.isPermanentlyDenied)
      toast("Storage Permission Denied!\nCan't Download Songs");
    else
      toast("Permission Error!");
  }

  static toast(String msg) {
    Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Color(0xff61e88a),
      textColor: Colors.black,
      fontSize: 14.0,
    );
  }

  static Future<Database> database;
  static Future dbSetup() async {
    WidgetsFlutterBinding.ensureInitialized();

    database = openDatabase(
      join(await getDatabasesPath(), 'recentlyPlayed.db'),
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE recent(title TEXT PRIMARY KEY, url TEXT,image TEXT,album TEXT,artist TEXT,lyrics TEXT,id TEXT)",
        );
      },
      version: 1,
    );
  }

  static Future<void> insertRecent(RecentlyPlayed recent) async {
    final Database db = await database;
    await db.insert(
      'recent',
      recent.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<RecentlyPlayed>> recentlyPlayedList() async {
    final Database db = await database;

    final List<Map<String, dynamic>> maps = await db.query('recent');

    return List.generate(maps.length, (i) {
      return RecentlyPlayed(
          title: maps[i]['title'],
          url: maps[i]['url'],
          image: maps[i]['image'],
          album: maps[i]['album'],
          artist: maps[i]['artist'],
          lyrics: maps[i]['lyrics'],
          id: maps[i]['id']);
    });
  }

  static Future<void> deleteDbElement(String title) async {
    final db = await database;

    await db.delete(
      'recent',
      where: "title = ?",
      whereArgs: [title],
    );
  }

  static Future<List<RecentlyPlayed>> getSongs() async {
    return await Const.recentlyPlayedList();
  }

  static Future change() async {
    recentSongs = await getSongs();
  }

  static List<RecentlyPlayed> recentSongs = [];
  static List<QueueModel> queueSongs = [];
}

class Playlist {
  static List<String> playlists = [];

  static Future sharedPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('playlists', playlists);
  }

  static Future getVals() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    playlists = prefs.getStringList('playlists') ?? [];
  }

  static Future<Database> database;
  static Future dbSetup(name) async {
    WidgetsFlutterBinding.ensureInitialized();

    database = openDatabase(
      join(await getDatabasesPath(), name + ".db"),
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE " +
              name +
              " (title TEXT PRIMARY KEY, url TEXT,album TEXT,artist TEXT,lyrics TEXT,id TEXT)",
        );
      },
      version: 1,
    );
  }

  static Future<void> insertSong(QueueModel recent, name) async {
    await dbSetup(name);
    final Database db = await database;

    await db.insert(
      name,
      recent.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future playlistList(name) async {
    await dbSetup(name);
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(name);
    playlistSongs = List.generate(maps.length, (i) {
      return QueueModel(
          title: maps[i]['title'],
          url: maps[i]['url'],
          album: maps[i]['album'],
          artist: maps[i]['artist'],
          lyrics: maps[i]['lyrics'],
          id: maps[i]['id']);
    });
    // return playlistSongs;
  }

  static Future<void> deleteDbElement(String id, name) async {
    await dbSetup(name);
    final db = await database;

    await db.delete(
      name,
      where: "id = ?",
      whereArgs: [id],
    );
    await playlistList(name);
  }

  static List<QueueModel> playlistSongs;
}
