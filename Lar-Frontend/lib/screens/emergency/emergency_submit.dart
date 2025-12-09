import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/emergency_provider.dart';

class EmergencySubmitScreen extends StatefulWidget {
  @override
  _EmergencySubmitScreenState createState() => _EmergencySubmitScreenState();
}

class _EmergencySubmitScreenState extends State<EmergencySubmitScreen> {
  final _typeController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EmergencyProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Submit Emergency Report')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _typeController, decoration: InputDecoration(labelText: 'Incident Type')),
            TextField(controller: _locationController, decoration: InputDecoration(labelText: 'Location')),
            TextField(controller: _descriptionController, decoration: InputDecoration(labelText: 'Description')),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: provider.isLoading
                  ? null
                  : () async {
                      bool success = await provider.submitEmergency({
                        'incident_type': _typeController.text,
                        'incident_location': _locationController.text,
                        'description': _descriptionController.text,
                      });
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submitted successfully')));
                        Navigator.pop(context);
                      }
                    },
              child: provider.isLoading ? CircularProgressIndicator() : Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
