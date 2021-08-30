import 'dart:async';
import 'package:audioplayer/audioplayer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_media_notification/flutter_media_notification.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:rivertoWearOS/style/appColors.dart';
import 'API/saavn.dart';
import 'Models/queueModel.dart';

String status = 'hidden';
AudioPlayer audioPlayer;
PlayerState playerState;

typedef void OnError(Exception exception);

enum PlayerState { stopped, playing, paused }

class AudioApp extends StatefulWidget {
  final List<QueueModel> songs;
  final int index;
  AudioApp(this.songs, this.index);
  @override
  _AudioAppState createState() => _AudioAppState();
}

@override
class _AudioAppState extends State<AudioApp> {
  Duration duration;
  Duration position;

  get isPlaying => playerState == PlayerState.playing;

  get isPaused => playerState == PlayerState.paused;

  get durationText =>
      duration != null ? duration.toString().split('.').first : '';

  get positionText =>
      position != null ? position.toString().split('.').first : '';

  bool isMuted = false;

  StreamSubscription _positionSubscription;
  StreamSubscription _audioPlayerStateSubscription;
  int index;
  @override
  void initState() {
    super.initState();
    index = widget.index;
    setState(() {});
    initAudioPlayer();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void initAudioPlayer() {
    if (audioPlayer == null) {
      audioPlayer = AudioPlayer();
    }
    setState(() {
      if (checker == "yes") {
        stop();
        play();
      }
      if (checker == "no") {
        if (playerState == PlayerState.playing) {
          play();
        } else {
          play();
          pause();
        }
      }
    });

    _positionSubscription = audioPlayer.onAudioPositionChanged
        .listen((p) => {if (mounted) setState(() => position = p)});

    _audioPlayerStateSubscription =
        audioPlayer.onPlayerStateChanged.listen((s) {
      if (s == AudioPlayerState.PLAYING) {
        {
          if (mounted) setState(() => duration = audioPlayer.duration);
        }
      } else if (s == AudioPlayerState.STOPPED) {
        onComplete();
        if (mounted)
          setState(() {
            position = duration;
          });
      }
    }, onError: (msg) {
      if (mounted)
        setState(() {
          playerState = PlayerState.stopped;
          duration = Duration(seconds: 0);
          position = Duration(seconds: 0);
        });
    });
  }

  getSongDetails(String id) async {
    setState(() {
      checker = "no";
    });
    try {
      await fetchSongDetails(id);
      play();
      setState(() {
        playerState = PlayerState.playing;
        checker = "yes";
      });
    } catch (e) {}
    setState(() {
      checker = "yes";
    });
    initAudioPlayer();
    setState(() {
      playerState = PlayerState.playing;
    });
    audioPlayer.play(widget.songs[index].url);
    play();
  }

  Future play() async {
    await audioPlayer.play(kUrl);
    MediaNotification.showNotification(
        title: title, author: artist, artUri: image, isPlaying: true);
    if (mounted)
      setState(() {
        playerState = PlayerState.playing;
      });
  }

  Future pause() async {
    await audioPlayer.pause();
    MediaNotification.showNotification(
        title: title, author: artist, artUri: image, isPlaying: false);
    setState(() {
      playerState = PlayerState.paused;
    });
  }

  Future stop() async {
    await audioPlayer.stop();
    if (mounted)
      setState(() {
        playerState = PlayerState.stopped;
        position = Duration();
      });
  }

  Future mute(bool muted) async {
    await audioPlayer.mute(muted);
    if (mounted)
      setState(() {
        isMuted = muted;
      });
  }

  void onComplete() {
    if (mounted) setState(() => playerState = PlayerState.stopped);
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    return Container(
      color: Colors.black,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          brightness: Brightness.dark,
          backgroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
          title: Text(
            title,
            style: TextStyle(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          leading: Padding(
            padding: const EdgeInsets.only(left: 30.0),
            child: IconButton(
              icon: Icon(
                Icons.keyboard_arrow_down,
                size: 23,
                color: accent,
              ),
              onPressed: () => Navigator.pop(context, false),
            ),
          ),
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (duration != null)
                    Container(
                      width: screenWidth * 0.8,
                      height: screenHeight * 0.1,
                      child: Slider(
                          activeColor: accent,
                          inactiveColor: Colors.green[50],
                          value: position?.inMilliseconds?.toDouble() ?? 0.0,
                          onChanged: (double value) {
                            return audioPlayer
                                .seek((value / 1000).roundToDouble());
                          },
                          min: 0.0,
                          max: duration.inMilliseconds.toDouble()),
                    ),
                  if (position != null) _buildProgressView(),
                  Row(
                    children: [
                      Spacer(),
                      Container(
                        decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(100)),
                        child: IconButton(
                          onPressed: () => {
                            if (index > 0)
                              {
                                setState(() {
                                  index--;
                                }),
                                pause(),
                                getSongDetails(widget.songs[index].id)
                              }
                          },
                          iconSize: 20.0,
                          icon: Icon(MdiIcons.panLeft),
                          color: Color(0xff263238),
                        ),
                      ),
                      SizedBox(width: 5),
                      GestureDetector(
                        onTap: () {
                          print(isPlaying);
                          return isPlaying ? pause() : play();
                        },
                        child: Container(
                          width: screenWidth * 0.4,
                          height: screenHeight * 0.4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            shape: BoxShape.rectangle,
                            image: DecorationImage(
                              fit: BoxFit.fill,
                              image: CachedNetworkImageProvider(image),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 5),
                      Container(
                        decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(100)),
                        child: IconButton(
                          onPressed: () => {
                            if (index < widget.songs.length - 1)
                              {
                                setState(() {
                                  index++;
                                }),
                                pause(),
                                getSongDetails(widget.songs[index].id)
                              }
                          },
                          iconSize: 20.0,
                          icon: Icon(MdiIcons.panRight),
                          color: Color(0xff263238),
                        ),
                      ),
                      Spacer()
                    ],
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: Container(
                      color: Colors.black,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 15.0, bottom: 15),
                        child: Column(
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(top: 0.0),
                              child: Text(
                                album + "  |  " + artist,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: accentLight,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            SizedBox(height: 5),
                            if (index <= widget.songs.length - 2)
                              Center(
                                  child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Container(
                                  padding: EdgeInsets.all(6),
                                  color: accent,
                                  child: Text(widget.songs[index + 1].title,
                                      style: TextStyle(color: Colors.black)),
                                ),
                              )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Row _buildProgressView() => Row(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(width: 10),
        Text(
          position != null
              ? "${positionText ?? ''} ".replaceFirst("0:0", "0")
              : duration != null
                  ? durationText
                  : '',
          style: TextStyle(fontSize: 12.0, color: Colors.green[50]),
        ),
        Spacer(),
        Text(
          position != null
              ? "${durationText ?? ''}".replaceAll("0:", "")
              : duration != null
                  ? durationText
                  : '',
          style: TextStyle(fontSize: 12.0, color: Colors.green[50]),
        ),
        SizedBox(width: 10),
      ]);
}
