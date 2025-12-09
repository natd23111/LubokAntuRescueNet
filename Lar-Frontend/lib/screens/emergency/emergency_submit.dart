TextFormField(controller: _typeController, decoration: InputDecoration(labelText: 'Incident Type'));
TextFormField(controller: _locationController, decoration: InputDecoration(labelText: 'Location'));
TextFormField(controller: _descriptionController, decoration: InputDecoration(labelText: 'Description'));

ElevatedButton(
  onPressed: () async {
    await emergencyProvider.submitEmergency({
      'incident_type': _typeController.text,
      'incident_location': _locationController.text,
      'description': _descriptionController.text,
    });
  },
  child: Text('Submit'),
)
