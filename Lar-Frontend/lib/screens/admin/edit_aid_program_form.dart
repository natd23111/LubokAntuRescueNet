import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/aid_program.dart';
import '../../providers/aid_program_provider.dart';

class EditAidProgramForm extends StatefulWidget {
  final AidProgram program;
  final VoidCallback onBack;
  final Function(AidProgram) onSubmit;

  const EditAidProgramForm({
    Key? key,
    required this.program,
    required this.onBack,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<EditAidProgramForm> createState() => _EditAidProgramFormState();
}

class _EditAidProgramFormState extends State<EditAidProgramForm> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController criteriaController;
  late TextEditingController aidAmountController;
  late DateTime startDate;
  late DateTime endDate;
  late String selectedCategory;
  late String? selectedType;
  late String selectedStatus;

  final List<String> categories = [
    'Financial',
    'Medical',
    'Education',
    'Housing',
    'Food',
    'Other',
  ];

  final List<String> programTypes = [
    'Monthly',
    'One-time',
    'Quarterly',
    'Seasonal',
  ];

  final List<String> statuses = ['Active', 'Inactive'];

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.program.title);
    descriptionController = TextEditingController(text: widget.program.description);
    criteriaController = TextEditingController(text: widget.program.eligibilityCriteria);
    aidAmountController = TextEditingController(text: widget.program.aidAmount?.toString() ?? '');
    startDate = widget.program.startDate;
    endDate = widget.program.endDate;
    selectedCategory = widget.program.category;
    selectedType = widget.program.programType;
    selectedStatus = widget.program.status == 'active' ? 'Active' : 'Inactive';
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    criteriaController.dispose();
    aidAmountController.dispose();
    super.dispose();
  }

  Future<void> selectDate(BuildContext context, bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? startDate : endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  String formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }

  Future<void> handleSubmit() async {
    if (titleController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        criteriaController.text.isEmpty ||
        aidAmountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final updatedProgram = AidProgram(
      id: widget.program.id,
      title: titleController.text,
      category: selectedCategory,
      description: descriptionController.text,
      aidAmount: aidAmountController.text.isNotEmpty 
          ? aidAmountController.text 
          : '0',
      status: selectedStatus.toLowerCase(),
      startDate: startDate,
      endDate: endDate,
      eligibilityCriteria: criteriaController.text,
      programType: selectedType ?? 'Monthly',
    );

    final provider = Provider.of<AidProgramProvider>(context, listen: false);
    final success = await provider.updateProgram(updatedProgram);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Program updated successfully!'),
          backgroundColor: Colors.green[600],
          duration: const Duration(seconds: 2),
        ),
      );
      widget.onSubmit(updatedProgram);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to update program'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Edit Aid Program',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Program Title
            const Text(
              'Program Title',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: 'e.g., B40 Financial Assistance 2025',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // Category
            const Text(
              'Category',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: selectedCategory,
                isExpanded: true,
                underline: SizedBox(),
                items: categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text(category),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => selectedCategory = value ?? 'Financial');
                },
              ),
            ),
            const SizedBox(height: 20),

            // Description
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Enter program description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // Start Date
            const Text(
              'Start Date',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => selectDate(context, true),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatDate(startDate),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const Icon(Icons.calendar_today, size: 18, color: Color(0xFF0E9D63)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // End Date
            const Text(
              'End Date',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => selectDate(context, false),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatDate(endDate),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const Icon(Icons.calendar_today, size: 18, color: Color(0xFF0E9D63)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Program Type
            const Text(
              'Program Type',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: selectedType,
                isExpanded: true,
                underline: SizedBox(),
                items: programTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text(type),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => selectedType = value ?? 'Monthly');
                },
              ),
            ),
            const SizedBox(height: 20),

            // Aid Amount
            const Text(
              'Aid Amount (RM)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: aidAmountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'e.g., 500.00',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                filled: true,
                fillColor: Colors.white,
                prefixText: 'RM ',
              ),
            ),
            const SizedBox(height: 20),

            // Eligibility Criteria
            const Text(
              'Eligibility Criteria',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: criteriaController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter eligibility criteria',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // Status
            const Text(
              'Status',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: selectedStatus,
                isExpanded: true,
                underline: SizedBox(),
                items: statuses.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text(status),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => selectedStatus = value ?? 'Active');
                },
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0E9D63),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Update Program',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[300]!),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
