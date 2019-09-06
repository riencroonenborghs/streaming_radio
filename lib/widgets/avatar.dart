import "package:flutter/material.dart";

class Avatar extends StatefulWidget {
  final String name;

  Avatar({Key key, @required this.name}) : super(key: key);

  @override
  _AvatarState createState() => _AvatarState();
}

class _AvatarState extends State<Avatar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48.0,
      height: 48.0,
      margin: EdgeInsets.all(0.0),
      decoration: new BoxDecoration(
        color: Theme.of(context).primaryColor,
        shape: BoxShape.circle,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget> [
          Text(
            widget.name.substring(0, 1),
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 24)
          )
        ]
      )
    );
  }
}
