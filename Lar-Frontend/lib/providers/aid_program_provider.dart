import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/aid_program.dart';

class AidProgramProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<AidProgram> _programs = [];
  bool _isLoading = false;
  String? _error;

  List<AidProgram> get programs => _programs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch all aid programs with optional filtering
  Future<void> fetchPrograms({String? status, String? category, String? search}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Query query = _firestore.collection('aid_programs');

      // Filter by status
      if (status != null && status.isNotEmpty) {
        query = query.where('status', isEqualTo: status.toLowerCase());
      }

      // Filter by category
      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category.toLowerCase());
      }

      final snapshot = await query.get();

      // Convert Firestore documents to AidProgram objects
      List<AidProgram> programsList = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Use document ID as the program ID
        return AidProgram.fromJson(data);
      }).toList();

      // Filter by search term (title or description)
      if (search != null && search.isNotEmpty) {
        final lowerSearch = search.toLowerCase();
        programsList = programsList.where((program) {
          return program.title.toLowerCase().contains(lowerSearch) ||
              (program.description?.toLowerCase().contains(lowerSearch) ?? false);
        }).toList();
      }

      _programs = programsList;
      _error = null;
    } catch (e) {
      _error = 'Error fetching programs: ${e.toString()}';
      print(_error);
    }

    _isLoading = false;
    notifyListeners();
  }

  // Create new aid program
  Future<bool> createProgram(AidProgram program) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final programData = {
        'title': program.title,
        'description': program.description ?? '',
        'category': program.category.toLowerCase(),
        'criteria': program.eligibilityCriteria ?? '',
        'start_date': program.startDate.toIso8601String(),
        'end_date': program.endDate.toIso8601String(),
        'status': program.status.toLowerCase(),
        'program_type': program.programType ?? 'aid',
        'aid_amount': program.aidAmount ?? '0',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final docRef = await _firestore.collection('aid_programs').add(programData);
      
      // Create the program object with the new document ID
      final newProgram = AidProgram(
        id: docRef.id,
        title: program.title,
        category: program.category,
        status: program.status,
        startDate: program.startDate,
        endDate: program.endDate,
        description: program.description,
        aidAmount: program.aidAmount,
        eligibilityCriteria: program.eligibilityCriteria,
        programType: program.programType,
      );

      _programs.add(newProgram);
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error creating program: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      print(_error);
      return false;
    }
  }

  // Update aid program
  Future<bool> updateProgram(AidProgram program) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final programData = {
        'title': program.title,
        'description': program.description ?? '',
        'category': program.category.toLowerCase(),
        'criteria': program.eligibilityCriteria ?? '',
        'start_date': program.startDate.toIso8601String(),
        'end_date': program.endDate.toIso8601String(),
        'status': program.status.toLowerCase(),
        'program_type': program.programType ?? 'aid',
        'aid_amount': program.aidAmount ?? '0',
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _firestore.collection('aid_programs').doc(program.id.toString()).update(programData);

      // Update local list
      final index = _programs.indexWhere((p) => p.id == program.id);
      if (index != -1) {
        _programs[index] = program;
      }

      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error updating program: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      print(_error);
      return false;
    }
  }

  // Delete aid program
  Future<bool> deleteProgram(String programId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore.collection('aid_programs').doc(programId).delete();

      _programs.removeWhere((p) => p.id == programId);

      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error deleting program: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      print(_error);
      return false;
    }
  }

  // Toggle program status
  Future<bool> toggleProgramStatus(String programId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final doc = await _firestore.collection('aid_programs').doc(programId).get();
      if (!doc.exists) {
        _error = 'Program not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final currentStatus = doc['status'] as String;
      final newStatus = currentStatus == 'active' ? 'inactive' : 'active';

      await _firestore.collection('aid_programs').doc(programId).update({
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      });

      final index = _programs.indexWhere((p) => p.id == programId);
      if (index != -1) {
        final program = _programs[index];
        _programs[index] = AidProgram(
          id: program.id,
          title: program.title,
          category: program.category,
          status: newStatus,
          startDate: program.startDate,
          endDate: program.endDate,
          description: program.description,
          aidAmount: program.aidAmount,
          eligibilityCriteria: program.eligibilityCriteria,
          programType: program.programType,
        );
      }

      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error toggling status: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      print(_error);
      return false;
    }
  }
}
