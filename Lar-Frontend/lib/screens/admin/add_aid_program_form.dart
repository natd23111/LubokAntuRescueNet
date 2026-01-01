import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/aid_program.dart';
import '../../providers/aid_program_provider.dart';

class AddAidProgramForm extends StatefulWidget {
  final VoidCallback onBack;
  final Function(AidProgram) onSubmit;

  const AddAidProgramForm({
    Key? key,
    required this.onBack,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<AddAidProgramForm> createState() => _AddAidProgramFormState();
}

class _AddAidProgramFormState extends State<AddAidProgramForm> {
  bool _showSuccess = false;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _aidAmountController = TextEditingController();
  final TextEditingController _eligibilityController = TextEditingController();

  String? _selectedCategory;
  String? _selectedProgramType;
  String? _selectedStatus;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _aidAmountController.dispose();
    _eligibilityController.dispose();
    super.dispose();
  }

  Future<void> selectDate(BuildContext context, bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2024),
      lastDate: DateTime(2027),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) return 'Select date';
    return '${date.day}/${date.month}/${date.year}';
  }

  void handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end dates')),
      );
      return;
    }

    if (_selectedProgramType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select program type')),
      );
      return;
    }

    if (_selectedStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select status')),
      );
      return;
    }

    setState(() => _showSuccess = true);

    Future.delayed(const Duration(seconds: 1), () async {
      if (mounted) {
        // Generate sequential program ID based on year
        final provider = context.read<AidProgramProvider>();
        final year = DateTime.now().year;
        final nextNumber = provider.programs.length + 1;
        final programId = 'AID$year${nextNumber.toString().padLeft(3, '0')}'; // AID2026001, AID2026002, etc.
        
        final newProgram = AidProgram(
          id: programId,
          title: _titleController.text,
          category: _selectedCategory ?? 'other',
          status: _selectedStatus ?? 'active',
          startDate: _startDate ?? DateTime.now(),
          endDate: _endDate ?? DateTime.now(),
          description: _descriptionController.text,
          aidAmount: _aidAmountController.text,
          eligibilityCriteria: _eligibilityController.text,
          programType: _selectedProgramType,
        );

        // Save to Firebase
        final success = await provider.addAidProgram(newProgram);

        if (success) {
          // Clear form
          _titleController.clear();
          _descriptionController.clear();
          _aidAmountController.clear();
          _eligibilityController.clear();
          
          setState(() {
            _selectedCategory = null;
            _selectedProgramType = null;
            _selectedStatus = null;
            _startDate = null;
            _endDate = null;
            _showSuccess = false;
          });

          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Aid program added successfully!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            
            // Navigate back after 2 seconds
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                widget.onBack();
              }
            });
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(provider.error ?? 'Failed to add program'),
                backgroundColor: Colors.red,
              ),
            );
            setState(() => _showSuccess = false);
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E9D63),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: const Text(
          'Add Aid Program',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // Success Message
          if (_showSuccess)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0E9D63).withOpacity(0.1),
                border: Border.all(color: const Color(0xFF0E9D63).withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green[600],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Program Added Successfully!',
                          style: TextStyle(
                            color: Color(0xFF0E9D63),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'The new aid program has been created.',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Program Title
                    _buildFormField(
                      label: 'Program Title',
                      required: true,
                      controller: _titleController,
                      hintText: 'e.g., Student Education Aid 2025',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Program title is required';
                        }
                        return null;
                      },
                    ),

                    // Category
                    _buildDropdownField(
                      label: 'Category / Type',
                      required: true,
                      value: _selectedCategory,
                      items: const [
                        'financial',
                        'disaster',
                        'medical',
                        'education',
                        'housing',
                        'other',
                      ],
                      displayNames: const {
                        'financial': 'Financial Aid',
                        'disaster': 'Disaster Relief',
                        'medical': 'Medical Emergency Fund',
                        'education': 'Education Aid',
                        'housing': 'Housing Assistance',
                        'other': 'Other',
                      },
                      onChanged: (value) => setState(() => _selectedCategory = value),
                    ),

                    // Description
                    _buildFormField(
                      label: 'Description',
                      required: true,
                      controller: _descriptionController,
                      hintText: 'Describe the aid program, eligibility, and benefits',
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Description is required';
                        }
                        return null;
                      },
                    ),

                    // Date Range
                    Text(
                      'Date Range',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDatePickerButton(
                            label: 'Start Date',
                            date: _startDate,
                            onTap: () => selectDate(context, true),
                            required: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDatePickerButton(
                            label: 'End Date',
                            date: _endDate,
                            onTap: () => selectDate(context, false),
                            required: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Program Type
                    _buildDropdownField(
                      label: 'Program Type',
                      required: true,
                      value: _selectedProgramType,
                      items: const [
                        'one-time',
                        'monthly',
                        'quarterly',
                        'application-based',
                      ],
                      displayNames: const {
                        'one-time': 'One-time Payment',
                        'monthly': 'Monthly Payment',
                        'quarterly': 'Quarterly Payment',
                        'application-based': 'Application Based',
                      },
                      onChanged: (value) => setState(() => _selectedProgramType = value),
                    ),

                    // Aid Amount
                    _buildFormField(
                      label: 'Aid Amount (RM)',
                      required: false,
                      controller: _aidAmountController,
                      hintText: 'e.g., 500 or 5000',
                      keyboardType: TextInputType.number,
                    ),

                    // Eligibility Criteria
                    _buildFormField(
                      label: 'Eligibility Criteria',
                      required: false,
                      controller: _eligibilityController,
                      hintText: 'Who can apply for this program?',
                      maxLines: 3,
                    ),

                    // Status
                    _buildDropdownField(
                      label: 'Status',
                      required: true,
                      value: _selectedStatus,
                      items: const ['active', 'inactive', 'draft'],
                      displayNames: const {
                        'active': 'Active',
                        'inactive': 'Inactive',
                        'draft': 'Draft',
                      },
                      onChanged: (value) => setState(() => _selectedStatus = value),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0E9D63),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Submit',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    _titleController.clear();
                    _descriptionController.clear();
                    _aidAmountController.clear();
                    _eligibilityController.clear();
                    setState(() {
                      _selectedCategory = null;
                      _selectedProgramType = null;
                      _selectedStatus = null;
                      _startDate = null;
                      _endDate = null;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                  'Clear / Reset',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: widget.onBack,
                  child: Text(
                    'Back',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required bool required,
    required TextEditingController controller,
    String? hintText,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              if (required)
                const Text(
                  ' *',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            minLines: maxLines == 1 ? 1 : maxLines,
            decoration: InputDecoration(
              prefixText: keyboardType == TextInputType.number ? 'RM ' : null,
              prefixStyle: keyboardType == TextInputType.number 
                  ? const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)
                  : null,
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF0E9D63), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            validator: validator,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required bool required,
    required String? value,
    required List<String> items,
    required Map<String, String> displayNames,
    required Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              if (required)
                const Text(
                  ' *',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF0E9D63), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            hint: Text(
              'Select ${label.toLowerCase()}',
              style: TextStyle(color: Colors.grey[400]),
            ),
            items: items
                .map((item) => DropdownMenuItem(
                      value: item,
                      child: Text(displayNames[item] ?? item),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerButton({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required bool required,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            if (required)
              const Text(
                ' *',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatDate(date),
                  style: TextStyle(
                    fontSize: 14,
                    color: date == null ? Colors.grey[400] : Colors.black,
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
