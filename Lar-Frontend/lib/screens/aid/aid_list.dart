import 'package:flutter/material.dart';

class AidListScreen extends StatelessWidget {
  const AidListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Aid Programs')),
      body: Center(child: Text('List of Aid Programs will appear here')),
    );
  }
}
