import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:earth_is_the_best/Map/MapScreen.dart';
import 'package:earth_is_the_best/Quizz/QuizzPage.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'About/AboutPage.dart';
import 'model/People.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.selectedIndex}) : super(key: key);

  final int selectedIndex;

  @override
  State<StatefulWidget> createState() {
    return MyHomePageState(this.selectedIndex);
  }
}

class MyHomePageState extends State<MyHomePage> {
  MyHomePageState(this.selectedIndex);

  int selectedIndex;
  late Widget _mapScreenPage;
  final Widget _aboutPage = AboutPage();
  late Widget _quizzPage;

  final Color _mainColor = const Color.fromARGB(255, 47, 85, 151);

  bool _isLoadingPeople = false;
  List<People> peoplesLoaded = [];

  final CollectionReference _collectionRef =
      FirebaseFirestore.instance.collection('Peoples_updated');

  @override
  void initState() {
    // updateAllPeoples();
    // refreshPeoples();
    // DeleteDocs();
    // UpdateDocs();
    _mapScreenPage = MapScreen();
    _quizzPage = QuizzPage();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async => false,
      child: Scaffold(
      body: getBody(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: selectedIndex,
        backgroundColor: _mainColor,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54.withOpacity(0.60),
        selectedFontSize: 14,
        unselectedFontSize: 14,
        onTap: (value) {
          // Respond to item press.
          setState(() => selectedIndex = value);
        },
        items: const [
          BottomNavigationBarItem(
            label: 'Carte',
            icon: Icon(Icons.home),
          ),
          BottomNavigationBarItem(
            label: 'Jouer',
            icon: Icon(Icons.games),
          ),
          // BottomNavigationBarItem(
          //   label: 'Compte',
          //   icon: Icon(Icons.account_balance),
          // ),
          BottomNavigationBarItem(
            label: 'A propos',
            icon: Icon(Icons.book),
          ),
        ],
      ),
    ));
  }

  Widget getBody() {
    if (selectedIndex == 0) {
      return _mapScreenPage;
    } else if (selectedIndex == 1) {
      return _quizzPage;
    } else {
      return _aboutPage;
    }
  }

  void onTapHandler(int index) {
    setState(() {
      selectedIndex = index;
    });
  }


  //A executer avec des fichier excel contenant une seul table
  // Future<void> refreshPeoples() async {
  //   setState(() => _isLoadingPeople = true);
  //   ByteData data = await rootBundle.load("assets/style/oceanie_v2.xlsx");
  //   var bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  //   var excel = Excel.decodeBytes(bytes);
  //
  //   for (var table in excel.tables.keys) {
  //     print(table); //sheet Name
  //     print(excel.tables[table]?.maxCols);
  //     print(excel.tables[table]?.maxRows);
  //     List<List>? rows = excel.tables[table]?.rows;
  //     for (var row in rows!) {
  //       People people = People(nameFr: '');
  //       for (var element in row) {
  //         if (element != null && element.rowIndex != 0) {
  //           // if (element.colIndex == 0) {
  //           //   people.quizText = element.value.toString();
  //           // }
  //           if (element.colIndex == 0) {
  //             people.nameEng = element.value.toString();
  //           }
  //           if (element.colIndex == 1) {
  //             people.nameFr = element.value.toString();
  //           }
  //           if (element.colIndex == 2) {
  //             people.descriptionEng = element.value.toString();
  //           }
  //           if (element.colIndex == 3) {
  //             people.descriptionFr = element.value.toString();
  //           }
  //           if (element.colIndex == 4) {
  //             String situation = element.value.toString();
  //             people.situation = situation;
  //             if (situation == "A") {
  //               people.color = Colors.blue;
  //             } else if (situation == "D") {
  //               people.color = Colors.black;
  //             } else if (situation == "F") {
  //               people.color = Colors.orange;
  //             }
  //           }
  //           if (element.colIndex == 5) {
  //             people.group = element.value.toString();
  //           }
  //           if (element.colIndex == 6) {
  //             people.linkEng = element.value.toString();
  //           }
  //           if (element.colIndex == 7) {
  //             people.linkFr = element.value.toString();
  //           }
  //           if (element.colIndex == 8 && (element.value.toString() != "" || element.value != null)) {
  //             var value = element.value.toString();
  //             double lat = double.parse(value.split(',').first);
  //             double lng = double.parse(value.split(',').last);
  //             LatLng latLng = LatLng(lat, lng);
  //             people.coordinatesLatLng = latLng;
  //           }
  //           if (element.colIndex == 9) {
  //             people.reference = element.value.toString();
  //             peoplesLoaded.add(people);
  //           }
  //           if (element.colIndex == 10 && (element.value.toString() != "" || element.value != null)) {
  //             peoplesLoaded.last.quizText = element.value.toString();
  //           }
  //         }
  //         // if(element == null){
  //         //   print("null cell");
  //         // }
  //       }
  //     }
  //   }
  //
  //   for (People people in peoplesLoaded) {
  //     if (people.coordinatesLatLng != null) {
  //       GeoPoint coordinates = GeoPoint(people.coordinatesLatLng!.latitude,
  //           people.coordinatesLatLng!.longitude);
  //       await _collectionRef.add({
  //         'nameFr': people.nameFr,
  //         'nameEng': people.nameEng,
  //         'descriptionEng': people.descriptionEng,
  //         'descriptionFr': people.descriptionFr,
  //         'quizText': people.quizText,
  //         'situation': people.situation,
  //         'group': people.group,
  //         'linkEng': people.linkEng,
  //         'linkFr': people.linkFr,
  //         'coordinates': coordinates,
  //         'reference': people.reference,
  //       }).catchError((error) => print("Failed to add people: $error"));
  //     }
  //   }
  //   print("loading down");
  //
  //   setState(() => _isLoadingPeople = false);
  // }

  // Future<void> DeleteDocs() async {
  //   await _collectionRef.where('reference', isEqualTo: 'ASIE').get().then(
  //       (QuerySnapshot querySnapshot) => querySnapshot.docs.forEach((doc) {
  //             _collectionRef.doc(doc.id).delete();
  //           }));
  //   print("delete down");
  // }

  //A executer avec des fichier excel contenant une seul table
  // Future<void> updateAllPeoples() async {
  //   setState(() => _isLoadingPeople = true);
  //   ByteData data = await rootBundle.load("assets/style/oceanie.xlsx");
  //   var bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  //   var excel = Excel.decodeBytes(bytes);
  //
  //   for (var table in excel.tables.keys) {
  //     // print(table); //sheet Name
  //     List<List>? rows = excel.tables[table]?.rows;
  //     for (var row in rows!) {
  //       People people = People(nameFr: '');
  //       for (var element in row) {
  //         if (element != null && element.rowIndex != 0) {
  //           // if (element.colIndex == 0) {
  //           //   people.quizText = element.value.toString();
  //           // }
  //           if (element.colIndex == 0) {
  //             people.nameEng = element.value.toString();
  //           }
  //           if (element.colIndex == 1) {
  //             people.nameFr = element.value.toString();
  //           }
  //           if (element.colIndex == 2) {
  //             people.descriptionEng = element.value.toString();
  //           }
  //           if (element.colIndex == 3) {
  //             people.descriptionFr = element.value.toString();
  //           }
  //           if (element.colIndex == 4) {
  //             String situation = element.value.toString();
  //             people.situation = situation;
  //             if (situation == "A") {
  //               people.color = Colors.blue;
  //             } else if (situation == "D") {
  //               people.color = Colors.black;
  //             } else if (situation == "F") {
  //               people.color = Colors.orange;
  //             }
  //           }
  //           if (element.colIndex == 5) {
  //             people.group = element.value.toString();
  //           }
  //           if (element.colIndex == 6) {
  //             people.linkEng = element.value.toString();
  //           }
  //           if (element.colIndex == 7) {
  //             people.linkFr = element.value.toString();
  //           }
  //           if (element.colIndex == 8 && (element.value.toString() != "" || element.value != null)) {
  //             var value = element.value.toString();
  //             double lat = double.parse(value.split(',').first);
  //             double lng = double.parse(value.split(',').last);
  //             LatLng latLng = LatLng(lat, lng);
  //             people.coordinatesLatLng = latLng;
  //           }
  //           if (element.colIndex == 9) {
  //             people.reference = element.value.toString();
  //             peoplesLoaded.add(people);
  //           }
  //           if (element.colIndex == 10 && (element.value.toString() != "" || element.value != null)) {
  //             peoplesLoaded.last.quizText = element.value.toString();
  //           }
  //         }
  //         // if(element == null){
  //         //   print("null cell");
  //         // }
  //       }
  //     }
  //   }
  //
  //   for (People people in peoplesLoaded) {
  //     if (people.coordinatesLatLng != null) {
  //       GeoPoint coordinates = GeoPoint(people.coordinatesLatLng!.latitude,
  //           people.coordinatesLatLng!.longitude);
  //
  //       await _collectionRef
  //           .where('nameFr', isEqualTo: people.nameFr)
  //           .where('reference', isEqualTo: people.reference)
  //           .get()
  //           .then((QuerySnapshot querySnapshot) =>
  //           querySnapshot.docs.forEach((doc) {
  //             _collectionRef
  //                 .doc(doc.id)
  //                 .update({
  //               'nameEng': people.nameEng,
  //               'descriptionEng': people.descriptionEng,
  //               'descriptionFr': people.descriptionFr,
  //               'quizText': people.quizText,
  //               'situation': people.situation,
  //               'group': people.group,
  //               'linkEng': people.linkEng,
  //               'linkFr': people.linkFr,
  //               'coordinates': coordinates,
  //             })
  //                 .then((value) => print("People Updated"))
  //                 .catchError((error) =>
  //                 print("Failed to update people: $error"));
  //           }));
  //     }
  //   }
  //   print("update down");
  //
  //   setState(() => _isLoadingPeople = false);
  // }
}
