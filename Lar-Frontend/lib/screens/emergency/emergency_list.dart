ListView.builder(
  itemCount: emergencyProvider.reports.length,
  itemBuilder: (context, index) {
    final report = emergencyProvider.reports[index];
    return ListTile(
      title: Text(report.incidentType),
      subtitle: Text(report.incidentLocation),
      trailing: Text(report.status),
    );
  },
)
