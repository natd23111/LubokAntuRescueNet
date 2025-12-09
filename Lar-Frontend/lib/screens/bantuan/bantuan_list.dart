import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bantuan_provider.dart';

class BantuanListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BantuanProvider>(context);
    provider.fetchPrograms();

    return Scaffold(
      appBar: AppBar(title: Text('Bantuan Programs')),
      body: provider.isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: provider.programs.length,
              itemBuilder: (context, index) {
                final program = provider.programs[index];
                return Card(
                  child: ListTile(
                    title: Text(program.title),
                    subtitle: Text(program.description),
                    trailing: Text(program.status ?? 'Active'),
                  ),
                );
              },
            ),
    );
  }
}
