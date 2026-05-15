/*
  GROUP_C - Student Assistant Application
  Members:
  - S.Rululu (222057369)
  - k.Malikoe (224004891)
  - T.Maqala (219004340)
  - R.Molelekwa (222015201)
  - Name Surname (Student Number)
  Date: May 2026
  Module: TPG316C
*/

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/application_viewmodel.dart';

class ApplicationFormView extends StatefulWidget {
  const ApplicationFormView({super.key});

  @override
  State<ApplicationFormView> createState() => _ApplicationFormViewState();
}

class _ApplicationFormViewState extends State<ApplicationFormView> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _yearOfStudyController = TextEditingController();
  final _module1LevelController = TextEditingController();
  final _module1NameController = TextEditingController();
  final _module2LevelController = TextEditingController();
  final _module2NameController = TextEditingController();
  final _motivationController = TextEditingController();
  
  // Module 2 toggle
  bool _includeModule2 = false;
  
  // File upload
  File? _selectedDocument;
  bool _isUploading = false;
  String? _uploadedDocumentUrl;
  
  // Year of study options
  final List<String> _yearOptions = ['1', '2', '3'];
  
  // Module level options
  final List<String> _levelOptions = ['First Year', 'Second Year', 'Third Year'];
  
  // Module name options
  final List<String> _moduleOptions = [
    'TPG316C - Mobile App Development',
    'TPG311C - Web Development',
    'TPG312C - Databases',
    'TPG313C - Networking',
    'TPG314C - Software Engineering',
    'TPG315C - Operating Systems',
  ];

  @override
  void dispose() {
    _yearOfStudyController.dispose();
    _module1LevelController.dispose();
    _module1NameController.dispose();
    _module2LevelController.dispose();
    _module2NameController.dispose();
    _motivationController.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    
    if (result != null) {
      setState(() {
        _selectedDocument = File(result.path);
        _isUploading = true;
      });
      
      // Simulate upload (will connect to Supabase later)
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _uploadedDocumentUrl = 'uploaded_document_url_placeholder';
        _isUploading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document uploaded successfully!')),
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    final authVM = context.read<AuthViewModel>();
    final appVM = context.read<ApplicationViewModel>();
    
    // Check if student already has an application
    final hasExisting = await appVM.hasExistingApplication(authVM.currentUserId!);
    if (hasExisting) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You already have an application. Only one application allowed.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final success = await appVM.submitApplication(
      userId: authVM.currentUserId!,
      yearOfStudy: _yearOfStudyController.text,
      module1Level: _module1LevelController.text,
      module1Name: _module1NameController.text,
      module2Level: _includeModule2 ? _module2LevelController.text : null,
      module2Name: _includeModule2 ? _module2NameController.text : null,
      motivation: _motivationController.text,
      documentUrl: _uploadedDocumentUrl,
    );
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // Return to home to refresh
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${appVM.errorMessage}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appVM = context.watch<ApplicationViewModel>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Assistant Application'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Card(
                    color: Colors.blue,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.assignment, size: 48, color: Colors.white),
                          SizedBox(height: 8),
                          Text(
                            'Student Assistant Application',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Apply to become a Student Assistant',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 1. Year of Study
                  const Text(
                    'Academic Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Current Year of Study *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.school),
                    ),
                    value: _yearOfStudyController.text.isEmpty
                        ? null
                        : _yearOfStudyController.text,
                    items: _yearOptions.map((String year) {
                      return DropdownMenuItem<String>(
                        value: year,
                        child: Text('Year $year'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _yearOfStudyController.text = value ?? '';
                      });
                    },
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Please select your year of study' : null,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 2. First Module (Required)
                  const Text(
                    'First Module Application *',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Module Level',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    value: _module1LevelController.text.isEmpty
                        ? null
                        : _module1LevelController.text,
                    items: _levelOptions.map((String level) {
                      return DropdownMenuItem<String>(
                        value: level,
                        child: Text(level),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _module1LevelController.text = value ?? '';
                      });
                    },
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Please select module level' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Module Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.book),
                    ),
                    value: _module1NameController.text.isEmpty
                        ? null
                        : _module1NameController.text,
                    items: _moduleOptions.map((String module) {
                      return DropdownMenuItem<String>(
                        value: module,
                        child: Text(module, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _module1NameController.text = value ?? '';
                      });
                    },
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Please select module name' : null,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 3. Second Module (Optional)
                  CheckboxListTile(
                    title: const Text(
                      'Apply for a second module (Optional)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    value: _includeModule2,
                    onChanged: (value) {
                      setState(() {
                        _includeModule2 = value ?? false;
                        if (!_includeModule2) {
                          _module2LevelController.clear();
                          _module2NameController.clear();
                        }
                      });
                    },
                    activeColor: Colors.blue,
                  ),
                  
                  if (_includeModule2) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Second Module Details',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Module Level',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      value: _module2LevelController.text.isEmpty
                          ? null
                          : _module2LevelController.text,
                      items: _levelOptions.map((String level) {
                        return DropdownMenuItem<String>(
                          value: level,
                          child: Text(level),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _module2LevelController.text = value ?? '';
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Module Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.book),
                      ),
                      value: _module2NameController.text.isEmpty
                          ? null
                          : _module2NameController.text,
                      items: _moduleOptions.map((String module) {
                        return DropdownMenuItem<String>(
                          value: module,
                          child: Text(module, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _module2NameController.text = value ?? '';
                        });
                      },
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // 4. Motivation
                  const Text(
                    'Motivation Statement *',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _motivationController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Why do you want to become a Student Assistant?',
                      hintText: 'Describe your qualifications, experience, and motivation...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.edit_note),
                      alignLabelWithHint: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please provide a motivation statement';
                      }
                      if (value.trim().length < 50) {
                        return 'Motivation must be at least 50 characters';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 5. Supporting Document
                  const Text(
                    'Supporting Documents',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (_selectedDocument != null) ...[
                            Row(
                              children: [
                                const Icon(Icons.insert_drive_file, color: Colors.green),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _selectedDocument!.path.split('/').last,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      _selectedDocument = null;
                                      _uploadedDocumentUrl = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_isUploading)
                              const LinearProgressIndicator(),
                          ],
                          if (_selectedDocument == null)
                            ElevatedButton.icon(
                              onPressed: _pickDocument,
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Upload Document (CV/Transcript)'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 45),
                              ),
                            ),
                          const SizedBox(height: 8),
                          const Text(
                            'Accepted formats: PDF, DOC, JPG, PNG. Max size: 5MB',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: appVM.isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: appVM.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'SUBMIT APPLICATION',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}