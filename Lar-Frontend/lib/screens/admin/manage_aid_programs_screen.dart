import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/aid_program.dart';
import '../../providers/aid_program_provider.dart';
import 'add_aid_program_form.dart';
import 'edit_aid_program_form.dart';

class ManageAidProgramsScreen extends StatefulWidget {
  const ManageAidProgramsScreen({Key? key}) : super(key: key);

  @override
  State<ManageAidProgramsScreen> createState() => _ManageAidProgramsScreenState();
}

class _ManageAidProgramsScreenState extends State<ManageAidProgramsScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch programs when screen loads
    Future.microtask(() {
      Provider.of<AidProgramProvider>(context, listen: false).fetchPrograms();
    });
  }

  void _handleAddProgram(AidProgram program) async {
    final provider = Provider.of<AidProgramProvider>(context, listen: false);
    final success = await provider.createProgram(program);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Program Added Successfully!'),
          backgroundColor: Colors.green[600],
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.of(context).pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to add program'),
          backgroundColor: Colors.red[600],
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _handleEditProgram(int index) {
    final programs = Provider.of<AidProgramProvider>(context, listen: false).programs;
    if (index >= 0 && index < programs.length) {
      final program = programs[index];
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => EditAidProgramForm(
            program: program,
            onBack: () => Navigator.of(context).pop(),
            onSubmit: (updatedProgram) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Program updated successfully!'),
                  backgroundColor: Colors.green[600],
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ),
      );
    }
  }

  void _handleDeleteProgram(int index) async {
    final provider = Provider.of<AidProgramProvider>(context, listen: false);
    final programs = provider.programs;
    
    if (index >= 0 && index < programs.length) {
      final program = programs[index];
      
      // Show confirmation dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Program'),
          content: Text('Are you sure you want to delete "${program.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final success = await provider.deleteProgram(program.id.toString());
                
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Program deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(provider.error ?? 'Failed to delete'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    }
  }

  void _toggleProgramStatus(int index) async {
    final provider = Provider.of<AidProgramProvider>(context, listen: false);
    final programs = provider.programs;
    
    if (index >= 0 && index < programs.length) {
      final program = programs[index];
      final success = await provider.toggleProgramStatus(program.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Program status changed to ${programs[index].status.toUpperCase()}'),
            backgroundColor: Colors.blue[600],
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Failed to toggle status'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
    return Consumer<AidProgramProvider>(
      builder: (context, provider, child) {
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
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AddAidProgramForm(
                            onBack: () => Navigator.of(context).pop(),
                            onSubmit: _handleAddProgram,
                          ),
                        ),
                      );
                    },
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
                child: provider.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0E9D63)),
                        ),
                      )
                    : provider.programs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.folder_open,
                                  size: 64,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No aid programs found',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: Text(
                                    '${provider.programs.length} active program(s)',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: provider.programs.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final program = provider.programs[index];
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
      },
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
                  color: program.status == 'active' 
                      ? const Color(0xFF0E9D63).withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  program.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: program.status == 'active' 
                        ? const Color(0xFF0E9D63)
                        : Colors.orange,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Description
          if (program.description != null && program.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                program.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
            ),

          // Duration
          Text(
            'Duration: ${_formatDate(program.startDate)} - ${_formatDate(program.endDate)}',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
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
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    onPressed: () => _toggleProgramStatus(index),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      side: BorderSide(
                        color: program.status == 'active' ? Colors.orange : Colors.green,
                      ),
                    ),
                    child: Text(
                      program.status == 'active' ? 'Deactivate' : 'Activate',
                      style: TextStyle(
                        color: program.status == 'active' ? Colors.orange : Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                height: 40,
                width: 40,
                child: OutlinedButton(
                  onPressed: () => _handleDeleteProgram(index),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    side: const BorderSide(color: Colors.red, width: 1),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Icon(
                    Icons.delete,
                    size: 18,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
