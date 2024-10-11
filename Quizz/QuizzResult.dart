import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../Ad_Helper.dart';
import '../HomePageState.dart';

class QuizzResult extends StatefulWidget {
  const QuizzResult(
      {Key? key,
      required this.score,
      required this.timer,
      required this.reference,
      required this.rating})
      : super(key: key);

  final double score;
  final String timer;
  final String reference;
  final double rating;

  @override
  _QuizzResultState createState() =>
      _QuizzResultState(score, timer, reference, rating);
}

class _QuizzResultState extends State<QuizzResult> {
  _QuizzResultState(double score, this.timer, this.reference, this.rating) {
    reponse = (10 * score).round();
  }

  late int reponse;
  late String timer;
  late String reference;
  late int finalScore = 0;
  late double rating;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference _collectionRef =
      FirebaseFirestore.instance.collection('Users');

  final Color _mainColor = const Color.fromARGB(255, 47, 85, 151);
  final Color _secondaryColor = const Color.fromARGB(255, 32, 69, 129);
  final Color _xpColor = const Color.fromARGB(255, 255, 215, 0);
  final Color _timeColor = Colors.lightBlueAccent;
  final Color _scoreColor = Colors.lightGreen;

  final ButtonStyle style = ElevatedButton.styleFrom(
    foregroundColor: Colors.white70,
    backgroundColor: Colors.green,
    textStyle: const TextStyle(fontSize: 20),
    disabledForegroundColor: Colors.white70.withOpacity(0.38),
    disabledBackgroundColor: Colors.white70.withOpacity(0.12),
    fixedSize: const Size(300, 50),
  );

  InterstitialAd? _interstitialAd;

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              setState(() {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                        const MyHomePage(selectedIndex: 1)));
              });
            },
          );

          setState(() {
            _interstitialAd = ad;
          });
        },
        onAdFailedToLoad: (err) {
          print('Failed to load an interstitial ad: ${err.message}');
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color.fromARGB(255, 47, 85, 151),
      statusBarIconBrightness: Brightness.light,
    ));

    calculateScore();

    _loadInterstitialAd();

    _collectionRef
        .doc(_auth.currentUser?.uid)
        .get()
        .then((value) => {
              if (value['score$reference'] < finalScore)
                {
                  _collectionRef
                      .doc(_auth.currentUser?.uid)
                      .update({'score$reference': finalScore})
                }
            })
        .catchError((error) => print("Failed to update user score: $error"));
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    super.dispose();
  }

  void calculateScore() {
    if (reponse == 0) {
      return;
    }
    finalScore = rating.toInt() * reponse * 1000;

    int? minutes = int.tryParse(timer.split(':').first);
    int? seconds = int.tryParse(timer.split(':').last);

    if (minutes! > 15) {
      return;
    } else if (12 < minutes && minutes < 15) {
      finalScore += 100;
      return;
    } else if (10 < minutes && minutes < 12) {
      finalScore += 200;
      int diff = 10 - minutes;
      finalScore += diff * 400;
      int diffSeconds = 60 - seconds!;
      finalScore += diffSeconds * 5;
      return;
    } else if (5 < minutes && minutes < 10) {
      finalScore += 300;
      int diff = 10 - minutes;
      finalScore += diff * 400;
      int diffSeconds = 60 - seconds!;
      finalScore += diffSeconds * 10;
      return;
    } else if (minutes < 5) {
      finalScore += 400;
      finalScore += 5 * 400;
      int diff = 5 - minutes;
      finalScore += diff * 800;
      int diffSeconds = 60 - seconds!;
      finalScore += diffSeconds * 15;
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          backgroundColor: _mainColor,
          body: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const Text('Quizz terminé !',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 26,
                      fontWeight: FontWeight.bold)),
              Image.asset("assets/style/logo/logo_earth_is_the_best.png",
                  width: 100),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    width: 100,
                    height: 80,
                    child: Card(
                        color: _xpColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("SCORE",
                                style: TextStyle(
                                    color: _mainColor,
                                    fontWeight: FontWeight.bold)),
                            SizedBox(
                              width: 95,
                              height: 56,
                              child: Card(
                                  color: _mainColor,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10.0)),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Icon(Icons.align_horizontal_left_rounded,
                                          color: _xpColor),
                                      Text(finalScore.toString(),
                                          style: TextStyle(
                                              color: _xpColor,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  )),
                            )
                          ],
                        )),
                  ),
                  SizedBox(
                    width: 100,
                    height: 80,
                    child: Card(
                        color: _timeColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("TEMPS",
                                style: TextStyle(
                                    color: _mainColor,
                                    fontWeight: FontWeight.bold)),
                            SizedBox(
                              width: 95,
                              height: 56,
                              child: Card(
                                  color: _mainColor,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10.0)),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Icon(Icons.timer, color: _timeColor),
                                      Text(timer,
                                          style: TextStyle(
                                              color: _timeColor,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  )),
                            )
                          ],
                        )),
                  ),
                  SizedBox(
                    width: 100,
                    height: 80,
                    child: Card(
                        color: _scoreColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("REPONSES",
                                style: TextStyle(
                                    color: _mainColor,
                                    fontWeight: FontWeight.bold)),
                            SizedBox(
                              width: 95,
                              height: 56,
                              child: Card(
                                  color: _mainColor,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10.0)),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Icon(Icons.vertical_align_bottom,
                                          color: _scoreColor),
                                      Text("$reponse/10",
                                          style: TextStyle(
                                              color: _scoreColor,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  )),
                            )
                          ],
                        )),
                  ),
                ],
              ),
              ElevatedButton(
                style: style,
                onPressed: () {
                  if (_interstitialAd != null) {
                    _interstitialAd?.show();
                  } else {
                    setState(() {
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                              const MyHomePage(selectedIndex: 1)));
                    });
                  }
                },
                child: Text(
                  "Continuer",
                  style:
                      TextStyle(color: _mainColor, fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
        ));
  }
}
