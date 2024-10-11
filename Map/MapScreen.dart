import 'dart:core';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:earth_is_the_best/model/People.dart';
import 'package:fluster/fluster.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:getwidget/components/dropdown/gf_dropdown.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Quizz/QuizzPage.dart';
import 'SimpleDialogItem.dart';
import 'MapHelper.dart';
import 'MapMarker.dart';

class MapScreen extends StatefulWidget {
  // const MapScreen({Key? key, required this.peoples}) : super(key: key);
  const MapScreen({Key? key}) : super(key: key);

  // final List<People> peoples;


  // _MapScreenState createState() => _MapScreenState(peoples);
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // _MapScreenState(List<People> peoplesLoaded) {
  //   peoples = peoplesLoaded;
  // }

  final CollectionReference _collectionRef =
  FirebaseFirestore.instance.collection('Peoples_updated');


  _MapScreenState();

  late List<People> peoples = [];
  late List<String> peoplesName = [];

  // bool isLoading = false;
  Set<Marker> markers = {};

  // final Completer<GoogleMapController> _mapController = Completer();
  late GoogleMapController _mapController;
  String _mapStyle = "";

  /// Minimum zoom at which the markers will cluster
  final int _minClusterZoom = 0;

  /// Maximum zoom at which the markers will cluster
  final int _maxClusterZoom = 19;

  /// [Fluster] instance used to manage the clusters
  Fluster<MapMarker>? _clusterManager;

  /// Current map zoom. Initial zoom will be 15, street level
  double _currentZoom = 4;

  /// Map loading flag
  bool _isMapLoading = true;

  /// Markers loading flag
  bool _areMarkersLoading = true;

  /// Color of the cluster circle
  final Color _clusterColor = const Color.fromARGB(153, 110, 204, 57);

  final Color _linkColor = const Color.fromARGB(255, 0, 120, 168);

  /// Color of the cluster text
  final Color _clusterTextColor = Colors.white;

  late BitmapDescriptor actualPeoplesIcon;
  late BitmapDescriptor weakPeoplesIcon;
  late BitmapDescriptor deadPeoplesIcon;
  late BitmapDescriptor actualPeoplesGroupIcon;
  late BitmapDescriptor actualPeoplesNationIcon;
  late BitmapDescriptor weakPeoplesNationIcon;
  late BitmapDescriptor weakPeoplesGroupIcon;
  late BitmapDescriptor deadPeoplesGroupIcon;

  late BitmapDescriptor currentIcon;
  String currentNamePeople = "";
  String currentDescriptionPeople = "";
  String currentLink = "";
  Color currentColor = Colors.black;
  final isSelected = <bool>[true, false, false];

  final isContinentsSelected = <bool>[true, false, false, false, false, false];
  List<Continent> continents = <Continent>[
    Continent("Europe","EUR", const LatLng(47.551386, 16.753688),0),
    Continent("Afrique","AFR", const LatLng(-9.364745, 16.584908),0),
    Continent("Amériques","AM",const LatLng(10.970590, -74.671464),0),
    Continent("Asie","ASIE",const LatLng(9.929740, 105.413515),0),
    Continent("Océanie","OCE", const LatLng(-34.097509, 144.096631),0),
    Continent("Pays","PAYS", const LatLng(47.551386, 16.753688),0)];
  List<String> continentsDropDown = <String>[ "Europe","Afrique","Amériques","Asie","Océanie", "Pays"];
  String continentValue = 'Europe';

  final Color _mainColor = const Color.fromARGB(255, 47, 85, 151);

  double pinPillPosition = -250;

  late FloatingSearchBarController controller;
  late List<String> filteredSearchHistory = [];
  int historyLength = 0;
  late String selectedTerm = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
      alignment: AlignmentDirectional.bottomStart,
      children: <Widget>[
        GoogleMap(
          compassEnabled: false,
          rotateGesturesEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          initialCameraPosition: CameraPosition(
            target: const LatLng(48.856614, 2.3522219),
            zoom: _currentZoom,
          ),
          markers: markers,
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
            _mapController.setMapStyle(_mapStyle);
          },
          onCameraMove: (position) => _updateMarkers(position.zoom),
          onTap: (LatLng location) {
            setState(() {
              pinPillPosition = -250;
            });
          },
        ),
        Opacity(
          opacity: _isMapLoading ? 1 : 0,
          child: const Center(child: CircularProgressIndicator()),
        ),
        AnimatedPositioned(
          bottom: pinPillPosition,
          right: 0,
          left: 0,
          duration: const Duration(milliseconds: 200),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(10),
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
                            Text(currentNamePeople,
                                overflow: TextOverflow.clip,
                                style: TextStyle(
                                    color: currentColor, fontSize: 20)),
                            const Padding(
                                padding: EdgeInsetsDirectional.only(top: 8)),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Text(currentDescriptionPeople,
                                    overflow: TextOverflow.clip,
                                    softWrap: true,
                                    style: const TextStyle(
                                        fontSize: 16, color: Colors.grey)),
                              ),
                            ),
                            const Padding(
                                padding: EdgeInsetsDirectional.only(top: 8)),
                            Row(
                              children: [
                                Icon(
                                  Icons.ads_click,
                                  color: _linkColor,
                                  size: 20,
                                ),
                                const Padding(
                                    padding:
                                        EdgeInsetsDirectional.only(end: 6)),
                                InkWell(
                                    child: Text('Source wiki',
                                        style: TextStyle(
                                            color: _linkColor, fontSize: 16)),
                                    onTap: () =>
                                        launchUrl(Uri.parse(currentLink))),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ]),
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).viewPadding.top + 86,
          left: 0,
          right: 0,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Container(
                //   height: 35,
                //   padding: EdgeInsets.zero,
                //   decoration: BoxDecoration(
                //     borderRadius: BorderRadius.circular(50),
                //     color: Colors.white,
                //   ),
                //   child: ToggleButtons(
                //     color: Colors.black,
                //     selectedColor: Colors.blue,
                //     selectedBorderColor: Colors.blue,
                //     fillColor: Colors.white,
                //     splashColor: Colors.blue.withOpacity(0.12),
                //     hoverColor: Colors.blue.withOpacity(0.04),
                //     borderRadius: BorderRadius.circular(50),
                //     constraints: const BoxConstraints(minHeight: 36.0),
                //     isSelected: isContinentsSelected,
                //     onPressed: (index) {
                //       setState(() {
                //         isContinentsSelected[index] = !isContinentsSelected[index];
                //         refreshMarker();
                //       });
                //     },
                //     children: const [
                //       Padding(
                //         padding: EdgeInsets.symmetric(horizontal: 16.0),
                //         child: Text('eur'),
                //       ),
                //       Padding(
                //         padding: EdgeInsets.symmetric(horizontal: 16.0),
                //         child: Text('am'),
                //       ),
                //       Padding(
                //         padding: EdgeInsets.symmetric(horizontal: 16.0),
                //         child: Text('oce'),
                //       ),
                //       Padding(
                //         padding: EdgeInsets.symmetric(horizontal: 16.0),
                //         child: Text('afr'),
                //       ),
                //       Padding(
                //         padding: EdgeInsets.symmetric(horizontal: 16.0),
                //         child: Text('asie'),
                //       ),
                //       Padding(
                //         padding: EdgeInsets.symmetric(horizontal: 16.0),
                //         child: Text('pays'),
                //       ),
                //     ],
                //   ),
                // ),
                Container(
                  height: 40,
                  width: 260,
                  margin: const EdgeInsets.all(20),
                  child: DropdownButtonHideUnderline(
                    child: GFDropdown(
                      padding: const EdgeInsets.only(left: 15),
                      borderRadius: BorderRadius.circular(5),
                      border: const BorderSide(
                          color: Colors.black12, width: 1),
                      dropdownButtonColor: Colors.white,
                      value: continentValue,
                      onChanged: (newValue) {
                        setState(() {
                          continentValue = newValue.toString();
                          refreshMarker();
                          _mapController.animateCamera(
                              CameraUpdate.newLatLngZoom(
                                  continents.where((element) => element.name==continentValue).first.coordinates, 3));
                        });
                      },
                      items: continentsDropDown
                          .map((value) => DropdownMenuItem(
                        value: value,
                        child: Text(value, style: TextStyle(color: _mainColor, fontSize: 18)),
                      ))
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).viewPadding.top + 56,
          left: 0,
          right: 0,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 35,
                  padding: EdgeInsets.zero,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color: Colors.white,
                  ),
                  child: ToggleButtons(
                    color: Colors.black,
                    selectedColor: Colors.blue,
                    selectedBorderColor: Colors.blue,
                    fillColor: Colors.white,
                    splashColor: Colors.blue.withOpacity(0.12),
                    hoverColor: Colors.blue.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(50),
                    constraints: const BoxConstraints(minHeight: 36.0),
                    isSelected: isSelected,
                    onPressed: (index) {
                      setState((){
                        isSelected[index] = !isSelected[index];
                        refreshMarker();
                      });
                    },
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text('Actuel'),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text('Fragile'),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text('Eteint'),
                      ),
                    ],
                  ),
                ),
                TextButton(
                    onPressed: () {
                      showAlertDialog(context);
                    },
                    child: const Icon(
                      Icons.info,
                      size: 34,
                    ))
              ],
            ),
          ),
        ),
        FloatingSearchBar(
          borderRadius: BorderRadius.circular(50),
          controller: controller,
          transition: CircularFloatingSearchBarTransition(),
          physics: const BouncingScrollPhysics(),
          title: Text(
            selectedTerm,
            style: Theme.of(context).textTheme.headline6,
          ),
          hint: 'Rechercher un peuple',
          actions: [
            FloatingSearchBarAction.searchToClear(),
          ],
          onQueryChanged: (query) {
            setState(() {
              filteredSearchHistory = filterSearchTerms(filter: query);
            });
          },
          onSubmitted: (query) {
            setState(() {
              selectedTerm = query;
            });
            controller.close();
          },
          builder: (context, transition) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Material(
                color: Colors.white,
                elevation: 4,
                child: Builder(
                  builder: (context) {
                    if (filteredSearchHistory.isEmpty &&
                        controller.query.isEmpty) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: peoplesName
                            .map(
                              (term) => ListTile(
                                title: Text(
                                  term,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                leading: const Icon(Icons.people),
                                onTap: () {
                                  setState(() {
                                    putSearchTermFirst(term);
                                    selectedTerm = term;
                                    pinPillPosition = 0;
                                    People people =
                                        getPeopleByName(selectedTerm);
                                    currentDescriptionPeople =
                                        people.descriptionFr!;
                                    currentNamePeople = people.nameFr;
                                    currentLink = people.linkFr!;
                                    currentColor = Colors.blue;
                                    _mapController.animateCamera(
                                        CameraUpdate.newLatLngZoom(
                                            people.coordinatesLatLng!, 6));
                                  });
                                  controller.close();
                                },
                              ),
                            )
                            .toList(),
                      );
                    } else if (filteredSearchHistory.isEmpty) {
                      return ListTile(
                        title: Text(controller.query),
                        leading: const Icon(Icons.people),
                        onTap: () {
                          setState(() {
                            // addSearchTerm(controller.query);
                            selectedTerm = controller.query;
                          });
                          controller.close();
                        },
                      );
                    } else {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: filteredSearchHistory
                            .map(
                              (term) => ListTile(
                                title: Text(
                                  term,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                leading: const Icon(Icons.people),
                                onTap: () {
                                  setState(() {
                                    putSearchTermFirst(term);
                                    selectedTerm = term;
                                    pinPillPosition = 0;
                                    People people =
                                        getPeopleByName(selectedTerm);
                                    currentDescriptionPeople =
                                        people.descriptionFr!;
                                    currentNamePeople = people.nameFr;
                                    currentLink = people.linkFr!;
                                    currentColor = people.color!;
                                    _mapController.animateCamera(
                                        CameraUpdate.newLatLngZoom(
                                            people.coordinatesLatLng!, 6));
                                  });
                                  controller.close();
                                },
                              ),
                            )
                            .toList(),
                      );
                    }
                  },
                ),
              ),
            );
          },
        ),
      ],
    ));
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    controller = FloatingSearchBarController();
    filteredSearchHistory = filterSearchTerms(filter: "");
    initPeople();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      rootBundle.loadString("assets/style/map_style.txt").then((string) {
        _mapStyle = string;
      });
    });
  }

  void initPeople() async {
    setState(() => _isMapLoading = true);

    // await getData();
    await initIcon();
    await refreshMarker();

    historyLength = peoplesName.length;

    setState(() => _isMapLoading = false);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> getData() async {

    peoples.clear();
    peoplesName.clear();

    await _collectionRef
    .where('reference', isEqualTo: continents.where((element) => element.name==continentValue).first.reference)
    // .where('situation', isEqualTo: 'D')
        .get()
        .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) {
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
          coordinatesLatLng: LatLng(coordinates.latitude, coordinates.longitude),
          reference: doc['reference'],
          // quizText: doc['quizText'],
          color: peopleTypeColor,
        );
        peoples.add(people);
        peoplesName.add(doc['nameFr']);
      });
    });
  }

  List<String> filterSearchTerms({
    required String filter,
  }) {
    if (filter.isNotEmpty) {
      return peoplesName
          .where((name) => name.toUpperCase().startsWith(filter.toUpperCase()))
          .toList();
    } else {
      return peoplesName.reversed.toList();
    }
  }

  void addSearchTerm(String term) {
    if (peoplesName.contains(term)) {
      // This method will be implemented soon
      putSearchTermFirst(term);
      return;
    }
    peoplesName.add(term);
    if (peoplesName.length > historyLength) {
      peoplesName.removeRange(0, peoplesName.length - historyLength);
    }
    // Changes in peoplesName mean that we have to update the filteredSearchHistory
    filteredSearchHistory = filterSearchTerms(filter: "");
  }

  void deleteSearchTerm(String term) {
    peoplesName.removeWhere((t) => t == term);
    filteredSearchHistory = filterSearchTerms(filter: "");
  }

  void putSearchTermFirst(String term) {
    deleteSearchTerm(term);
    addSearchTerm(term);
  }

  People getPeopleByName(String name) {
    return peoples.where((element) => element.nameFr.contains(name)).first;
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

  Future<void> initIcon() async {
    await getBytesFromAsset('assets/style/marker/iAC.png', 150).then((value) =>
        {actualPeoplesNationIcon = BitmapDescriptor.fromBytes(value!)});
    await getBytesFromAsset('assets/style/marker/iFC.png', 150).then((value) =>
    {weakPeoplesNationIcon = BitmapDescriptor.fromBytes(value!)});
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
  }

  Future<void> refreshMarker() async {
    await getData();
    final List<MapMarker> mapMarkers = [];

    // markers.clear();
    for (var people in peoples) {
      if (people.coordinatesLatLng != null) {
        if (people.situation == "A" && isSelected[0] && people.group != null) {
          if (people.group == "C") {
            currentIcon = actualPeoplesNationIcon;
          } else if (people.group == "G") {
            currentIcon = actualPeoplesGroupIcon;
          } else if (people.group == "P") {
            currentIcon = actualPeoplesIcon;
          }
          MapMarker mapMarker = MapMarker(
              id: people.coordinatesLatLng.toString(),
              position: people.coordinatesLatLng!,
              icon: currentIcon,
              onTap: () {
                setState(() {
                  pinPillPosition = 0;
                  currentDescriptionPeople = people.descriptionFr!;
                  currentNamePeople = people.nameFr;
                  currentLink = people.linkFr!;
                  currentColor = people.color!;
                });
              });
          mapMarkers.add(mapMarker);
        } else if (people.situation == "F" &&
            isSelected[1] &&
            people.group != null) {
          if (people.group == "C") {
            currentIcon = weakPeoplesNationIcon;
          }
          else if (people.group == "G") {
            currentIcon = weakPeoplesGroupIcon;
          } else if (people.group == "P") {
            currentIcon = weakPeoplesIcon;
          }
          MapMarker mapMarker = MapMarker(
              id: people.coordinatesLatLng.toString(),
              position: people.coordinatesLatLng!,
              icon: currentIcon,
              onTap: () {
                setState(() {
                  pinPillPosition = 0;
                  currentDescriptionPeople = people.descriptionFr!;
                  currentNamePeople = people.nameFr;
                  currentLink = people.linkFr!;
                  currentColor = people.color!;
                });
              });
          mapMarkers.add(mapMarker);
        } else if (people.situation == "D" &&
            isSelected[2] &&
            people.group != null) {
          if (people.group == "G") {
            currentIcon = deadPeoplesGroupIcon;
          } else if (people.group == "P") {
            currentIcon = deadPeoplesIcon;
          }
          MapMarker mapMarker = MapMarker(
              id: people.coordinatesLatLng.toString(),
              position: people.coordinatesLatLng!,
              icon: currentIcon,
              onTap: () {
                setState(() {
                  pinPillPosition = 0;
                  currentDescriptionPeople = people.descriptionFr!;
                  currentNamePeople = people.nameFr;
                  currentLink = people.linkFr!;
                  currentColor = people.color!;
                });
              });
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

  Future<void> _updateMarkers([double? updatedZoom]) async {
    if (_clusterManager == null || updatedZoom == _currentZoom) return;
    if (updatedZoom != null) {
      if (updateZoomChangeCategory(updatedZoom)) {
        await updateMarkersAfterCheck(updatedZoom);
      }
    }
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

  bool updateZoomChangeCategory(double updatedZoom) =>
      (updatedZoom > _currentZoom + 0.5 || updatedZoom < _currentZoom - 0.5);

  void onTapCluster() {
    setState(() {
      pinPillPosition = -250;
      _mapController.animateCamera(CameraUpdate.zoomBy(1));
    });
  }

  showAlertDialog(BuildContext context) {
    // Create button
    SimpleDialog alert = const SimpleDialog(title: Text("Légende"), children: [
      SimpleDialogItem(
        icon: "assets/style/marker/iAP.png",
        iconSecond: "assets/style/marker/iFP.png",
        text: "Peuples contemporain\norange: peuple en danger",
      ),
      SimpleDialogItem(
        icon: "assets/style/marker/iAG.png",
        iconSecond: "assets/style/marker/iFG.png",
        text: "Peuples intégrant des sous groupes",
      ),
      SimpleDialogItem(
        icon: "assets/style/marker/iAC.png",
        iconSecond: "assets/style/marker/iFC.png",
        text: "Peuples relatif à un pays",
      ),
      SimpleDialogItem(
        icon: "assets/style/marker/iDP.png",
        iconSecond: "assets/style/marker/iDG.png",
        text: "Peuples et groupes disparus",
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
