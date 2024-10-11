import 'dart:ui';

import 'package:google_maps_flutter/google_maps_flutter.dart';

class People {
  late String? nameEng;
  late String nameFr;
  late String? descriptionEng;
  late String? descriptionFr;
  late String? quizText;
  late String? situation;
  late String? group;
  late String? linkEng;
  late String? linkFr;
  late LatLng? coordinatesLatLng;
  late String? reference;
  late Color? color;

  People(
      {this.nameEng,
      required this.nameFr,
      this.descriptionEng,
      this.descriptionFr,
      this.quizText,
      this.situation,
      this.group,
      this.linkEng,
      this.linkFr,
      this.coordinatesLatLng,
      this.reference,
      this.color});
}
