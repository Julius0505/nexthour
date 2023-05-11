import 'dart:io';
import 'package:better_player/better_player.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:nexthour/models/Subtitles.dart';
import 'package:provider/provider.dart';
import '../common/apipath.dart';
import '../common/google-ads.dart';
import '../providers/app_config.dart';
import '../providers/user_profile_provider.dart';
import '/common/global.dart';
import 'package:flutter/material.dart';
import 'package:wakelock/wakelock.dart';

// ignore: must_be_immutable
class MyCustomPlayer extends StatefulWidget {
  MyCustomPlayer({
    required this.title,
    required this.url,
    this.downloadStatus,
    required this.subtitles,
  });

  final String title;
  String url;
  final dynamic downloadStatus;
  final Subtitles? subtitles;

  @override
  State<StatefulWidget> createState() {
    return _MyCustomPlayerState();
  }
}

class _MyCustomPlayerState extends State<MyCustomPlayer>
    with WidgetsBindingObserver {
  TargetPlatform? platform;
  BetterPlayerController? _betterPlayerController;
  var betterPlayerConfiguration;
  DateTime? currentBackPressTime;

  dynamic selectedVideoIndex;
  bool showPlayerControls = true;
  void stopScreenLock() async {
    Wakelock.enable();
  }

  //  Handle back press
  Future<bool> onWillPopS() {
    DateTime now = DateTime.now();
    if (currentBackPressTime == null ||
        now.difference(currentBackPressTime!) > Duration(seconds: 2)) {
      currentBackPressTime = now;
      Navigator.pop(context);
      return Future.value(true);
    }
    return Future.value(true);
  }

  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.inactive:
        if (_betterPlayerController != null) _betterPlayerController!.pause();
        debugPrint("Inactive");
        break;
      case AppLifecycleState.resumed:
        if (_betterPlayerController != null) _betterPlayerController!.pause();
        break;
      case AppLifecycleState.paused:
        if (_betterPlayerController != null) _betterPlayerController!.pause();
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  BannerAd? _bannerAd;
  AdWidget? adWidget;

  @override
  void initState() {
    super.initState();

    // Ad
    _bannerAd = BannerAd(
      adUnitId: Platform.isAndroid ? bannerAdIDAndroid : bannerAdIDiOS,
      request: AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          print('$BannerAd loaded.');
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          print('$BannerAd failedToLoad: $error');
        },
        onAdOpened: (Ad ad) => print('$BannerAd onAdOpened.'),
        onAdClosed: (Ad ad) => print('$BannerAd onAdClosed.'),
      ),
    );
    _bannerAd?.load();
    adWidget = AdWidget(ad: _bannerAd!);

    this.stopScreenLock();
    setState(() {
      playerTitle = widget.title;
    });

    WidgetsBinding.instance.addObserver(this);
    Future.delayed(Duration.zero, () {
      initializePlayer();
    });

    String os = Platform.operatingSystem;

    if (os == 'android') {
      setState(() {
        platform = TargetPlatform.android;
      });
    } else {
      setState(() {
        platform = TargetPlatform.iOS;
      });
    }
  }

  Future<void> initializePlayer() async {
    widget.url = widget.url.contains(' ')
        ? widget.url.replaceAll(RegExp(r' '), '%20')
        : widget.url;
    print('Video URL :-> ${widget.url}');
    List<BetterPlayerSubtitlesSource>? _subtitles = [];

    if (widget.subtitles != null) {
      if ((widget.subtitles?.subtitles?.length)! > 0) {
        for (int i = 0; i < (widget.subtitles?.subtitles?.length)!; i++) {
          print(
              "Subtitle :-> ${APIData.subtitlePlayer}${widget.subtitles?.subtitles?[i].subT!}");
          _subtitles.add(
            BetterPlayerSubtitlesSource(
              type: BetterPlayerSubtitlesSourceType.network,
              name: widget.subtitles?.subtitles![i].subLang ?? "Unknown",
              urls: [
                '${APIData.subtitlePlayer}${widget.subtitles?.subtitles?[i].subT!}'
              ],
            ),
          );
        }
      }
    }

    try {
      int _startAt = 0;
      if (await storage.containsKey(key: widget.url)) {
        String? s = await storage.read(key: widget.url);
        if (s != null) {
          _startAt = int.parse(s);
        } else {
          _startAt = 0;
        }
      }

      var dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        widget.url,
        subtitles: _subtitles,
      );
      betterPlayerConfiguration = BetterPlayerConfiguration(
        startAt: Duration(seconds: _startAt),
        autoPlay: true,
        looping: false,
        fullScreenByDefault: true,
        aspectRatio: MediaQuery.of(context).size.aspectRatio,
        subtitlesConfiguration: BetterPlayerSubtitlesConfiguration(
          fontSize: 20,
          fontColor: Colors.white,
          backgroundColor: Colors.black,
        ),
        controlsConfiguration: BetterPlayerControlsConfiguration(
          textColor: Colors.white,
          iconsColor: Colors.white,
        ),
      );
      _betterPlayerController = BetterPlayerController(
        betterPlayerConfiguration,
        betterPlayerDataSource: dataSource,
      );
      _betterPlayerController!.play();

      _betterPlayerController!.videoPlayerController!.addListener(
        () {
          if (currentPositionInSec == 0) setState(() {});
          currentPositionInSec = _betterPlayerController!
              .videoPlayerController!.value.position.inSeconds;
          print('Position in Seconds : $currentPositionInSec');
        },
      );
    } catch (e) {
      print('Better Player Error :-> $e');
    }
  }

  int currentPositionInSec = 0, durationInSec = 0;

  void saveCurrentPosition() {
    durationInSec = _betterPlayerController!
        .videoPlayerController!.value.duration!.inSeconds;
    print('Duration in Seconds :$durationInSec');
    if (currentPositionInSec == durationInSec) {
      storage.write(key: widget.url, value: '0');
    } else {
      storage.write(key: widget.url, value: '$currentPositionInSec');
    }
  }

  @override
  void dispose() async {
    saveCurrentPosition();
    _betterPlayerController!.dispose();
    Wakelock.disable();

    // Ad
    _bannerAd?.dispose();
    _bannerAd = null;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userDetails = Provider.of<UserProfileProvider>(context, listen: false)
        .userProfileModel!;
    final appconfig = Provider.of<AppConfig>(context, listen: false).appModel;
    return WillPopScope(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
        ),
        backgroundColor: Theme.of(context).primaryColorDark,
        body: Stack(
          children: [
            _betterPlayerController == null
                ? Center(child: CircularProgressIndicator())
                : Center(
                    // flex: 8,
                    child: _betterPlayerController != null
                        ? BetterPlayer(
                            controller: _betterPlayerController!,
                          )
                        : SizedBox.shrink(),
                  ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if ((userDetails.removeAds == "0" ||
                        userDetails.removeAds == 0) &&
                    (appconfig?.appConfig?.removeAds == 0 ||
                        appconfig?.appConfig?.removeAds == '0'))
                  Expanded(
                    flex: 1,
                    child: Align(
                      alignment: FractionalOffset.topCenter,
                      child: Padding(
                        padding: EdgeInsets.only(top: 20.0),
                        child: Container(
                          alignment: Alignment.center,
                          child: adWidget,
                          width: _bannerAd!.size.width.toDouble(),
                          height: _bannerAd!.size.height.toDouble(),
                        ),
                      ),
                    ),
                  ),
              ],
            )
          ],
        ),
      ),
      onWillPop: onWillPopS,
    );
  }
}
