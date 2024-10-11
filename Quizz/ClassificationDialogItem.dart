import 'package:flutter/material.dart';

class ClassificationDialogItem extends StatelessWidget {
  const ClassificationDialogItem(
      {Key? key,
        required this.imageUrl,
        required this.text})
      : super(key: key);

  final String imageUrl;
  final String text;

  @override
  Widget build(BuildContext context) {
    return SimpleDialogOption(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipOval(
            child: SizedBox.fromSize(
              size: Size.fromRadius(20), // Image radius
              child: Image.network(imageUrl, fit: BoxFit.cover),
            ),
          ),
          // Image.network(imageUrl, width: 30),
          const Padding(padding: EdgeInsetsDirectional.only(start: 16.0)),
          Expanded(
            child: Text(text,
                overflow: TextOverflow.clip,
                softWrap: true,
                style: const TextStyle(fontSize: 16, color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
