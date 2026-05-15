/*
  GROUP_X - Student Assistant Application
  Members:
  - S.Rululu (222057369)
  - k.Malikoe (224004891)
  - T.Maqala (219004340)
  - R.Molelekwa (222015201)
  Date: May 2026
  Module: TPG316C
*/

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApplicationViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _applications = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> get applications => _applications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Fetch applications for current user (students see theirs, admins see all)
  Future<void> fetchApplications(String userId, String userRole) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (userRole == 'admin') {
        // Admin sees all applications
        final response = await _supabase
            .from('applications')
            .select('*, profiles(full_name, email)')
            .order('created_at', ascending: false);
        _applications = List<Map<String, dynamic>>.from(response);
      } else {
        // Student sees only their own applications
        final response = await _supabase
            .from('applications')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false);
        _applications = List<Map<String, dynamic>>.from(response);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Check if student already has an application
  Future<bool> hasExistingApplication(String userId) async {
    try {
      final response = await _supabase
          .from('applications')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Submit new application
  Future<bool> submitApplication({
    required String userId,
    required String yearOfStudy,
    required String module1Level,
    required String module1Name,
    String? module2Level,
    String? module2Name,
    required String motivation,
    String? documentUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = {
        'user_id': userId,
        'year_of_study': yearOfStudy,
        'module1_level': module1Level,
        'module1_name': module1Name,
        'module2_level': module2Level,
        'module2_name': module2Name,
        'motivation': motivation,
        'document_url': documentUrl,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('applications')
          .insert(data)
          .select();

      return response.isNotEmpty;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update application (only if pending)
  Future<bool> updateApplication({
    required String applicationId,
    required String yearOfStudy,
    required String module1Level,
    required String module1Name,
    String? module2Level,
    String? module2Name,
    required String motivation,
    String? documentUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = {
        'year_of_study': yearOfStudy,
        'module1_level': module1Level,
        'module1_name': module1Name,
        'module2_level': module2Level,
        'module2_name': module2Name,
        'motivation': motivation,
        if (documentUrl != null) 'document_url': documentUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('applications').update(data).match({
        'id': applicationId,
      });

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete application (only if pending)
  Future<bool> deleteApplication(String applicationId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _supabase.from('applications').delete().match({
        'id': applicationId,
      });

      _applications.removeWhere((app) => app['id'] == applicationId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Admin: Update application status (approve/reject)
  Future<bool> updateApplicationStatus(
    String applicationId,
    String status,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _supabase
          .from('applications')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .match({'id': applicationId});

      // Update local list
      final index = _applications.indexWhere(
        (app) => app['id'] == applicationId,
      );
      if (index != -1) {
        _applications[index]['status'] = status;
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
