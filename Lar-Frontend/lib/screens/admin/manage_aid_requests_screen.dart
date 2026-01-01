import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/aid_request_provider.dart';
import '../../models/aid_request_model.dart';

class ManageAidRequestsScreen extends StatefulWidget {
  final VoidCallback onBack;

  const ManageAidRequestsScreen({required this.onBack});

  @override
  _ManageAidRequestsScreenState createState() => _ManageAidRequestsScreenState();
}

class _ManageAidRequestsScreenState extends State<ManageAidRequestsScreen> {
  late AidRequestProvider aidRequestProvider;
  String activeTab = 'pending';
  String? selectedRequestId;
  bool editMode = false;
  bool showSuccess = false;
  String? searchQuery;
  bool _hasInitialized = false;

  String? selectedStatus;
  TextEditingController remarksController = TextEditingController();
  TextEditingController approvedAmountController = TextEditingController();
  TextEditingController notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // No need to fetch here anymore - it's done in build with _hasInitialized flag
  }

  @override
  void dispose() {
    remarksController.dispose();
    approvedAmountController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllRequests() async {
    try {
      // Fetch all aid requests from Firestore for admin view
      await aidRequestProvider.fetchAllAidRequests();
    } catch (e) {
      print('Error fetching requests: $e');
    }
  }

  void _showDeleteConfirmation(AidRequestModel request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Aid Request'),
        content: Text(
          'Are you sure you want to delete request ${request.requestId}?\n\n'
          'Type: ${request.aidType}\n'
          'Status: ${request.status}\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteRequest(request.requestId);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRequest(String requestId) async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deleting request...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      // Delete from Firestore
      await aidRequestProvider.deleteRequest(requestId);

      // Go back to list
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        setState(() => selectedRequestId = null);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request $requestId deleted successfully'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting request: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _handleUpdate() async {
    if (selectedRequestId == null) return;

    // Validate status selection
    if (selectedStatus == null || selectedStatus!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a status')),
      );
      return;
    }

    // Call provider to update request
    final success = await aidRequestProvider.updateRequestStatus(
      requestId: selectedRequestId!,
      newStatus: selectedStatus!,
      remarks: remarksController.text,
      approvedAmount: approvedAmountController.text,
      notes: notesController.text,
    );

    if (success) {
      setState(() {
        showSuccess = true;
      });
      Future.delayed(Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            editMode = false;
            showSuccess = false;
            selectedStatus = null;
            remarksController.clear();
            approvedAmountController.clear();
            notesController.clear();
            // Keep selectedRequestId to show detail view instead of going back to list
          });
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(aidRequestProvider.error ?? 'Failed to update request')),
      );
    }
  }

  List<AidRequestModel> _getFilteredRequests() {
    List<AidRequestModel> requests = aidRequestProvider.aidRequests;

    // Filter by status
    requests = requests.where((req) {
      String status = req.status.toLowerCase();
      if (activeTab == 'pending') return status == 'pending';
      if (activeTab == 'approved') return status == 'approved';
      if (activeTab == 'rejected') return status == 'rejected';
      return true;
    }).toList();

    // Filter by search query
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final query = searchQuery!.toLowerCase();
      requests = requests.where((req) {
        return req.requestId.toLowerCase().contains(query) ||
            req.aidType.toLowerCase().contains(query);
      }).toList();
    }

    return requests;
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;

    status = status.toLowerCase();
    if (status == 'pending') {
      bgColor = Colors.amber.shade100;
      textColor = Colors.amber.shade800;
      label = 'Pending';
    } else if (status == 'approved') {
      bgColor = Colors.green.shade100;
      textColor = Colors.green.shade800;
      label = 'Approved';
    } else {
      bgColor = Colors.red.shade100;
      textColor = Colors.red.shade800;
      label = 'Rejected';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AidRequestProvider>(
      builder: (context, provider, _) {
        aidRequestProvider = provider;

        // Initialize data fetch on first build
        if (!_hasInitialized) {
          _hasInitialized = true;
          Future.microtask(() => _fetchAllRequests());
        }

        // Edit mode - update request
        if (editMode && selectedRequestId != null) {
          return _buildEditView();
        }

        // Detail view - view request details
        if (selectedRequestId != null && !editMode) {
          return _buildDetailView();
        }

        // List view - main list of requests
        return _buildListView();
      },
    );
  }

  Widget _buildEditView() {
    final request = aidRequestProvider.aidRequests.firstWhere((r) => r.requestId == selectedRequestId);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF0E9D63),
        title: Text('Update Aid Request'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => setState(() => editMode = false),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showSuccess)
              Container(
                margin: EdgeInsets.only(bottom: 16),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Request Updated Successfully!',
                              style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.w600)),
                          Text('The applicant will be notified.',
                              style: TextStyle(color: Colors.green.shade700, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Text('Request ID', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            Text(request.requestId, style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
            SizedBox(height: 16),
            Text('Application Status *', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedStatus ?? request.status.toLowerCase(),
              items: ['pending', 'approved', 'rejected']
                  .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status[0].toUpperCase() + status.substring(1)),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => selectedStatus = value),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            SizedBox(height: 16),
            Text('Decision Remarks', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            TextField(
              controller: remarksController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Add reason for acceptance or rejection...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            SizedBox(height: 16),
            Text('Approved Amount (RM)', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            TextField(
              controller: approvedAmountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter approved amount',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            SizedBox(height: 4),
            Text('Leave blank if rejected', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Request Details', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                  SizedBox(height: 12),
                  _buildDetailRow('Aid Type', request.aidType),
                  _buildDetailRow('Monthly Income', 'RM ${request.monthlyIncome.toStringAsFixed(2)}'),
                  _buildDetailRow('Family Members', request.familyMembers.length.toString()),
                  SizedBox(height: 12),
                  Text('Reason', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  SizedBox(height: 4),
                  Text(request.description, style: TextStyle(color: Colors.black87)),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text('Internal Notes', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add internal notes (not visible to applicant)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF0E9D63),
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Update Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
            SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => setState(() => editMode = false),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailView() {
    final request = aidRequestProvider.aidRequests.firstWhere((r) => r.requestId == selectedRequestId);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF0E9D63),
        title: Text('Request Details'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => setState(() => selectedRequestId = null),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _showDeleteConfirmation(request),
            tooltip: 'Delete Request',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Request ID', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    Text(request.requestId, style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                  ],
                ),
                _buildStatusBadge(request.status),
              ],
            ),
            SizedBox(height: 16),
            _buildDetailRow('Aid Type', request.aidType),
            if (request.applicantName != null)
              _buildDetailRow('Full Name', request.applicantName!),
            if (request.applicantIC != null)
              _buildDetailRow('IC Number', request.applicantIC!),
            if (request.applicantEmail != null)
              _buildDetailRow('Email', request.applicantEmail!),
            if (request.applicantPhone != null)
              _buildDetailRow('Phone', request.applicantPhone!),
            if (request.applicantAddress != null)
              _buildDetailRow('Address', request.applicantAddress!),
            _buildDetailRow('Date Submitted', request.formattedDate),
            _buildDetailRow('Monthly Income', 'RM ${request.monthlyIncome.toStringAsFixed(2)}'),
            _buildDetailRow('Family Members', request.familyMembers.length.toString()),
            SizedBox(height: 16),
            Text('Family Composition', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            ...request.familyMembers.map((member) {
              return Container(
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.name, style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                    Text(member.status, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
              );
            }).toList(),
            SizedBox(height: 16),
            _buildDetailRow('Description', request.description),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => setState(() => editMode = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF0E9D63),
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Update Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
            SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => setState(() => selectedRequestId = null),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                child: Text('Back to List', style: TextStyle(color: Colors.grey[600])),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    final filteredRequests = _getFilteredRequests();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF0E9D63),
        title: Text('Aid Requests'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
      ),
      body: Column(
        children: [
          // Tabs
          Container(
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => activeTab = 'pending'),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: activeTab == 'pending'
                            ? Border(bottom: BorderSide(color: Color(0xFF0E9D63), width: 2))
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          'Pending (${aidRequestProvider.aidRequests.where((r) => r.status.toLowerCase() == 'pending').length})',
                          style: TextStyle(
                            color: activeTab == 'pending' ? Color(0xFF0E9D63) : Colors.grey.shade600,
                            fontWeight: activeTab == 'pending' ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => activeTab = 'approved'),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: activeTab == 'approved'
                            ? Border(bottom: BorderSide(color: Color(0xFF0E9D63), width: 2))
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          'Approved (${aidRequestProvider.aidRequests.where((r) => r.status.toLowerCase() == 'approved').length})',
                          style: TextStyle(
                            color: activeTab == 'approved' ? Color(0xFF0E9D63) : Colors.grey.shade600,
                            fontWeight: activeTab == 'approved' ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => activeTab = 'rejected'),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: activeTab == 'rejected'
                            ? Border(bottom: BorderSide(color: Color(0xFF0E9D63), width: 2))
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          'Rejected (${aidRequestProvider.aidRequests.where((r) => r.status.toLowerCase() == 'rejected').length})',
                          style: TextStyle(
                            color: activeTab == 'rejected' ? Color(0xFF0E9D63) : Colors.grey.shade600,
                            fontWeight: activeTab == 'rejected' ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Search
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search by ID or type...',
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          // List
          Expanded(
            child: aidRequestProvider.isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF0E9D63)),
                        SizedBox(height: 16),
                        Text('Loading requests...', style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  )
                : filteredRequests.isEmpty
                    ? Center(
                        child: Text('No requests found', style: TextStyle(color: Colors.grey.shade600)),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(12),
                        itemCount: filteredRequests.length,
                        itemBuilder: (context, index) {
                          final request = filteredRequests[index];
                          return GestureDetector(
                            onTap: () => setState(() => selectedRequestId = request.requestId),
                            child: Container(
                              margin: EdgeInsets.only(bottom: 10),
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(request.requestId,
                                          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                                      _buildStatusBadge(request.status),
                                    ],
                                  ),
                                  SizedBox(height: 6),
                                  Text(request.aidType, style: TextStyle(color: Colors.black87)),
                                  SizedBox(height: 6),
                                  Text('Income: RM ${request.monthlyIncome}', style: TextStyle(color: Colors.grey.shade700)),
                                  SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('${request.familyMembers.length} members',
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                      Icon(Icons.chevron_right, color: Colors.grey.shade400),
                                    ],
                                  ),
                                  SizedBox(height: 6),
                                  Text(request.formattedDate, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          // Back Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: widget.onBack,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                child: Text(
                  'Back',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          SizedBox(height: 4),
          Text(value, style: TextStyle(color: Colors.black87)),
        ],
      ),
    );
  }
}
