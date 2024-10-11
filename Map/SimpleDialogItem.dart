import 'package:flutter/material.dart';

class SimpleDialogItem extends StatelessWidget {
  const SimpleDialogItem(
      {Key? key,
      required this.icon,
      required this.iconSecond,
      required this.text})
      : super(key: key);

  final String icon;
  final String iconSecond;
  final String text;

  @override
  Widget build(BuildContext context) {
    return SimpleDialogOption(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(icon, width: 30),
          Image.asset(iconSecond, width: 30),
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
