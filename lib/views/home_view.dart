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

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    final authVM = context.read<AuthViewModel>();
    final appVM = context.read<ApplicationViewModel>();
    
    if (authVM.currentUserId != null) {
      await appVM.fetchApplications(
        authVM.currentUserId!,
        authVM.userRole ?? 'student',
      );
    }
  }

  void _navigateToSubmitApplication() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ApplicationFormView()),
    ).then((_) => _loadApplications());
  }

  void _navigateToApplicationDetail(Map<String, dynamic> application) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ApplicationDetailView(application: application),
      ),
    ).then((_) => _loadApplications());
  }

  void _logout() async {
    final authVM = context.read<AuthViewModel>();
    await authVM.logout();
    // Navigation will be handled by AppRouter
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final appVM = context.watch<ApplicationViewModel>();
    final isAdmin = authVM.userRole == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Admin Dashboard' : 'My Applications'),
        centerTitle: true,
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadApplications,
            tooltip: 'Refresh',
          ),
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _buildBody(appVM, isAdmin),
      floatingActionButton: !isAdmin
          ? FloatingActionButton(
              onPressed: _navigateToSubmitApplication,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildBody(ApplicationViewModel appVM, bool isAdmin) {
    if (appVM.isLoading && appVM.applications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (appVM.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${appVM.errorMessage}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadApplications,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (appVM.applications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_open, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No applications found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            if (!isAdmin)
              ElevatedButton.icon(
                onPressed: _navigateToSubmitApplication,
                icon: const Icon(Icons.add),
                label: const Text('Submit Application'),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadApplications(),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: appVM.applications.length,
        itemBuilder: (context, index) {
          final application = appVM.applications[index];
          return _buildApplicationCard(application, isAdmin);
        },
      ),
    );
  }

  Widget _buildApplicationCard(Map<String, dynamic> application, bool isAdmin) {
    final status = application['status'] ?? 'pending';
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToApplicationDetail(application),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Status icon
                  Icon(statusIcon, color: statusColor, size: 20),
                  const SizedBox(width: 8),
                  // Module 1 name
                  Expanded(
                    child: Text(
                      application['module1_name'] ?? 'No Module',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Module 2 (if exists)
              if (application['module2_name'] != null &&
                  application['module2_name'].isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.book, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        application['module2_name'],
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              // Year of study
              Row(
                children: [
                  const Icon(Icons.school, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Year ${application['year_of_study'] ?? 'N/A'}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Student name (for admin view)
              if (isAdmin && application['profiles'] != null)
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      application['profiles']['full_name'] ?? 'Unknown',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              // Date submitted
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(application['created_at']),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown date';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown date';
    }
  }
}


