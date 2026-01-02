class Warning {
  final String id;
  final String type;
  final String location;
  final String severity; // high, medium, low
  final double distance; // in km
  final String description;
  final DateTime timestamp;
  final double latitude;
  final double longitude;

  Warning({
    required this.id,
    required this.type,
    required this.location,
    required this.severity,
    required this.distance,
    required this.description,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
  });

  // Calculate time ago string
  String getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return timestamp.toString().split(' ')[0];
    }
  }

  String getDistanceText() {
    if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)} m from you';
    }
    return '${distance.toStringAsFixed(1)} km from you';
  }
}
