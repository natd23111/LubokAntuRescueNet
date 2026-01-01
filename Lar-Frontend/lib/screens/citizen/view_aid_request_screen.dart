import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/aid_request_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/aid_request_model.dart';

class ViewAidRequestScreen extends StatefulWidget {
  @override
  _ViewAidRequestScreenState createState() => _ViewAidRequestScreenState();
}

class _ViewAidRequestScreenState extends State<ViewAidRequestScreen> {
  String activeTab = 'pending';
  String searchQuery = '';
  String selectedStatus = 'All';
  TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFCD34D);
      case 'approved':
        return const Color(0xFF059669);
      case 'rejected':
        return Colors.red;
      case 'processing':
        return const Color(0xFF93C5FD);
      default:
        return Colors.grey;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFEF08A);
      case 'approved':
        return const Color(0xFFD1FAE5);
      case 'rejected':
        return const Color(0xFFFEE2E2);
      case 'processing':
        return const Color(0xFFDBEAFE);
      default:
        return Colors.grey[100]!;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'processing':
        return 'Processing';
      default:
        return status;
    }
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusBgColor(status),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _getStatusLabel(status),
        style: TextStyle(
          color: _getStatusColor(status),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  List<AidRequestModel> _getFilteredRequests(List<AidRequestModel> requests) {
    return requests
        .where((r) =>
            (activeTab == 'all' || r.status.toLowerCase() == activeTab.toLowerCase()) &&
            (selectedStatus == 'All' || r.aidType.toLowerCase() == selectedStatus.toLowerCase()) &&
            (r.requestId.toLowerCase().contains(searchQuery.toLowerCase()) ||
                r.aidType.toLowerCase().contains(searchQuery.toLowerCase()) ||
                r.description.toLowerCase().contains(searchQuery.toLowerCase())))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AidRequestProvider>(
      builder: (context, aidRequestProvider, _) {
        final filteredRequests = _getFilteredRequests(aidRequestProvider.aidRequests);

        return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF059669),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'My Aid Requests',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // Tabs
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => activeTab = 'pending'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: activeTab == 'pending'
                            ? Border(
                                bottom: BorderSide(
                                  color: const Color(0xFF059669),
                                  width: 2,
                                ),
                              )
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          'Pending',
                          style: TextStyle(
                            color: activeTab == 'pending'
                                ? const Color(0xFF059669)
                                : Colors.grey[600],
                            fontWeight: activeTab == 'pending'
                                ? FontWeight.w600
                                : FontWeight.normal,
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
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: activeTab == 'approved'
                            ? Border(
                                bottom: BorderSide(
                                  color: const Color(0xFF059669),
                                  width: 2,
                                ),
                              )
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          'Approved',
                          style: TextStyle(
                            color: activeTab == 'approved'
                                ? const Color(0xFF059669)
                                : Colors.grey[600],
                            fontWeight: activeTab == 'approved'
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => activeTab = 'all'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: activeTab == 'all'
                            ? Border(
                                bottom: BorderSide(
                                  color: const Color(0xFF059669),
                                  width: 2,
                                ),
                              )
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          'All Requests',
                          style: TextStyle(
                            color: activeTab == 'all'
                                ? const Color(0xFF059669)
                                : Colors.grey[600],
                            fontWeight: activeTab == 'all'
                                ? FontWeight.w600
                                : FontWeight.normal,
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search aid requests',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
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
              ),
            ),
          ),

          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  'All',
                  'Financial Aid',
                  'Disaster Relief',
                  'Education Aid',
                  'Medical Fund',
                ].map((type) {
                  final isSelected = selectedStatus == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => selectedStatus = type),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF059669)
                              : Colors.white,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF059669)
                                : Colors.grey[300]!,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.grey[700],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Content
          Expanded(
            child: aidRequestProvider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
                    ),
                  )
                : filteredRequests.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'No aid requests found',
                              style:
                                  TextStyle(color: Colors.grey[600], fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        itemCount: filteredRequests.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final request = filteredRequests[index];
                          return _buildRequestCard(request);
                        },
                      ),
          ),
          
          // Error display
          if (aidRequestProvider.error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                border: Border(
                  top: BorderSide(color: Colors.red[200]!),
                ),
              ),
              child: Text(
                'Error: ${aidRequestProvider.error}',
                style: TextStyle(color: Colors.red[700], fontSize: 12),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey[200]!)),
        ),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              'Back',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
      ),
        );
      },
    );
  }

  Widget _buildRequestCard(AidRequestModel request) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                request.requestId,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              _buildStatusBadge(request.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            request.aidType,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            request.description,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                request.formattedDate,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              Icon(Icons.chevron_right,
                  color: Colors.grey[400], size: 20),
            ],
          ),
        ],
      ),
    );
  }
}
