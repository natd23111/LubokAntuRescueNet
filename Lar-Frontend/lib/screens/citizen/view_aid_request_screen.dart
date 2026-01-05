import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/aid_request_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/aid_request_model.dart';

class ViewAidRequestScreen extends StatefulWidget {
  const ViewAidRequestScreen({super.key});

  @override
  _ViewAidRequestScreenState createState() => _ViewAidRequestScreenState();
}

class _ViewAidRequestScreenState extends State<ViewAidRequestScreen> {
  String activeTab = 'pending';
  String searchQuery = '';
  String selectedStatus = 'All';
  String? selectedRequestId;
  TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        final requestId = args['requestId'] ?? args['reportId'];
        if (requestId != null) {
          print('📍 Auto-selecting aid request from navigation: $requestId');
          Future.delayed(Duration(milliseconds: 500), () {
            if (mounted) {
              setState(() => selectedRequestId = requestId);
            }
          });
        }
      }

      // Ensure provider has userId set and data loaded
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final aidProvider = Provider.of<AidRequestProvider>(
        context,
        listen: false,
      );
      if (authProvider.userId != null) {
        aidProvider.setUserId(authProvider.userId!);
      }
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFD97706);
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

  String _getStatusLabel(String status, AppLocalizations l10n) {
    switch (status.toLowerCase()) {
      case 'pending':
        return l10n.pending;
      case 'approved':
        return l10n.approved;
      case 'rejected':
        return l10n.rejected;
      case 'processing':
        return l10n.processing;
      default:
        return status;
    }
  }

  Widget _buildStatusBadge(String status, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusBgColor(status),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _getStatusLabel(status, l10n),
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
        .where(
          (r) =>
              (activeTab == 'pending' ||
                      activeTab == 'approved' ||
                      activeTab == 'rejected'
                  ? r.status.toLowerCase() == activeTab.toLowerCase()
                  : true) &&
              (selectedStatus == 'All' ||
                  r.aidType.toLowerCase() == selectedStatus.toLowerCase()) &&
              (r.requestId.toLowerCase().contains(searchQuery.toLowerCase()) ||
                  r.aidType.toLowerCase().contains(searchQuery.toLowerCase()) ||
                  r.description.toLowerCase().contains(
                    searchQuery.toLowerCase(),
                  )),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<AidRequestProvider>(
      builder: (context, aidRequestProvider, _) {
        if (selectedRequestId != null) {
          return _buildDetailView();
        }

        final filteredRequests = _getFilteredRequests(
          aidRequestProvider.aidRequests,
        );

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: const Color(0xFF059669),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              l10n.myAidRequests,
              style: const TextStyle(
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
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
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
                              l10n.pendingTabLabel(
                                '${aidRequestProvider.aidRequests.where((r) => r.status.toLowerCase() == 'pending').length}',
                              ),
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
                              l10n.approvedTabLabel(
                                '${aidRequestProvider.aidRequests.where((r) => r.status.toLowerCase() == 'approved').length}',
                              ),
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
                        onTap: () => setState(() => activeTab = 'rejected'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: activeTab == 'rejected'
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
                              l10n.rejectedTabLabel(
                                '${aidRequestProvider.aidRequests.where((r) => r.status.toLowerCase() == 'rejected').length}',
                              ),
                              style: TextStyle(
                                color: activeTab == 'rejected'
                                    ? const Color(0xFF059669)
                                    : Colors.grey[600],
                                fontWeight: activeTab == 'rejected'
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
                    hintText: l10n.searchAidRequests,
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
                  child: Builder(
                    builder: (context) {
                      final typeMap = {
                        'All': l10n.allRequests,
                        'Financial Aid': l10n.financialAidFilter,
                        'Disaster Relief': l10n.disasterReliefFilter,
                        'Medical Emergency Fund': l10n.medicalEmergencyFundFilter,
                        'Education Aid': l10n.educationAidFilter,
                        'Housing Assistance': l10n.housingAssistanceFilter,
                        'Other': l10n.otherCategoryFilter,
                      };
                      final types = ['All', 'Financial Aid', 'Disaster Relief', 'Medical Emergency Fund', 'Education Aid', 'Housing Assistance', 'Other'];

                      return Row(
                        children: types.map((type) {
                          final isSelected = selectedStatus == type;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => selectedStatus = type),
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
                                  typeMap[type] ?? type,
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
                      );
                    },
                  ),
                ),
              ),

              // Content
              Expanded(
                child: aidRequestProvider.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF059669),
                          ),
                        ),
                      )
                    : filteredRequests.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.noAidRequestsFound,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
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
                          return _buildRequestCard(request, l10n);
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
                    border: Border(top: BorderSide(color: Colors.red[200]!)),
                  ),
                  child: Text(
                    '${l10n.errorPrefix}${aidRequestProvider.error}',
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                child: Text('Back', style: TextStyle(color: Colors.grey[600])),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRequestCard(AidRequestModel request, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () => setState(() => selectedRequestId = request.requestId),
      child: Container(
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
                _buildStatusBadge(request.status, l10n),
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
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailView() {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<AidRequestProvider>(
      builder: (context, aidRequestProvider, _) {
        final request = aidRequestProvider.aidRequests.firstWhere(
          (r) => r.requestId == selectedRequestId,
        );

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: const Color(0xFF059669),
            title: Text(l10n.requestDetails),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => selectedRequestId = null),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.requestIdLabel,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          request.requestId,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    _buildStatusBadge(request.status, l10n),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDetailRow(l10n.aidTypeLabel, request.aidType, l10n),
                if (request.applicantName != null)
                  _buildDetailRow(l10n.fullNameLabel, request.applicantName!, l10n),
                if (request.applicantIC != null)
                  _buildDetailRow(l10n.icNumberLabel, request.applicantIC!, l10n),
                if (request.applicantEmail != null)
                  _buildDetailRow(l10n.emailLabel, request.applicantEmail!, l10n),
                if (request.applicantPhone != null)
                  _buildDetailRow(l10n.phoneLabel, request.applicantPhone!, l10n),
                if (request.applicantAddress != null)
                  _buildDetailRow(l10n.addressLabel, request.applicantAddress!, l10n),
                _buildDetailRow(l10n.dateSubmittedLabel, request.formattedDate, l10n),
                _buildDetailRow(
                  l10n.monthlyIncomeLabel,
                  'RM ${request.monthlyIncome.toStringAsFixed(2)}',
                  l10n,
                ),
                _buildDetailRow(
                  l10n.familyMembersLabel,
                  request.familyMembers.length.toString(),
                  l10n,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.familyComposition,
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ...request.familyMembers.map((member) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.name,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          member.status,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
                _buildDetailRow(l10n.descriptionLabel, request.description, l10n),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => setState(() => selectedRequestId = null),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                child: Text(
                  l10n.backToList,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.black87)),
        ],
      ),
    );
  }
}
