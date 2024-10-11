import 'dart:async';
import 'dart:math';

import 'package:earth_is_the_best/Quizz/QuizzResult.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:getwidget/getwidget.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../Ad_Helper.dart';
import '../HomePageState.dart';
import '../model/People.dart';
import 'QuizzOnMap.dart';

class QuizzByDescription extends StatefulWidget {
  const QuizzByDescription(
      {Key? key,
      required this.peoples,
      required this.progressBarPercentage,
      required this.lifePoint,
      required this.rating,
      required this.duration})
      : super(key: key);

  final List<People> peoples;
  final double progressBarPercentage;
  final int lifePoint;
  final double rating;
  final Duration duration;

  @override
  _QuizzByDescriptionState createState() => _QuizzByDescriptionState(
      peoples, progressBarPercentage, lifePoint, rating, duration);
}

class _QuizzByDescriptionState extends State<QuizzByDescription> {
  _QuizzByDescriptionState(this.peoples, this.progressBarPercentage,
      this.lifePoint, this.rating, this.duration);

  @override
  void dispose() async {
    super.dispose();
    timer?.cancel();
    _rewardedInterstitialAd?.dispose();
  }

  late List<People> peoples;

  final Color _mainColor = const Color.fromARGB(255, 47, 85, 151);
  final Color _secondaryColor = const Color.fromARGB(255, 32, 69, 129);
  late Color validateColor = Colors.green;

  Duration duration;
  Timer? timer;

  List<People> nameChoiceList = [];
  late People peopleToFind;
  late double rating;

  int selectedIndex = -1;

  late double progressBarPercentage;

  late int lifePoint;

  double pinPillPositionSuccess = -250;

  double pinPillPositionFailed = -250;

  String buttonValidateContinue = "Valider";

  Random random = Random();

  String minutes = "";

  String seconds = "";

  RewardedInterstitialAd? _rewardedInterstitialAd;

  void _loadRewardedInterstitialAd() {
    RewardedInterstitialAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              setState(() {
                ad.dispose();
                _rewardedInterstitialAd = null;
              });
              _loadRewardedInterstitialAd();
            },
          );

          setState(() {
            _rewardedInterstitialAd = ad;
          });
        },
        onAdFailedToLoad: (err) {
          print('Failed to load a rewarded ad: ${err.message}');
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color.fromARGB(255, 32, 69, 129),
      statusBarIconBrightness: Brightness.light,
    ));

    for (int i = 0; i < rating * 2; i++) {
      nameChoiceList.add(peoples.removeAt(random.nextInt(peoples.length)));
    }

    peopleToFind = nameChoiceList[random.nextInt(nameChoiceList.length)];

    timer = Timer.periodic(const Duration(seconds: 1), (_) => addTime());

    _loadRewardedInterstitialAd();
  }

  void addTime() {
    const addSecond = 1;
    setState(() {
      final seconds = duration.inSeconds + addSecond;
      duration = Duration(seconds: seconds);
      minutes = twoDigits(duration.inMinutes.remainder(60));
      this.seconds = twoDigits(duration.inSeconds.remainder(60));
    });
  }

  String twoDigits(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
          backgroundColor: _mainColor,
          appBar: GFAppBar(
            backgroundColor: _secondaryColor,
            leading: GFIconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const MyHomePage(selectedIndex: 1)));
                dispose();
              },
              type: GFButtonType.transparent,
            ),
            title: GFProgressBar(
              percentage: progressBarPercentage,
              lineHeight: 20,
              alignment: MainAxisAlignment.spaceBetween,
              backgroundColor: Colors.black26,
              progressBarColor: GFColors.SUCCESS,
            ),
            actions: <Widget>[
              GFButton(
                icon: const Icon(
                  Icons.favorite,
                  color: Colors.red,
                ),
                onPressed: () {},
                type: GFButtonType.transparent,
                text: lifePoint.toString(),
                textStyle: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          body: Stack(
            alignment: AlignmentDirectional.bottomStart,
            children: <Widget>[
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Padding(
                    padding: EdgeInsetsDirectional.only(
                        start: 16.0, end: 16.0, top: 10, bottom: 10),
                    child: Text("Selectionne le nom du peuple qui correspond",
                        style: TextStyle(
                            fontSize: 20,
                            color: Colors.white70,
                            fontWeight: FontWeight.bold)),
                  ),
                  GFListTile(
                    avatar: GFAvatar(
                      backgroundImage: AssetImage(
                          'assets/style/marker/i${peopleToFind.situation!}${peopleToFind.group!}.png'),
                      shape: GFAvatarShape.standard,
                      backgroundColor: Colors.transparent,
                      size: 50,
                    ),
                    color: Colors.white70,
                    subTitle: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.10,
                      width: 250.0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: Text(
                                peopleToFind.quizText!,
                                style: TextStyle(
                                    color: _mainColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.0),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsetsDirectional.only(top: 16.0),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.45,
                      width: 280,
                      child: ListView.builder(
                        scrollDirection: Axis.vertical,
                        itemCount: nameChoiceList.length,
                        itemBuilder: (BuildContext context, int position) {
                          return InkWell(
                            onTap: () =>
                                setState(() => selectedIndex = position),
                            child: SizedBox(
                              height: 50,
                              width: 50,
                              child: Card(
                                shadowColor: Colors.white12,
                                color: _mainColor,
                                shape: (selectedIndex == position)
                                    ? RoundedRectangleBorder(
                                        side: const BorderSide(
                                            color: Colors.green, width: 3.0),
                                        borderRadius:
                                            BorderRadius.circular(10.0))
                                    : RoundedRectangleBorder(
                                        side: const BorderSide(
                                            color: Colors.white70, width: 2.0),
                                        borderRadius:
                                            BorderRadius.circular(10.0)),
                                elevation: 5,
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: <Widget>[
                                    Text(
                                      nameChoiceList[position].nameFr,
                                      style: const TextStyle(
                                          fontSize: 20, color: Colors.white70),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              AnimatedPositioned(
                bottom: pinPillPositionSuccess,
                right: 0,
                left: 0,
                duration: const Duration(milliseconds: 200),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.25,
                    decoration: BoxDecoration(
                        color: _secondaryColor,
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                              offset: Offset.zero,
                              color: Colors.grey.withOpacity(0.5))
                        ]),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: const [
                          Padding(
                            padding: EdgeInsetsDirectional.only(
                                start: 38.0, top: 16.0),
                            child:
                                Icon(Icons.check_circle, color: Colors.green),
                          ),
                          Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text("Excellent",
                                style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ]),
                  ),
                ),
              ),
              AnimatedPositioned(
                bottom: pinPillPositionFailed,
                right: 0,
                left: 0,
                duration: const Duration(milliseconds: 200),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.25,
                    decoration: BoxDecoration(
                        color: _secondaryColor,
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                              offset: Offset.zero,
                              color: Colors.grey.withOpacity(0.5))
                        ]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: const [
                              Padding(
                                padding: EdgeInsetsDirectional.only(
                                    start: 38.0, top: 16.0),
                                child: Icon(Icons.circle_notifications,
                                    color: Colors.red, size: 30),
                              ),
                              Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text("Incorrect",
                                    style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ]),
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Padding(
                                padding:
                                    EdgeInsetsDirectional.only(start: 38.0),
                                child: Text("Réponse correcte : ",
                                    style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400)),
                              ),
                              Text(peopleToFind.nameFr,
                                  style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600))
                            ]),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                  height: MediaQuery.of(context).size.height * 0.10,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          backgroundColor: validateColor,
                          textStyle: const TextStyle(fontSize: 20),
                          disabledForegroundColor:
                              Colors.white70.withOpacity(0.38),
                          disabledBackgroundColor:
                              Colors.white70.withOpacity(0.12),
                          fixedSize: const Size(300, 50),
                        ),
                        onPressed: () {
                          setState(() {
                            if (buttonValidateContinue == "Continuer") {
                              if (lifePoint <= 0) {
                                showAlertDialog(context);
                              } else {
                                goToNextActivity();
                              }
                            } else {
                              if (selectedIndex != -1) {
                                if (lifePoint <= 0) {
                                  showAlertDialog(context);
                                } else {
                                  if (nameChoiceList[selectedIndex].nameFr ==
                                      peopleToFind.nameFr) {
                                    pinPillPositionSuccess = -30;
                                    progressBarPercentage += 0.1;
                                  } else {
                                    pinPillPositionFailed = 0;
                                    lifePoint -= 1;
                                    validateColor = Colors.red;
                                    if (lifePoint <= 0) {
                                      showAlertDialog(context);
                                    }
                                  }
                                  buttonValidateContinue = "Continuer";
                                }
                              }
                            }
                          });
                        },
                        child: Text(
                          buttonValidateContinue,
                          style: TextStyle(
                              color: _mainColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  )),
            ],
          )),
    );
  }

  showAlertDialog(BuildContext context) {
    // Create button
    SimpleDialog alert = SimpleDialog(children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              Icon(
                Icons.favorite,
                color: Colors.red,
              ),
              Text(" Aïe tu n'as plus de points de vie !")
            ],
          ),
          const Text("Regarde une publicité pour en regagner"),
          TextButton(
            onPressed: () {
              if (_rewardedInterstitialAd != null){
                _rewardedInterstitialAd?.show(
                  onUserEarnedReward: (_, reward) {
                    lifePoint++;
                    goToNextActivity();
                  },
                );
              } else {
                lifePoint++;
                goToNextActivity();
              }
            },
            child: const Text('Regarder'),
          ),
        ],
      ),
    ]);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  void goToNextActivity() {
    if (peoples.length >= rating * 2) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => QuizzOnMap(
                    peoples: peoples,
                    progressBarPercentage: progressBarPercentage,
                    lifePoint: lifePoint,
                    rating: rating,
                    duration: duration,
                  )));
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => QuizzResult(
                  score: progressBarPercentage,
                  timer: minutes + " : " + seconds,
                  reference: peopleToFind.reference.toString(),
                  rating: rating)));
      dispose();
    }
  }
}
