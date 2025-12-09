import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/emergency_provider.dart';
import 'package:lar/screens/emergency/emergency_submit_screen.dart';

class EmergencyListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EmergencyProvider>(context);

    provider.fetchMyReports();

    return Scaffold(
      appBar: AppBar(title: Text('My Emergency Reports')),
      body: provider.isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: provider.reports.length,
              itemBuilder: (context, index) {
                final report = provider.reports[index];
                return Card(
                  child: ListTile(
                    title: Text(report.incidentType),
                    subtitle: Text(report.incidentLocation),
                    trailing: Text(report.status ?? 'Submitted'),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EmergencySubmitScreen())),
      ),
    );
  }
}
