import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/aid_request_model.dart';

class AidRequestProvider extends ChangeNotifier {
  List<AidRequestModel> _aidRequests = [];
  bool _isLoading = false;
  String? _error;
  String? _userId;
  String? _lastRequestId;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<AidRequestModel> get aidRequests => _aidRequests;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AidRequestProvider({dynamic authProvider}) {
    if (authProvider != null && authProvider.userId != null) {
      _userId = authProvider.userId.toString();
      Future.delayed(Duration.zero, () {
        fetchUserAidRequests();
      });
    }
  }

  void setUserId(String userId) {
    _userId = userId;
    notifyListeners();
    fetchUserAidRequests();
  }

  Future<void> fetchUserAidRequests() async {
    if (_userId == null) {
      print('ERROR: _userId is null, cannot fetch aid requests');
      _aidRequests = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('aid_requests')
          .where('user_id', isEqualTo: _userId)
          .get();

      print('DEBUG: Fetched ${snapshot.docs.length} aid requests for user $_userId');

      _aidRequests = snapshot.docs
          .map((doc) => AidRequestModel.fromFirestore(doc))
          .toList();

      // Sort by submission date in descending order (most recent first)
      _aidRequests.sort((a, b) => b.submissionDate.compareTo(a.submissionDate));

      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      print('ERROR fetching aid requests: $e');
      _error = 'Failed to fetch aid requests: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllAidRequests() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('aid_requests')
          .get();

      print('DEBUG: Fetched ${snapshot.docs.length} total aid requests for admin');

      _aidRequests = snapshot.docs
          .map((doc) => AidRequestModel.fromFirestore(doc))
          .toList();

      // Sort by submission date in descending order (most recent first)
      _aidRequests.sort((a, b) => b.submissionDate.compareTo(a.submissionDate));

      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      print('ERROR fetching all aid requests: $e');
      _error = 'Failed to fetch aid requests: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  String _generateRequestId() {
    // Generate sequential request ID based on year: AR2026001, AR2026002, etc.
    final year = DateTime.now().year;
    final nextNumber = _aidRequests.length + 1;
    return 'AR$year${nextNumber.toString().padLeft(3, '0')}';
  }

  Future<bool> submitAidRequest({
    required String aidType,
    required double monthlyIncome,
    required List<FamilyMemberModel> familyMembers,
    required String description,
    String? applicantName,
    String? applicantIC,
    String? applicantEmail,
    String? applicantPhone,
    String? applicantAddress,
  }) async {
    if (_userId == null) {
      _error = 'User not logged in';
      notifyListeners();
      return false;
    }

    if (aidType.isEmpty || monthlyIncome <= 0 || familyMembers.isEmpty || description.isEmpty) {
      _error = 'Please fill in all required fields';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final requestId = _generateRequestId();
      final now = DateTime.now();

      final aidRequest = AidRequestModel(
        id: requestId, // Use the sequential ID
        userId: _userId!,
        requestId: requestId,
        aidType: aidType,
        status: 'pending',
        submissionDate: now,
        description: description,
        familyMembers: familyMembers,
        monthlyIncome: monthlyIncome,
        createdAt: now,
        applicantName: applicantName,
        applicantIC: applicantIC,
        applicantEmail: applicantEmail,
        applicantPhone: applicantPhone,
        applicantAddress: applicantAddress,
      );

      // Use .doc(requestId).set() to create with sequential ID
      await _firestore
          .collection('aid_requests')
          .doc(requestId)
          .set(aidRequest.toFirestore());
      
      _lastRequestId = requestId;

      print('DEBUG: Aid request submitted with ID: $requestId');

      // Refresh the list
      await fetchUserAidRequests();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('ERROR submitting aid request: $e');
      _error = 'Failed to submit aid request: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  String? getLastRequestId() {
    return _lastRequestId;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> updateRequestStatus({
    required String requestId,
    required String newStatus,
    String? remarks,
    String? approvedAmount,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore
          .collection('aid_requests')
          .doc(requestId)
          .update({
            'status': newStatus,
            if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
            if (approvedAmount != null && approvedAmount.isNotEmpty) 'approved_amount': double.tryParse(approvedAmount) ?? 0,
            if (notes != null && notes.isNotEmpty) 'internal_notes': notes,
            'updated_at': DateTime.now(),
          });

      print('DEBUG: Request $requestId updated to status: $newStatus');

      // Refresh the list to get updated data
      await fetchAllAidRequests();

      _isLoading = false;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      print('ERROR updating request status: $e');
      _error = 'Failed to update request: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteRequest(String requestId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore
          .collection('aid_requests')
          .doc(requestId)
          .delete();

      print('DEBUG: Request $requestId deleted successfully');

      // Refresh the list to remove the deleted request
      await fetchAllAidRequests();

      _isLoading = false;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      print('ERROR deleting request: $e');
      _error = 'Failed to delete request: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
