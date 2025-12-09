import 'package:flutter/material.dart';
import 'emergency/emergency_list.dart';
import 'aid/aid_list.dart';
import 'bantuan/bantuan_list.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Lubok Antu RescueNet')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          ListTile(
            title: Text('Emergency Reports'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EmergencyListScreen())),
          ),
          ListTile(
            title: Text('Aid Requests'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AidListScreen())),
          ),
          ListTile(
            title: Text('Bantuan Programs'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BantuanListScreen())),
          ),
        ],
      ),
    );
  }
}
