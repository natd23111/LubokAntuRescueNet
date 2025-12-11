import 'package:flutter/material.dart';
import '../../models/aid_program.dart';
import 'add_aid_program_form.dart';

class ManageAidProgramsScreen extends StatefulWidget {
  const ManageAidProgramsScreen({Key? key}) : super(key: key);

  @override
  State<ManageAidProgramsScreen> createState() => _ManageAidProgramsScreenState();
}

class _ManageAidProgramsScreenState extends State<ManageAidProgramsScreen> {
  bool _showAddForm = false;

  // Sample data - replace with API call
  final List<AidProgram> _programs = [
    AidProgram(
      id: 'AID001',
      title: 'B40 Financial Assistance 2025',
      category: 'financial',
      status: 'active',
      startDate: DateTime(2025, 1, 1),
      endDate: DateTime(2025, 12, 31),
    ),
    AidProgram(
      id: 'AID002',
      title: 'Disaster Relief Fund',
      category: 'disaster',
      status: 'active',
      startDate: DateTime(2024, 11, 1),
      endDate: DateTime(2025, 12, 31),
    ),
    AidProgram(
      id: 'AID003',
      title: 'Medical Emergency Fund',
      category: 'medical',
      status: 'active',
      startDate: DateTime(2025, 1, 1),
      endDate: DateTime(2025, 12, 31),
    ),
  ];

  void _handleAddProgram(AidProgram program) {
    setState(() {
      _programs.add(program);
      _showAddForm = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Program Added Successfully!'),
        backgroundColor: Colors.green[600],
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _handleEditProgram(int index) {
    // TODO: Implement edit functionality
  }

  void _handleViewDetails(int index) {
    // TODO: Implement view details functionality
  }

  String _getCategoryColor(String category) {
    switch (category) {
      case 'financial':
        return '#0E9D63';
      case 'disaster':
        return '#FF6B6B';
      case 'medical':
        return '#4ECDC4';
      case 'education':
        return '#FFE66D';
      case 'housing':
        return '#A8E6CF';
      default:
        return '#0E9D63';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_monthName(date.month)}, ${date.year}';
  }

  String _monthName(int month) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    if (_showAddForm) {
      return AddAidProgramForm(
        onBack: () => setState(() => _showAddForm = false),
        onSubmit: _handleAddProgram,
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E9D63),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Aid Programs',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // Add Program Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _showAddForm = true),
                icon: const Icon(Icons.add),
                label: const Text('Add New Aid Program'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0E9D63),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),

          // Programs List
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      '${_programs.length} active program(s)',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _programs.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final program = _programs[index];
                      return _buildProgramCard(program, index);
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Back Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Back',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramCard(AidProgram program, int index) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      program.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${program.id}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E9D63).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  program.status.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0E9D63),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Category and Duration
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Category: ${_formatCategoryName(program.category)}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Duration: ${_formatDate(program.startDate)} - ${_formatDate(program.endDate)}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    onPressed: () => _handleEditProgram(index),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      side: const BorderSide(color: Color(0xFF0E9D63)),
                    ),
                    child: const Text(
                      'Edit',
                      style: TextStyle(
                        color: Color(0xFF0E9D63),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    onPressed: () => _handleViewDetails(index),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      'View Details',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCategoryName(String category) {
    switch (category) {
      case 'financial':
        return 'Financial Aid';
      case 'disaster':
        return 'Disaster Relief';
      case 'medical':
        return 'Medical Emergency';
      case 'education':
        return 'Education Aid';
      case 'housing':
        return 'Housing Assistance';
      default:
        return category;
    }
  }
}
