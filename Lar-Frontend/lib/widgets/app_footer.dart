import 'package:flutter/material.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: isDark ? Colors.black : Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(
            height: 16,
            thickness: 0.5,
            color: Colors.grey.withOpacity(0.3),
          ),

          // Logos
          Image.asset(
            'assets/footer_logos.png',
            height: 80,
            fit: BoxFit.contain,
          ),

          const SizedBox(height: 6),

          // Address
          Text(
            'Lubuk Antu, 95900, Sarawak',
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
