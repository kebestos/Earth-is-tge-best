import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:earth_is_the_best/Quizz/QuizzByDescription.dart';
import 'package:earth_is_the_best/model/User.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:getwidget/components/dropdown/gf_dropdown.dart';
import 'package:getwidget/components/rating/gf_rating.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../Ad_Helper.dart';
import '../Auth/AuthGate.dart';
import '../model/People.dart';
import 'ClassificationDialogItem.dart';

class QuizzPage extends StatefulWidget {
  const QuizzPage({Key? key}) : super(key: key);

  @override
  _QuizzPageState createState() => _QuizzPageState();
}

class Continent {
  late String name;
  late String reference;
  late LatLng coordinates;
  late int score;

  Continent(this.name, this.reference, this.coordinates, this.score);
}

class _QuizzPageState extends State<QuizzPage> {
  _QuizzPageState() {}

  late List<People> peoples = [];

  late List<UserData> users = [];
  late List<int> usersScoreToClassify = [];

  final FirebaseAuth _auth = FirebaseAuth.instance;

  late UserData user;
  late int scoreToDisplay = 0;

  final CollectionReference _collectionPeoples =
      FirebaseFirestore.instance.collection('Peoples_updated');

  final CollectionReference _collectionUsers =
      FirebaseFirestore.instance.collection('Users');

  late int currentScore = 0;

  Duration duration = Duration();

  final Color _mainColor = const Color.fromARGB(255, 47, 85, 151);

  // List<String> levels = <String>['Facile', 'Intermédiaire', 'Difficile'];
  // String levelValue = 'Facile';
  BannerAd? _bannerAd;

  void _loadBannerAd() {
    BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _bannerAd = ad as BannerAd;
          });
        },
        onAdFailedToLoad: (ad, err) {
          print('Failed to load a banner ad: ${err.message}');
          ad.dispose();
        },
      ),
    ).load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  List<Continent> continents = <Continent>[
    Continent("Europe", "EUR", const LatLng(47.551386, 16.753688), 0),
    Continent("Afrique", "AFR", const LatLng(-19.364745, 16.584908), 0),
    Continent("Amériques", "AM", const LatLng(10.970590, -74.671464), 0),
    Continent("Asie", "ASIE", const LatLng(9.929740, 105.413515), 0),
    Continent("Océanie", "OCE", const LatLng(-34.097509, 144.096631), 0)
  ];
  List<String> continentsDropDown = <String>[
    "Europe",
    "Afrique",
    "Amériques",
    "Asie",
    "Océanie"
  ];
  String continentValue = 'Europe';
  final _random = Random();

  // final isSituationsSelected = <bool>[true, true, false];

  double _rating = 1;
  int _ratingItemCount = 3;

  final ButtonStyle style = ElevatedButton.styleFrom(
    foregroundColor: Colors.white70,
    backgroundColor: Colors.green,
    textStyle: const TextStyle(fontSize: 20),
    disabledForegroundColor: Colors.white70.withOpacity(0.38),
    disabledBackgroundColor: Colors.white70.withOpacity(0.12),
    fixedSize: const Size(300, 50),
  );

  Future<void> getData() async {
    peoples.clear();

    await _collectionPeoples
        .where('reference',
            isEqualTo: continents
                .where((element) => element.name == continentValue)
                .first
                .reference)
        .where('quizText', isNull: false)
        .get()
        .then((QuerySnapshot querySnapshot) {
      for (var doc in querySnapshot.docs) {
        GeoPoint coordinates = doc['coordinates'];
        Color peopleTypeColor = Colors.red;
        if (doc['situation'] == "A") {
          peopleTypeColor = Colors.blue;
        } else if (doc['situation'] == "D") {
          peopleTypeColor = Colors.black;
        } else if (doc['situation'] == "F") {
          peopleTypeColor = Colors.orange;
        }
        People people = People(
          nameFr: doc['nameFr'],
          nameEng: doc['nameEng'],
          descriptionEng: doc['descriptionEng'],
          descriptionFr: doc['descriptionFr'],
          situation: doc['situation'],
          group: doc['group'],
          linkEng: doc['linkEng'],
          linkFr: doc['linkFr'],
          coordinatesLatLng:
              LatLng(coordinates.latitude, coordinates.longitude),
          reference: doc['reference'],
          quizText: doc['quizText'],
          color: peopleTypeColor,
        );
        peoples.add(people);
      }
    });
  }

  _asyncMethod() async {
    if (_auth.currentUser != null) {
      _collectionUsers.doc(_auth.currentUser?.uid).get().then((value) => {
            setState(() {
              user = UserData(
                  value['userName'],
                  value['photoUrl'],
                  value['scoreEUR'],
                  value['scoreAFR'],
                  value['scoreAM'],
                  value['scoreASIE'],
                  value['scoreOCE']);
            }),
            scoreToDisplay = user.scoreEUR,
            continents[0].score = user.scoreEUR,
            continents[1].score = user.scoreAFR,
            continents[2].score = user.scoreAM,
            continents[3].score = user.scoreASIE,
            continents[4].score = user.scoreOCE,
          });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _asyncMethod();
    });
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color.fromARGB(255, 47, 85, 151),
      statusBarIconBrightness: Brightness.light,
    ));
    _loadBannerAd();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: _mainColor,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const Padding(
              padding: EdgeInsetsDirectional.only(
                  start: 16.0, end: 16.0, top: 20.0, bottom: 32.0),
              child: Text('Quizz peoples guesser',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 26,
                      fontWeight: FontWeight.bold)),
            ),
            Image.asset("assets/style/logo/logo_earth_is_the_best.png",
                width: 100),
            // Container(
            //   height: 35,
            //   padding: EdgeInsets.zero,
            //   decoration: BoxDecoration(
            //     borderRadius: BorderRadius.circular(50),
            //     color: Colors.white,
            //   ),
            //   child: ToggleButtons(
            //     color: _mainColor,
            //     selectedColor: Colors.blue,
            //     selectedBorderColor: Colors.blue,
            //     fillColor: Colors.white,
            //     splashColor: Colors.blue.withOpacity(0.12),
            //     hoverColor: Colors.blue.withOpacity(0.04),
            //     borderRadius: BorderRadius.circular(50),
            //     constraints: const BoxConstraints(minHeight: 36.0),
            //     isSelected: isSituationsSelected,
            //     onPressed: (index) {
            //       setState(() {
            //         isSituationsSelected[index] = !isSituationsSelected[index];
            //       });
            //     },
            //     children: const [
            //       Padding(
            //         padding: EdgeInsets.symmetric(horizontal: 16.0),
            //         child: Text('Actuel'),
            //       ),
            //       Padding(
            //         padding: EdgeInsets.symmetric(horizontal: 16.0),
            //         child: Text('Fragile'),
            //       ),
            //       Padding(
            //         padding: EdgeInsets.symmetric(horizontal: 16.0),
            //         child: Text('Eteint'),
            //       ),
            //     ],
            //   ),
            // ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text("Peuples actuel et fragile",
                    style: TextStyle(fontSize: 20, color: Colors.white70)),
              ],
            ),
            Container(
              height: 50,
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.all(20),
              child: DropdownButtonHideUnderline(
                child: GFDropdown(
                  padding: const EdgeInsets.all(15),
                  borderRadius: BorderRadius.circular(5),
                  border: const BorderSide(color: Colors.black12, width: 1),
                  dropdownButtonColor: Colors.white,
                  value: continentValue,
                  onChanged: (newValue) {
                    setState(() {
                      continentValue = newValue.toString();
                      scoreToDisplay = continents
                          .where((element) => element.name == continentValue)
                          .first
                          .score;
                      if (continentValue == "Océanie") {
                        _ratingItemCount = 2;
                        _rating = 1;
                      } else {
                        _ratingItemCount = 3;
                      }
                    });
                  },
                  items: continentsDropDown
                      .map((value) => DropdownMenuItem(
                            value: value,
                            child: Text(value,
                                style: TextStyle(color: _mainColor)),
                          ))
                      .toList(),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Niveau : ",
                    style: TextStyle(fontSize: 20, color: Colors.white70)),
                GFRating(
                  color: Colors.yellow,
                  borderColor: Colors.yellowAccent,
                  itemCount: _ratingItemCount,
                  value: _rating,
                  onChanged: (value) {
                    setState(() {
                      _rating = value;
                    });
                  },
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(" Ton score $continentValue : $scoreToDisplay",
                        style: const TextStyle(
                            fontSize: 20, color: Colors.white70)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                        onPressed: () async {
                          if (_auth.currentUser != null) {
                            await getUserForClassification();
                            showAlertDialog(context);
                          } else {
                            showAlertDialogToConnect(context);
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: const [
                            Text("Classement",
                                style: TextStyle(
                                    fontSize: 20, color: Colors.white)),
                          ],
                        )),
                  ],
                ),
              ],
            ),
            Padding(
                padding: const EdgeInsetsDirectional.all(16.0),
                child: ElevatedButton(
                  style: style,
                  onPressed: () {
                    if (_auth.currentUser != null) {
                      play();
                    } else {
                      showAlertDialogToConnect(context);
                    }
                  },
                  child: const Text(
                    'Jouer',
                    style: TextStyle(color: Colors.white),
                  ),
                )),
            if (_bannerAd != null)
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                ),
              ),
          ],
        ));
  }

  Future<void> play() async {
    await getData();
    List<People> listFiltered = peoples
        .where((element) =>
            element.reference ==
            continents
                .where((element) => element.name == continentValue)
                .first
                .reference)
        //     .where((element) {
        //   if (isSituationsSelected[0] && element.situation == "A") {
        //     return true;
        //   }
        //   if (isSituationsSelected[1] && element.situation == "F") {
        //     return true;
        //   }
        //   if (isSituationsSelected[2] && element.situation == "D") {
        //     return true;
        //   }
        //   return false;
        // })
        .toList();
    int peoplesNumberForQuizz = 10 * 2 * _rating.toInt();
    // List<People> peoplesToPlay = List.generate(peoplesNumberForQuizz, (_) => listFiltered.toList()[_random.nextInt(listFiltered.length)]);
    List<People> peoplesToPlay = [];
    for (int i = 0; i < peoplesNumberForQuizz; i++) {
      peoplesToPlay
          .add(listFiltered.removeAt(_random.nextInt(listFiltered.length)));
    }
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => QuizzByDescription(
                  peoples: peoplesToPlay,
                  lifePoint: 5,
                  progressBarPercentage: 0.0,
                  rating: _rating,
                  duration: duration,
                )));
    dispose();
  }

  showAlertDialog(BuildContext context) {
    SimpleDialog alert =
        SimpleDialog(title: Text("Classement ${continentValue}"), children: [
      if (users.isNotEmpty)
        ClassificationDialogItem(
          imageUrl: users[0].photoUrl,
          text: "1. ${users[0].userName} : ${usersScoreToClassify[0]}",
        ),
      if (users.length >= 2)
        ClassificationDialogItem(
          imageUrl: users[1].photoUrl,
          text: "2. ${users[1].userName} : ${usersScoreToClassify[1]}",
        ),
      if (users.length >= 3)
        ClassificationDialogItem(
          imageUrl: users[2].photoUrl,
          text: "3. ${users[2].userName} : ${usersScoreToClassify[2]}",
        ),
      if (users.length >= 4)
        ClassificationDialogItem(
          imageUrl: users[3].photoUrl,
          text: "4. ${users[3].userName} : ${usersScoreToClassify[3]}",
        ),
      if (users.length >= 5)
        ClassificationDialogItem(
          imageUrl: users[4].photoUrl,
          text: "5. ${users[4].userName} : ${usersScoreToClassify[4]}",
        ),
      if (users.length >= 6)
        ClassificationDialogItem(
          imageUrl: users[5].photoUrl,
          text: "6. ${users[5].userName} : ${usersScoreToClassify[5]}",
        ),
      if (users.length >= 7)
        ClassificationDialogItem(
          imageUrl: users[6].photoUrl,
          text: "7. ${users[6].userName} : ${usersScoreToClassify[6]}",
        ),
      if (users.length >= 8)
        ClassificationDialogItem(
          imageUrl: users[7].photoUrl,
          text: "8. ${users[7].userName} : ${usersScoreToClassify[7]}",
        ),
      if (users.length >= 9)
        ClassificationDialogItem(
          imageUrl: users[8].photoUrl,
          text: "9. ${users[8].userName} : ${usersScoreToClassify[8]}",
        ),
      if (users.length >= 10)
        ClassificationDialogItem(
          imageUrl: users[9].photoUrl,
          text: "10. ${users[9].userName} : ${usersScoreToClassify[9]}",
        ),
    ]);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  Future<void> getUserForClassification() async {
    users.clear();
    usersScoreToClassify.clear();
    await _collectionUsers
        .orderBy(
            'score${continents.where((element) => element.name == continentValue).first.reference}',
            descending: true)
        .limit(10)
        .get()
        .then((value) => value.docs.forEach((doc) {
              UserData userData = UserData(
                  doc['userName'],
                  doc['photoUrl'],
                  doc['scoreEUR'],
                  doc['scoreAFR'],
                  doc['scoreAM'],
                  doc['scoreASIE'],
                  doc['scoreOCE']);
              users.add(userData);
              usersScoreToClassify.add(doc[
                  'score${continents.where((element) => element.name == continentValue).first.reference}']);
            }));
  }

  showAlertDialogToConnect(BuildContext context) {
    // Create button
    SimpleDialog alert = SimpleDialog(children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              // Icon(
              //   Icons.upload_file_outlined,
              //   color: Colors.blue,
              // ),
              Text("Connect toi pour jouer",
                overflow: TextOverflow.clip,
                textAlign: TextAlign.start,
                softWrap: true)
            ]),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: const [
                // Icon(
                //   Icons.upload_file_outlined,
                //   color: Colors.blue,
                // ),
                Text("et partager ton score",
                    overflow: TextOverflow.clip,
                    textAlign: TextAlign.start,
                    softWrap: true)
              ],
          ),
          TextButton(
            onPressed: () async {
              // StreamBuilder<User?>(
              //       stream: FirebaseAuth.instance.authStateChanges(),
              //       builder: (context, snapshot) {
              //         if (snapshot.hasData) {
              //           return const MyHomePage( selectedIndex: 1);
              //         }
              //         return const AuthGate();
              //       },
              //     );
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const AuthGate()));
            },
            child: const Text('Connexion'),
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
}
