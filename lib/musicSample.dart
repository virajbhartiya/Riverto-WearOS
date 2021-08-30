// import 'dart:async';
// 
// import 'package:audioplayer/audioplayer.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_media_notification/flutter_media_notification.dart';
// import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
// import 'package:rivertoWearOS/style/appColors.dart';
// import 'API/saavn.dart';

// String status = 'hidden';
// AudioPlayer audioPlayer;
// PlayerState playerState;

// typedef void OnError(Exception exception);

// enum PlayerState { stopped, playing, paused }

// class AudioApp extends StatefulWidget {
//   @override
//   AudioAppState createState() => AudioAppState();
// }

// @override
// class AudioAppState extends State<AudioApp> {
//   Duration duration;
//   Duration position;

//   get isPlaying => playerState == PlayerState.playing;

//   get isPaused => playerState == PlayerState.paused;

//   get durationText =>
//       duration != null ? duration.toString().split('.').first : '';

//   get positionText =>
//       position != null ? position.toString().split('.').first : '';

//   bool isMuted = false;

//   StreamSubscription _positionSubscription;
//   StreamSubscription _audioPlayerStateSubscription;

//   @override
//   void initState() {
//     super.initState();
//     qplaying = true;
//     initAudioPlayer();
//   }

//   @override
//   void dispose() {
//     super.dispose();
//   }

//   void initAudioPlayer() {
//     if (audioPlayer == null) {
//       audioPlayer = AudioPlayer();
//     }
//     setState(() {
//       if (checker == "yes") {
//         stop();
//         play();
//       }
//       if (checker == "no") {
//         if (playerState == PlayerState.playing) {
//           play();
//         } else {
//           //Using (Hack) Play() here Else UI glitch is being caused, Will try to find better solution.
//           play();
//           pause();
//         }
//       }
//     });

//     _positionSubscription = audioPlayer.onAudioPositionChanged
//         .listen((p) => {if (mounted) setState(() => position = p)});

//     _audioPlayerStateSubscription =
//         audioPlayer.onPlayerStateChanged.listen((s) {
//       if (s == AudioPlayerState.PLAYING) {
//         {
//           if (mounted) setState(() => duration = audioPlayer.duration);
//         }
//       } else if (s == AudioPlayerState.STOPPED) {
//         onComplete();
//         if (mounted)
//           setState(() {
//             position = duration;
//           });
//       }
//     }, onError: (msg) {
//       if (mounted)
//         setState(() {
//           playerState = PlayerState.stopped;
//           duration = Duration(seconds: 0);
//           position = Duration(seconds: 0);
//         });
//     });
//   }

//   Future play() async {
//     await audioPlayer.play(kUrl);
//     MediaNotification.showNotification(
//         title: title, author: artist, artUri: image, isPlaying: true);
//     if (mounted)
//       setState(() {
//         playerState = PlayerState.playing;
//       });
//   }

//   Future pause() async {
//     await audioPlayer.pause();
//     MediaNotification.showNotification(
//         title: title, author: artist, artUri: image, isPlaying: false);
//     setState(() {
//       playerState = PlayerState.paused;
//     });
//   }

//   Future stop() async {
//     await audioPlayer.stop();
//     if (mounted)
//       setState(() {
//         playerState = PlayerState.stopped;
//         position = Duration();
//       });
//   }

//   Future mute(bool muted) async {
//     await audioPlayer.mute(muted);
//     if (mounted)
//       setState(() {
//         isMuted = muted;
//       });
//   }

//   void onComplete() {
//     if (mounted) setState(() => playerState = PlayerState.stopped);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       color: Colors.black,
//       child: Scaffold(
//         backgroundColor: Colors.transparent,
//         appBar: AppBar(
//           brightness: Brightness.dark,
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//           //backgroundColor: Color(0xff384850),
//           centerTitle: true,
//           title: Text(
//             "Now Playing",
//             style: TextStyle(
//               color: accent,
//               fontSize: 25,
//               fontWeight: FontWeight.w700,
//             ),
//           ),

//           leading: Padding(
//             padding: const EdgeInsets.only(left: 14.0),
//             child: IconButton(
//               icon: Icon(
//                 Icons.keyboard_arrow_down,
//                 size: 32,
//                 color: accent,
//               ),
//               onPressed: () => Navigator.pop(context, false),
//             ),
//           ),
//         ),
//         body: Stack(
//           children: [
//             particle(context),
//             SingleChildScrollView(
//               child: Padding(
//                 padding: const EdgeInsets.only(top: 15.0),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Container(
//                       width: 250,
//                       height: 250,
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(15),
//                         shape: BoxShape.rectangle,
//                         image: DecorationImage(
//                           fit: BoxFit.fill,
//                           image: CachedNetworkImageProvider(image),
//                         ),
//                       ),
//                     ),
//                     ClipRRect(
//                       borderRadius: BorderRadius.circular(25),
//                       child: Container(
//                         color: Colors.black,
//                         child: Padding(
//                           padding: const EdgeInsets.only(top: 15.0, bottom: 15),
//                           child: Column(
//                             children: <Widget>[
//                               Text(
//                                 title,
//                                 // shaderRect: Rect.fromLTWH(13.0, 0.0, 100.0, 50.0),
//                                 // gradient: LinearGradient(colors: [
//                                 //   Color(0xff4db6ac),
//                                 //   Color(0xff61e88a),
//                                 // ]),
//                                 textScaleFactor: 2.5,
//                                 textAlign: TextAlign.center,
//                                 style: TextStyle(
//                                     color: accent,
//                                     fontSize: 12,
//                                     fontWeight: FontWeight.w700),
//                               ),
//                               Padding(
//                                 padding: const EdgeInsets.only(top: 0.0),
//                                 child: Text(
//                                   album + "  |  " + artist,
//                                   textAlign: TextAlign.center,
//                                   style: TextStyle(
//                                     color: accentLight,
//                                     fontSize: 15,
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                     Material(child: _buildPlayer()),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildPlayer() => Container(
//         padding: EdgeInsets.only(top: 10.0, left: 10, right: 10, bottom: 10),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.center,
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             if (duration != null)
//               Slider(
//                   activeColor: accent,
//                   inactiveColor: Colors.green[50],
//                   value: position?.inMilliseconds?.toDouble() ?? 0.0,
//                   onChanged: (double value) {
//                     return audioPlayer.seek((value / 1000).roundToDouble());
//                   },
//                   min: 0.0,
//                   max: duration.inMilliseconds.toDouble()),
//             if (position != null) _buildProgressView(),
//             Padding(
//               padding: const EdgeInsets.only(top: .0),
//               child: Column(
//                 children: <Widget>[
//                   Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       isPlaying
//                           ? Container()
//                           : Container(
//                               decoration: BoxDecoration(
//                                   color: accent,
//                                   borderRadius: BorderRadius.circular(100)),
//                               child: IconButton(
//                                 onPressed: isPlaying ? null : () => play(),
//                                 iconSize: 40.0,
//                                 icon: Padding(
//                                   padding: const EdgeInsets.only(left: 2.2),
//                                   child: Icon(MdiIcons.playOutline),
//                                 ),
//                                 color: Color(0xff263238),
//                               ),
//                             ),
//                       isPlaying
//                           ? Container(
//                               decoration: BoxDecoration(
//                                   color: accent,
//                                   borderRadius: BorderRadius.circular(100)),
//                               child: IconButton(
//                                 onPressed: isPlaying ? () => pause() : null,
//                                 iconSize: 40.0,
//                                 icon: Icon(MdiIcons.pause),
//                                 color: Color(0xff263238),
//                               ),
//                             )
//                           : Container()
//                     ],
//                   ),
//                   lyrics != "null"
//                       ? Padding(
//                           padding: const EdgeInsets.only(top: 20.0),
//                           child: Builder(builder: (context) {
//                             return FlatButton(
//                                 shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(18.0)),
//                                 color: Colors.black12,
//                                 onPressed: () {
//                                   showBottomSheet(
//                                       context: context,
//                                       builder: (context) => Container(
//                                             decoration: BoxDecoration(
//                                                 color: Colors.black,
//                                                 borderRadius: BorderRadius.only(
//                                                     topLeft:
//                                                         const Radius.circular(
//                                                             18.0),
//                                                     topRight:
//                                                         const Radius.circular(
//                                                             18.0))),
//                                             height: 400,
//                                             child: Column(
//                                               crossAxisAlignment:
//                                                   CrossAxisAlignment.center,
//                                               children: <Widget>[
//                                                 Padding(
//                                                   padding:
//                                                       const EdgeInsets.only(
//                                                           top: 10.0),
//                                                   child: Row(
//                                                     children: <Widget>[
//                                                       IconButton(
//                                                           icon: Icon(
//                                                             Icons
//                                                                 .arrow_back_ios,
//                                                             color: accent,
//                                                             size: 20,
//                                                           ),
//                                                           onPressed: () => {
//                                                                 Navigator.pop(
//                                                                     context)
//                                                               }),
//                                                       Expanded(
//                                                         child: Padding(
//                                                           padding:
//                                                               const EdgeInsets
//                                                                       .only(
//                                                                   right: 42.0),
//                                                           child: Center(
//                                                             child: Text(
//                                                               "Lyrics",
//                                                               style: TextStyle(
//                                                                 color: accent,
//                                                                 fontSize: 30,
//                                                                 fontWeight:
//                                                                     FontWeight
//                                                                         .w500,
//                                                               ),
//                                                             ),
//                                                           ),
//                                                         ),
//                                                       ),
//                                                     ],
//                                                   ),
//                                                 ),
//                                                 // lyrics != "null"
//                                                 //     ?
//                                                 Expanded(
//                                                   flex: 1,
//                                                   child: Padding(
//                                                       padding:
//                                                           const EdgeInsets.all(
//                                                               6.0),
//                                                       child: Center(
//                                                         child:
//                                                             SingleChildScrollView(
//                                                           child: Text(
//                                                             lyrics,
//                                                             style: TextStyle(
//                                                               fontSize: 16.0,
//                                                               color:
//                                                                   accentLight,
//                                                             ),
//                                                             textAlign: TextAlign
//                                                                 .center,
//                                                           ),
//                                                         ),
//                                                       )),
//                                                 )
//                                                 // : Padding(
//                                                 //     padding:
//                                                 //         const EdgeInsets.only(
//                                                 //             top: 120.0),
//                                                 //     child: Center(
//                                                 //       child: Container(
//                                                 //         child: Text(
//                                                 //           "No Lyrics available ;(",
//                                                 //           style: TextStyle(
//                                                 //               color: accentLight,
//                                                 //               fontSize: 25),
//                                                 //         ),
//                                                 //       ),
//                                                 //     ),
//                                                 //   ),
//                                               ],
//                                             ),
//                                           ));
//                                 },
//                                 child: ClipRRect(
//                                   borderRadius: BorderRadius.circular(25),
//                                   child: Container(
//                                     padding: EdgeInsets.symmetric(
//                                         vertical: 10, horizontal: 10),
//                                     color: Colors.black,
//                                     child: Text(
//                                       "Lyrics",
//                                       style: TextStyle(
//                                           color: accent, letterSpacing: 3),
//                                     ),
//                                   ),
//                                 ));
//                           }),
//                         )
//                       : Container()
//                 ],
//               ),
//             ),
//           ],
//         ),
//       );

//   Row _buildProgressView() => Row(mainAxisSize: MainAxisSize.min, children: [
//         Text(
//           position != null
//               ? "${positionText ?? ''} ".replaceFirst("0:0", "0")
//               : duration != null
//                   ? durationText
//                   : '',
//           style: TextStyle(fontSize: 18.0, color: Colors.green[50]),
//         ),
//         Spacer(),
//         Text(
//           position != null
//               ? "${durationText ?? ''}".replaceAll("0:", "")
//               : duration != null
//                   ? durationText
//                   : '',
//           style: TextStyle(fontSize: 18.0, color: Colors.green[50]),
//         )
//       ]);
// }
