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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/application_viewmodel.dart';
import 'application_form_view.dart';

class ApplicationDetailView extends StatefulWidget {
  final Map<String, dynamic> application;
  const ApplicationDetailView({super.key, required this.application});

  @override
  State<ApplicationDetailView> createState() => _ApplicationDetailViewState();
}

class _ApplicationDetailViewState extends State<ApplicationDetailView> {
  bool _isDeleting = false;

  Future<void> _deleteApplication() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Application'),
        content: const Text('Are you sure you want to delete this application? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);
    final appVM = context.read<ApplicationViewModel>();
    final success = await appVM.deleteApplication(widget.application['id']);

    setState(() => _isDeleting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application deleted successfully')),
      );
      Navigator.pop(context, true); // Return to home to refresh
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${appVM.errorMessage}')),
      );
    }
  }

  void _editApplication() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ApplicationFormView(
          isEditing: true,
          application: widget.application,
        ),
      ),
    ).then((_) => Navigator.pop(context, true)); // Refresh on return
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final isAdmin = authVM.userRole == 'admin';
    final status = widget.application['status'] ?? 'pending';
    final isPending = status == 'pending';
    
    // Student can edit/delete only if pending
    final canEdit = !isAdmin && isPending;
    final canDelete = !isAdmin && isPending;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Details'),
        centerTitle: true,
        actions: [
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editApplication,
              tooltip: 'Edit',
            ),
          if (canDelete)
            IconButton(
              icon: _isDeleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete, color: Colors.red),
              onPressed: _isDeleting ? null : _deleteApplication,
              tooltip: 'Delete',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner
            _buildStatusBanner(status),
            const SizedBox(height: 24),
            
            // Student Info (for admin)
            if (isAdmin && widget.application['profiles'] != null)
              _buildSection('Student Information', [
                _buildInfoRow('Name', widget.application['profiles']['full_name'] ?? 'N/A'),
                _buildInfoRow('Email', widget.application['profiles']['email'] ?? 'N/A'),
              ]),
            
            // Academic Information
            _buildSection('Academic Information', [
              _buildInfoRow('Year of Study', 'Year ${widget.application['year_of_study']}'),
            ]),
            
            const SizedBox(height: 16),
            
            // First Module
            _buildSection('First Module', [
              _buildInfoRow('Level', widget.application['module1_level'] ?? 'N/A'),
              _buildInfoRow('Module Name', widget.application['module1_name'] ?? 'N/A'),
            ]),
            
            // Second Module (if exists)
            if (widget.application['module2_name'] != null &&
                widget.application['module2_name'].isNotEmpty)
              _buildSection('Second Module', [
                _buildInfoRow('Level', widget.application['module2_level'] ?? 'N/A'),
                _buildInfoRow('Module Name', widget.application['module2_name']),
              ]),
            
            // Motivation
            _buildSection('Motivation Statement', [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  widget.application['motivation'] ?? 'No motivation provided',
                  style: const TextStyle(height: 1.5),
                ),
              ),
            ]),
            
            // Supporting Document
            if (widget.application['document_url'] != null)
              _buildSection('Supporting Document', [
                InkWell(
                  onTap: () {
                    // TODO: Open document viewer
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.insert_drive_file, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('View Uploaded Document'),
                        SizedBox(width: 8),
                        Icon(Icons.open_in_new, size: 16),
                      ],
                    ),
                  ),
                ),
              ]),
            
            const SizedBox(height: 16),
            
            // Submission Date
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Submitted:'),
                  Text(_formatDate(widget.application['created_at'])),
                ],
              ),
            ),
            
            const SizedBox(height: 80), // Space for admin buttons
          ],
        ),
      ),
      // Admin Action Buttons (bottom)
      bottomNavigationBar: isAdmin && isPending
          ? _buildAdminActions()
          : null,
    );
  }

  Widget _buildStatusBanner(String status) {
    Color color;
    IconData icon;
    String label;
    
    switch (status) {
      case 'approved':
        color = Colors.green;
        icon = Icons.check_circle;
        label = 'APPROVED';
        break;
      case 'rejected':
        color = Colors.red;
        icon = Icons.cancel;
        label = 'REJECTED';
        break;
      default:
        color = Colors.orange;
        icon = Icons.pending;
        label = 'PENDING REVIEW';
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Application Status',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActions() {
    final appVM = context.read<ApplicationViewModel>();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            offset: const Offset(0, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () async {
                final success = await appVM.updateApplicationStatus(
                  widget.application['id'],
                  'rejected',
                );
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Application rejected')),
                  );
                  Navigator.pop(context, true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('REJECT'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () async {
                final success = await appVM.updateApplicationStatus(
                  widget.application['id'],
                  'approved',
                );
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Application approved')),
                  );
                  Navigator.pop(context, true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('APPROVE'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Unknown';
    }
  }
}