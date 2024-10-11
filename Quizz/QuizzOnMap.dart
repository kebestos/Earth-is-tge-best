import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:earth_is_the_best/Quizz/QuizzByDescription.dart';
import 'package:fluster/fluster.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:getwidget/colors/gf_color.dart';
import 'package:getwidget/components/appbar/gf_appbar.dart';
import 'package:getwidget/components/button/gf_button.dart';
import 'package:getwidget/components/button/gf_icon_button.dart';
import 'package:getwidget/components/progress_bar/gf_progress_bar.dart';
import 'package:getwidget/types/gf_button_type.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../Ad_Helper.dart';
import '../HomePageState.dart';
import '../Map/MapHelper.dart';
import '../Map/MapMarker.dart';
import '../model/People.dart';
import 'QuizzResult.dart';

class QuizzOnMap extends StatefulWidget {
  const QuizzOnMap(
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
  _QuizzOnMapState createState() => _QuizzOnMapState(
      peoples, progressBarPercentage, lifePoint, rating, duration);
}

class _QuizzOnMapState extends State<QuizzOnMap> {
  _QuizzOnMapState(this.peoples, this.progressBarPercentage, this.lifePoint,
      this.rating, this.duration);

  late double progressBarPercentage;
  late int lifePoint;
  late List<People> peoples;
  List<People> peoplesChoiceList = [];
  late People peopleToFind;
  late String peopleNameSelected = "";
  late double rating;
  late LatLng currentContinentCoordinated = const LatLng(48.856614, 2.3522219);

  Duration duration;
  Timer? timer;
  String minutes = "";
  String seconds = "";

  late double _currentZoom = 3;

  late GoogleMapController _mapController;

  String _mapStyle = "";

  Set<Marker> markers = {};
  Fluster<MapMarker>? _clusterManager;

  /// Minimum zoom at which the markers will cluster
  final int _minClusterZoom = 0;

  /// Maximum zoom at which the markers will cluster
  final int _maxClusterZoom = 19;

  /// Color of the cluster circle
  final Color _clusterColor = const Color.fromARGB(153, 110, 204, 57);

  /// Color of the cluster text
  final Color _clusterTextColor = Colors.white;

  /// Markers loading flag
  bool _areMarkersLoading = true;

  bool _isMapLoading = true;

  late BitmapDescriptor actualPeoplesIcon;
  late BitmapDescriptor weakPeoplesIcon;
  late BitmapDescriptor deadPeoplesIcon;
  late BitmapDescriptor actualPeoplesGroupIcon;
  late BitmapDescriptor actualPeoplesNationIcon;
  late BitmapDescriptor weakPeoplesGroupIcon;
  late BitmapDescriptor weakPeoplesNationIcon;
  late BitmapDescriptor weakPeoplesNationIconBig;
  late BitmapDescriptor deadPeoplesGroupIcon;
  late BitmapDescriptor actualPeoplesIconBig;
  late BitmapDescriptor weakPeoplesIconBig;
  late BitmapDescriptor deadPeoplesIconBig;
  late BitmapDescriptor actualPeoplesGroupIconBig;
  late BitmapDescriptor actualPeoplesNationIconBig;
  late BitmapDescriptor weakPeoplesGroupIconBig;
  late BitmapDescriptor deadPeoplesGroupIconBig;

  final Color _mainColor = const Color.fromARGB(255, 47, 85, 151);
  final Color _secondaryColor = const Color.fromARGB(255, 32, 69, 129);
  late Color validateColor = Colors.green;
  String buttonValidateContinue = "Valider";

  double pinPillPositionSuccess = -250;

  double pinPillPositionFailed = -250;

  double pinPillPositionCardPeopleToFind = 70;

  Random random = Random();

  @override
  void initState() {
    super.initState();
    setState(() => _isMapLoading = true);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color.fromARGB(255, 32, 69, 129),
      statusBarIconBrightness: Brightness.light,
    ));

    for (int i = 0; i < 2 * rating; i++) {
      peoplesChoiceList.add(peoples.removeAt(random.nextInt(peoples.length)));
    }

    initPeople();
    peopleToFind = peoplesChoiceList[random.nextInt(peoplesChoiceList.length)];

    SchedulerBinding.instance.addPostFrameCallback((_) {
      rootBundle.loadString("assets/style/map_style.txt").then((string) {
        _mapStyle = string;
      });
    });
    timer = Timer.periodic(const Duration(seconds: 1), (_) => addTime());

    if (peopleToFind.reference == "EUR") {
      currentContinentCoordinated = const LatLng(47.551386, 16.753688);
    } else if (peopleToFind.reference == "AFR") {
      currentContinentCoordinated = const LatLng(-19.364745, 16.584908);
    } else if (peopleToFind.reference == "AM") {
      currentContinentCoordinated = const LatLng(10.970590, -74.671464);
    } else if (peopleToFind.reference == "ASIE") {
      currentContinentCoordinated = const LatLng(9.929740, 105.413515);
    } else if (peopleToFind.reference == "OCE") {
      currentContinentCoordinated = const LatLng(-34.097509, 144.096631);
    }

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
  void dispose() {
    super.dispose();
    timer?.cancel();
  }

  Future<void> initPeople() async {
    await initIcon();
    await refreshMarker("");
  }

  Future<void> initIcon() async {
    await getBytesFromAsset('assets/style/marker/iFC.png', 150).then((value) =>
        {weakPeoplesNationIcon = BitmapDescriptor.fromBytes(value!)});
    await getBytesFromAsset('assets/style/marker/iFC.png', 250).then((value) =>
        {weakPeoplesNationIconBig = BitmapDescriptor.fromBytes(value!)});
    await getBytesFromAsset('assets/style/marker/iAC.png', 150).then((value) =>
        {actualPeoplesNationIcon = BitmapDescriptor.fromBytes(value!)});
    await getBytesFromAsset('assets/style/marker/iAP.png', 150).then(
        (value) => {actualPeoplesIcon = BitmapDescriptor.fromBytes(value!)});
    await getBytesFromAsset('assets/style/marker/iAG.png', 150).then((value) =>
        {actualPeoplesGroupIcon = BitmapDescriptor.fromBytes(value!)});
    await getBytesFromAsset('assets/style/marker/iFP.png', 150).then(
        (value) => {weakPeoplesIcon = BitmapDescriptor.fromBytes(value!)});
    await getBytesFromAsset('assets/style/marker/iFG.png', 150).then(
        (value) => {weakPeoplesGroupIcon = BitmapDescriptor.fromBytes(value!)});
    await getBytesFromAsset('assets/style/marker/iDP.png', 150).then(
        (value) => {deadPeoplesIcon = BitmapDescriptor.fromBytes(value!)});
    await getBytesFromAsset('assets/style/marker/iDG.png', 150).then(
        (value) => {deadPeoplesGroupIcon = BitmapDescriptor.fromBytes(value!)});
    await getBytesFromAsset('assets/style/marker/iAC.png', 250).then((value) =>
        {actualPeoplesNationIconBig = BitmapDescriptor.fromBytes(value!)});
    await getBytesFromAsset('assets/style/marker/iAP.png', 250).then(
        (value) => {actualPeoplesIconBig = BitmapDescriptor.fromBytes(value!)});
    await getBytesFromAsset('assets/style/marker/iAG.png', 250).then((value) =>
        {actualPeoplesGroupIconBig = BitmapDescriptor.fromBytes(value!)});
    await getBytesFromAsset('assets/style/marker/iFP.png', 250).then(
        (value) => {weakPeoplesIconBig = BitmapDescriptor.fromBytes(value!)});
    await getBytesFromAsset('assets/style/marker/iFG.png', 250).then((value) =>
        {weakPeoplesGroupIconBig = BitmapDescriptor.fromBytes(value!)});
    await getBytesFromAsset('assets/style/marker/iDP.png', 250).then(
        (value) => {deadPeoplesIconBig = BitmapDescriptor.fromBytes(value!)});
    await getBytesFromAsset('assets/style/marker/iDG.png', 250).then((value) =>
        {deadPeoplesGroupIconBig = BitmapDescriptor.fromBytes(value!)});
  }

  Future<Uint8List?> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))
        ?.buffer
        .asUint8List();
  }

  Future<void> refreshMarker(String selectedNamePeople) async {
    late BitmapDescriptor currentIcon;
    late BitmapDescriptor currentIconBig;
    final List<MapMarker> mapMarkers = [];
    // markers.clear();
    for (var people in peoplesChoiceList) {
      if (people.coordinatesLatLng != null) {
        if (people.situation == "A" && people.group != null) {
          if (people.group == "C") {
            currentIcon = actualPeoplesNationIcon;
            currentIconBig = actualPeoplesNationIconBig;
          } else if (people.group == "G") {
            currentIcon = actualPeoplesGroupIcon;
            currentIconBig = actualPeoplesGroupIconBig;
          } else if (people.group == "P") {
            currentIcon = actualPeoplesIcon;
            currentIconBig = actualPeoplesIconBig;
          }
          MapMarker mapMarker = MapMarker(
            id: people.coordinatesLatLng.toString(),
            position: people.coordinatesLatLng!,
            onTap: () {
              setState(() {
                peopleNameSelected = people.nameFr;
                refreshMarker(people.nameFr);
              });
            },
            icon: selectedNamePeople == people.nameFr
                ? currentIconBig
                : currentIcon,
          );
          mapMarkers.add(mapMarker);
        } else if (people.situation == "F" && people.group != null) {
          if (people.group == "C") {
            currentIcon = weakPeoplesNationIcon;
            currentIconBig = weakPeoplesNationIconBig;
          } else if (people.group == "G") {
            currentIcon = weakPeoplesGroupIcon;
            currentIconBig = weakPeoplesGroupIconBig;
          } else if (people.group == "P") {
            currentIcon = weakPeoplesIcon;
            currentIconBig = weakPeoplesIconBig;
          }
          MapMarker mapMarker = MapMarker(
            id: people.coordinatesLatLng.toString(),
            position: people.coordinatesLatLng!,
            onTap: () {
              setState(() {
                peopleNameSelected = people.nameFr;
                refreshMarker(people.nameFr);
              });
            },
            icon: selectedNamePeople == people.nameFr
                ? currentIconBig
                : currentIcon,
          );
          mapMarkers.add(mapMarker);
        } else if (people.situation == "D" && people.group != null) {
          if (people.group == "G") {
            currentIcon = deadPeoplesGroupIcon;
            currentIconBig = deadPeoplesGroupIconBig;
          } else if (people.group == "P") {
            currentIcon = deadPeoplesIcon;
            currentIconBig = deadPeoplesIconBig;
          }
          MapMarker mapMarker = MapMarker(
            id: people.coordinatesLatLng.toString(),
            position: people.coordinatesLatLng!,
            onTap: () {
              setState(() {
                peopleNameSelected = people.nameFr;
                refreshMarker(people.nameFr);
              });
            },
            icon: selectedNamePeople == people.nameFr
                ? currentIconBig
                : currentIcon,
          );
          mapMarkers.add(mapMarker);
        }
      }
    }
    _clusterManager = await MapHelper.initClusterManager(
      mapMarkers,
      _minClusterZoom,
      _maxClusterZoom,
    );

    await updateMarkersAfterCheck();
  }

  Future<void> updateMarkersAfterCheck([double? updatedZoom]) async {
    if (_clusterManager == null || updatedZoom == _currentZoom) return;
    if (updatedZoom != null) {
      _currentZoom = updatedZoom;
    }

    setState(() {
      _areMarkersLoading = true;
    });

    final updatedMarkers = await MapHelper.getClusterMarkers(_clusterManager,
        _currentZoom, _clusterColor, _clusterTextColor, 100, onTapCluster);

    markers
      ..clear()
      ..addAll(updatedMarkers);

    setState(() {
      _areMarkersLoading = false;
    });
  }

  Future<void> _updateMarkers([double? updatedZoom]) async {
    if (_clusterManager == null || updatedZoom == _currentZoom) return;
    if (updatedZoom != null) {
      if (updateZoomChangeCategory(updatedZoom)) {
        await updateMarkersAfterCheck(updatedZoom);
      }
    }
  }

  bool updateZoomChangeCategory(double updatedZoom) =>
      (updatedZoom > _currentZoom + 0.5 || updatedZoom < _currentZoom - 0.5);

  void onTapCluster() {
    setState(() {
      _mapController.animateCamera(CameraUpdate.zoomBy(1));
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: GFAppBar(
          backgroundColor: const Color.fromARGB(255, 32, 69, 129),
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
          alignment: AlignmentDirectional.bottomCenter,
          children: [
            Opacity(
              opacity: _isMapLoading ? 1 : 0,
              child: const Center(child: CircularProgressIndicator()),
            ),
            GoogleMap(
                compassEnabled: false,
                rotateGesturesEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                initialCameraPosition: CameraPosition(
                  target: currentContinentCoordinated,
                  zoom: _currentZoom,
                ),
                markers: markers,
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                  _mapController.setMapStyle(_mapStyle);
                },
                onCameraMove: (position) => _updateMarkers(position.zoom)),
            AnimatedPositioned(
              bottom: pinPillPositionCardPeopleToFind,
              right: 0,
              left: 0,
              duration: const Duration(milliseconds: 200),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  margin: const EdgeInsets.all(30),
                  height: 180,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.all(Radius.circular(20)),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                            blurRadius: 20,
                            offset: Offset.zero,
                            color: Colors.grey.withOpacity(0.5))
                      ]),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Flexible(
                          child: Container(
                            margin: const EdgeInsets.only(
                                left: 10, right: 10, top: 5, bottom: 5),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text(peopleToFind.nameFr,
                                    overflow: TextOverflow.clip,
                                    style: TextStyle(
                                        color: _mainColor,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),
                                const Padding(
                                    padding:
                                        EdgeInsetsDirectional.only(top: 8)),
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Text(peopleToFind.quizText!,
                                        overflow: TextOverflow.clip,
                                        softWrap: true,
                                        style: const TextStyle(
                                            fontSize: 16, color: Colors.grey)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ]),
                ),
              ),
            ),
            AnimatedPositioned(
              bottom: pinPillPositionSuccess,
              right: 0,
              left: 0,
              duration: const Duration(milliseconds: 200),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 180,
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
                          child: Icon(Icons.check_circle, color: Colors.green),
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
                  height: 180,
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
                    ],
                  ),
                ),
              ),
            ),
            Padding(
                padding: const EdgeInsetsDirectional.only(bottom: 16.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      textStyle: const TextStyle(fontSize: 20),
                      backgroundColor: validateColor,
                      fixedSize: const Size(280, 50)),
                  onPressed: () {
                    setState(() {
                      if (buttonValidateContinue == "Continuer") {
                        if (lifePoint <= 0) {
                          showAlertDialog(context);
                        } else {
                          goToNextActivity();
                        }
                      } else {
                        if(peopleNameSelected != ""){
                          if (lifePoint <= 0) {
                            showAlertDialog(context);
                          } else {
                            if (peopleNameSelected == peopleToFind.nameFr) {
                              pinPillPositionSuccess = -50;
                              pinPillPositionCardPeopleToFind = 140;
                              progressBarPercentage += 0.1;
                            } else {
                              pinPillPositionFailed = -50;
                              pinPillPositionCardPeopleToFind = 140;
                              lifePoint -= 1;
                              validateColor = Colors.red;
                              _mapController.animateCamera(
                                  CameraUpdate.newLatLngZoom(
                                      peopleToFind.coordinatesLatLng!, 7));
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
                )),
          ],
        ),
      ),
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
              builder: (context) => QuizzByDescription(
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
