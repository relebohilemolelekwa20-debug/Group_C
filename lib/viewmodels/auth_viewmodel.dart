/*
  GROUP_C - Student Assistant Application
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

class AuthViewModel extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  bool _isLoading = false;
  String? _errorMessage;
  String _userRole = 'student'; // Default value, never null
  
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get userRole => _userRole; // Returns String, never null
  
  bool get isLoggedIn => _supabase.auth.currentSession != null;
  String? get currentUserId => _supabase.auth.currentUser?.id;
  String? get currentUserEmail => _supabase.auth.currentUser?.email;
  
  // Initialize user session and fetch role
  Future<void> initUser() async {
    if (!isLoggedIn) {
      _userRole = 'student';
      //notifyListeners();
      return;
    }
    await fetchUserRole();
    //notifyListeners();
  }
  
  // Fetch user role from profiles table
  Future<void> fetchUserRole() async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        _userRole = 'student';
        return;
      }
      
      final response = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle();
      
      if (response != null && response['role'] != null) {
        _userRole = response['role'];
      } else {
        _userRole = 'student';
      }
    } catch (e) {
      _userRole = 'student';
    }
    notifyListeners();
  }
  
  // Sign Up
  Future<void> signUp(String email, String password, String name, BuildContext context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': name},
      );
      
      if (response.user != null) {
        _userRole = 'student';
        _errorMessage = null;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account created! Please login.')),
          );
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Login
  Future<void> login(String email, String password, BuildContext context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      
      if (response.user != null) {
        await fetchUserRole();
        _errorMessage = null;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Logout
  Future<void> logout() async {
    await _supabase.auth.signOut();
    _userRole = 'student';
    notifyListeners();
  }
  
  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}