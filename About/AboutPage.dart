import 'package:earth_is_the_best/Auth/DeleteAccount.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:getwidget/getwidget.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../Ad_Helper.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  _AboutPageState createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  final Color _mainColor = const Color.fromARGB(255, 47, 85, 151);

  BannerAd? _bannerAd;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _loadBannerAd() {
    BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _bannerAd = ad as BannerAd;
          });
        },
        onAdFailedToLoad: (ad, err) {
          if (kDebugMode) {
            print('Failed to load a banner ad: ${err.message}');
          }
          ad.dispose();
        },
      ),
    ).load();
  }

  final Uri emailLaunchUri = Uri(
    scheme: 'mailto',
    path: 'hello@earthisthebest.org',
  );

  List<Widget> languages = <Widget>[
    Image.asset("assets/style/logo/france.png", width: 50),
    Image.asset("assets/style/logo/royaume-uni.png", width: 50),
  ];
  final isLanguageSelected = <bool>[true, false];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color.fromARGB(255, 47, 85, 151),
      statusBarIconBrightness: Brightness.light,
    ));
    _loadBannerAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
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
                  start: 16.0, end: 16.0, top: 30.0, bottom: 0.0),
              child: Text('Earth is the best',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 26,
                      fontWeight: FontWeight.bold)),
            ),
            Image.asset("assets/style/logo/logo_earth_is_the_best.png",
                width: 100),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GFIconButton(
                  color: const Color.fromARGB(255, 18, 140, 126),
                  onPressed: () {
                    launchUrl(Uri.parse("https://www.earthisthebest.org/"));
                  },
                  icon: Image.asset("assets/style/logo/World.png", width: 40),
                ),
                GFIconButton(
                  color: const Color.fromARGB(255, 66, 103, 178),
                  onPressed: () {
                    launchUrlString("fb://page/664644013727600")
                        .catchError((onError) => launchUrlString(
                            "https://www.facebook.com/earthistheb3st"));
                  },
                  icon: const Icon(Icons.facebook),
                ),
                GFIconButton(
                  color: const Color.fromARGB(255, 29, 161, 242),
                  onPressed: () {
                    launchUrlString("twitter://user?id=1367046130949902336")
                        .catchError((onError) => launchUrlString(
                            "https://twitter.com/Seb_earthis?fbclid=IwAR2HbUqQOQupDtg_wANygZ--xoHxWkLrI6LX3jlmP4T-O6F_Mh0WI2eHyQA"));
                  },
                  icon: Image.asset(
                      "assets/style/logo/twitter-logo_transparent.png"),
                ),
              ],
            ),
            Flexible(
              child: Container(
                margin: const EdgeInsets.all(10),
                height: MediaQuery.of(context).size.width * 0.60,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const <Widget>[
                    Expanded(
                      child: SingleChildScrollView(
                          child: Padding(
                              padding: EdgeInsetsDirectional.only(
                                  start: 16.0, end: 16.0, top: 10, bottom: 10),
                              child: Text(
                                  "La diversité des cultures sur terre est un témoignage de la fascinante histoire de l'humanité. Chaque peuple devrait apprendre davantage sur les rites et coutumes des autres cultures, sur leur condition. Car c'est par l'éducation que l'on améliore notre compréhension de l'autre, et par l'ignorance que naissent les malentendus et conflits.",
                                  overflow: TextOverflow.clip,
                                  textAlign: TextAlign.start,
                                  softWrap: true,
                                  style: TextStyle(
                                      fontSize: 20,
                                      color:
                                          Color.fromARGB(255, 47, 85, 151))))),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GFButton(
                  color: const Color.fromARGB(255, 15, 157, 88),
                  onPressed: sendEmail,
                  text: "Contact",
                  icon: const Icon(Icons.mail_outline, color: Colors.white70),
                  // shape: GFButtonShape.square,
                  size: GFSize.LARGE,
                ),
                if (_auth.currentUser != null)
                  GFButton(
                    color: const Color.fromARGB(255, 15, 157, 88),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const DeleteAccount()));
                    },
                    text: "Supprimer le compte",
                    icon: const Icon(Icons.delete, color: Colors.white70),
                    // shape: GFButtonShape.square,
                    size: GFSize.LARGE,
                  ),
                // ToggleButtons(
                //   direction: Axis.horizontal,
                //   color: Colors.blue[400],
                //   selectedColor: Colors.white,
                //   selectedBorderColor: Colors.blue[700],
                //   fillColor: Colors.blue[200],
                //   splashColor: Colors.blue.withOpacity(0.12),
                //   hoverColor: Colors.blue.withOpacity(0.04),
                //   borderRadius: BorderRadius.circular(8),
                //   constraints: const BoxConstraints(
                //     minHeight: 30.0,
                //     maxHeight: 40.0,
                //     minWidth: 80.0,
                //   ),
                //   isSelected: isLanguageSelected,
                //   onPressed: (index) {
                //     setState(() {
                //       for (int i = 0; i < isLanguageSelected.length; i++) {
                //         isLanguageSelected[i] = i == index;
                //       }
                //     });
                //   },
                //   children: languages,
                // ),
              ],
            ),
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

  sendEmail() async {
    launchUrl(emailLaunchUri);
  }
}
