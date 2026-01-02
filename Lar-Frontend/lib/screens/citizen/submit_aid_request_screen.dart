import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/aid_request_provider.dart';
import '../../models/aid_request_model.dart';

class FamilyMember {
  final int id;
  String name;
  String status;

  FamilyMember({
    required this.id,
    required this.name,
    required this.status,
  });
}

class SubmitAidRequestScreen extends StatefulWidget {
  final String? preselectedProgramId;
  final String? preselectedCategory;
  final String? preselectedAmount;

  const SubmitAidRequestScreen({
    this.preselectedProgramId,
    this.preselectedCategory,
    this.preselectedAmount,
  });

  @override
  _SubmitAidRequestScreenState createState() => _SubmitAidRequestScreenState();
}

class _SubmitAidRequestScreenState extends State<SubmitAidRequestScreen> {
  bool showSuccess = false;
  late String selectedAidType;
  String monthlyIncome = '';
  String description = '';
  String? programId;
  String? programAmount;
  List<FamilyMember> familyMembers = [
    FamilyMember(id: 1, name: '', status: 'student')
  ];

  @override
  void initState() {
    super.initState();
    // Pre-populate with program details if provided
    // Map program categories to dropdown values
    if (widget.preselectedCategory != null) {
      selectedAidType = _mapCategoryToDropdownValue(widget.preselectedCategory!);
    } else {
      selectedAidType = '';
    }
    programId = widget.preselectedProgramId;
    programAmount = widget.preselectedAmount;
  }

  String _mapCategoryToDropdownValue(String category) {
    switch (category.toLowerCase()) {
      case 'financial':
        return 'Financial Aid';
      case 'disaster':
        return 'Disaster Relief';
      case 'medical':
        return 'Medical Emergency Fund';
      case 'education':
        return 'Education Aid';
      case 'housing':
        return 'Housing Assistance';
      default:
        return 'Other';
    }
  }

  final TextEditingController incomeController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController familyCountController = TextEditingController();

  @override
  void dispose() {
    incomeController.dispose();
    descriptionController.dispose();
    familyCountController.dispose();
    super.dispose();
  }

  void handleSubmit() async {
    // Validate form
    if (selectedAidType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an aid type')),
      );
      return;
    }

    if (incomeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter monthly household income')),
      );
      return;
    }

    if (familyMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one family member')),
      );
      return;
    }

    if (descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a description')),
      );
      return;
    }

    // Convert family members to AidRequestModel format
    List<FamilyMemberModel> familyMembersData = familyMembers
        .map((fm) => FamilyMemberModel(name: fm.name, status: fm.status))
        .toList();

    // Submit to Firebase
    final aidRequestProvider = Provider.of<AidRequestProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await aidRequestProvider.submitAidRequest(
      aidType: selectedAidType,
      monthlyIncome: double.tryParse(incomeController.text) ?? 0,
      familyMembers: familyMembersData,
      description: descriptionController.text,
      applicantName: authProvider.userName,
      applicantIC: authProvider.userIc,
      applicantEmail: authProvider.userEmail,
      applicantPhone: authProvider.userPhone,
      applicantAddress: authProvider.userAddress,
    );

    if (success && mounted) {
      setState(() => showSuccess = true);
      final requestId = aidRequestProvider.getLastRequestId();
      
      Future.delayed(Duration(seconds: 3), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(aidRequestProvider.error ?? 'Failed to submit request')),
      );
    }
  }

  void addFamilyMember() {
    if (familyMembers.length >= 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum of 20 family members allowed')),
      );
      return;
    }
    setState(() {
      familyMembers.add(
        FamilyMember(
          id: DateTime.now().millisecondsSinceEpoch,
          name: '',
          status: 'student',
        ),
      );
      familyCountController.text = familyMembers.length.toString();
    });
  }

  void removeFamilyMember(int id) {
    setState(() {
      familyMembers.removeWhere((member) => member.id == id);
      familyCountController.text = familyMembers.length.toString();
    });
  }

  void updateFamilyMemberCount(String value) {
    int? count = int.tryParse(value);
    if (count == null || count < 1) return;
    if (count > 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum of 20 family members allowed')),
      );
      familyCountController.text = '20';
      count = 20;
    }

    setState(() {
      if (count! > familyMembers.length) {
        // Add more family members
        for (int i = familyMembers.length; i < count!; i++) {
          familyMembers.add(
            FamilyMember(
              id: DateTime.now().millisecondsSinceEpoch + i,
              name: '',
              status: 'student',
            ),
          );
        }
      } else if (count! < familyMembers.length) {
        // Remove family members from the end
        familyMembers = familyMembers.sublist(0, count!);
      }
    });
  }

  void updateFamilyMember(int id, {String? name, String? status}) {
    final index = familyMembers.indexWhere((member) => member.id == id);
    if (index != -1) {
      setState(() {
        if (name != null) familyMembers[index].name = name;
        if (status != null) familyMembers[index].status = status;
      });
    }
  }

  void clearForm() {
    setState(() {
      selectedAidType = '';
      incomeController.clear();
      descriptionController.clear();
      familyCountController.clear();
      familyMembers = [FamilyMember(id: 1, name: '', status: 'student')];
    });
  }

  String getCurrentDate() {
    final now = DateTime.now();
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AidRequestProvider>(
      builder: (context, aidRequestProvider, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: const Color(0xFF059669),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text(
              'Submit Aid Request',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Success Message
                if (showSuccess)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF059669),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Aid Request Submitted!',
                                style: TextStyle(
                                  color: Color(0xFF166534),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Your request has been received. Reference: ${aidRequestProvider.getLastRequestId()}',
                                style: const TextStyle(
                                  color: Color(0xFF15803D),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Form Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Aid Type
                  _buildFormLabel('Aid Type / Category'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedAidType.isEmpty ? null : selectedAidType,
                    decoration: InputDecoration(
                      hintText: 'Select aid type',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF059669),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    items: [
                      'Financial Aid',
                      'Disaster Relief',
                      'Medical Emergency Fund',
                      'Education Aid',
                      'Housing Assistance',
                      'Other',
                    ].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedAidType = newValue ?? '';
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Household Details Section
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Divider(color: Colors.grey[200], thickness: 1),
                  ),
                  Text(
                    'Household Details',
                    style: TextStyle(
                      color: Colors.grey[900],
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Monthly Household Income
                  _buildFormLabel('Monthly Household Income (RM)'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: incomeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter monthly income',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF059669),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Number of Family Members
                  _buildFormLabel('Number of Family Members'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: familyCountController,
                    keyboardType: TextInputType.number,
                    onChanged: updateFamilyMemberCount,
                    decoration: InputDecoration(
                      hintText: 'Enter number',
                      prefixIcon: const Icon(Icons.family_restroom),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF059669),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Family Members Details
                  _buildFormLabel('Family Members Details'),
                  const SizedBox(height: 12),
                  Column(
                    children: [
                      ...familyMembers.asMap().entries.map((entry) {
                        int index = entry.key;
                        FamilyMember member = entry.value;
                        return _buildFamilyMemberCard(
                          index: index,
                          member: member,
                          canDelete: familyMembers.length > 1,
                        );
                      }).toList(),
                      const SizedBox(height: 12),
                      _buildAddMemberButton(),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Description
                  _buildFormLabel('Description / Reason'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Explain why you need this aid',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF059669),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submission Date
                  _buildFormLabel('Submission Date'),
                  const SizedBox(height: 8),
                  TextField(
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: 'Auto-filled with current date',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      fillColor: Colors.grey[50],
                      filled: true,
                    ),
                    controller: TextEditingController(
                      text: getCurrentDate(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Auto-filled with current date',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey[200]!),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Submit Request',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: clearForm,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                child: Text(
                  'Clear / Reset',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                side: BorderSide(color: Colors.grey[300]!),
                ),
                child: Text(
                  'Back',
                  style: TextStyle(
                  color: Colors.grey[600]),
                ),
              ),
            ),
          ],
        ),
      ),
        );
      },
    );
  }

  Widget _buildFormLabel(String label) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: label,
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const TextSpan(
            text: ' *',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyMemberCard({
    required int index,
    required FamilyMember member,
    required bool canDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Member ${index + 1}',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (canDelete)
                GestureDetector(
                  onTap: () => removeFamilyMember(member.id),
                  child: Icon(
                    Icons.delete_outline,
                    color: Colors.red[600],
                    size: 18,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Name Input
          TextField(
            onChanged: (value) =>
                updateFamilyMember(member.id, name: value),
            decoration: InputDecoration(
              hintText: 'Name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF059669),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Status Dropdown
          DropdownButtonFormField<String>(
            value: member.status,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF059669),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            items: [
              'Student',
              'Employed / Full-time',
              'Part-time Worker',
              'Unemployed',
              'Retired',
              'Child (Under 12)',
            ].map((String value) {
              return DropdownMenuItem<String>(
                value: value.toLowerCase().replaceAll(' / ', '/').replaceAll(' ', '-'),
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                updateFamilyMember(member.id, status: newValue);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddMemberButton() {
    return GestureDetector(
      onTap: addFamilyMember,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey[300]!,
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add,
              color: Colors.grey[600],
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Add Family Member',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
