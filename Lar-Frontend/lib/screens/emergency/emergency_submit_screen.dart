import 'package:flutter/material.dart';

class EmergencySubmitScreen extends StatelessWidget {
  const EmergencySubmitScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Emergency Report')),
      body: const Center(child: Text('Form goes here')),
    );
  }
}
