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
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/application_viewmodel.dart';
import '../routes/route_manager.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  String _filterStatus = 'all'; // all, pending, approved, rejected
  
  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    final authVM = context.read<AuthViewModel>();
    final appVM = context.read<ApplicationViewModel>();
    
    await appVM.fetchApplications(
      authVM.currentUserId!,
      'admin', // Admin role to see all applications
    );
  }

  void _logout() async {
    final authVM = context.read<AuthViewModel>();
    await authVM.logout();
  }

  void _navigateToDetail(Map<String, dynamic> application) {
    RouteManager.pushNamed(
      context,
      RouteManager.applicationDetail,
      arguments: application,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final appVM = context.watch<ApplicationViewModel>();
    
    // Filter applications based on status
    List<Map<String, dynamic>> filteredApps = appVM.applications;
    if (_filterStatus != 'all') {
      filteredApps = appVM.applications
          .where((app) => app['status'] == _filterStatus)
          .toList();
    }
    
    final pendingCount = appVM.applications
        .where((app) => app['status'] == 'pending')
        .length;
    final approvedCount = appVM.applications
        .where((app) => app['status'] == 'approved')
        .length;
    final rejectedCount = appVM.applications
        .where((app) => app['status'] == 'rejected')
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadApplications,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Cards
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildStatCard('Pending', pendingCount, Colors.orange, () {
                  setState(() => _filterStatus = 'pending');
                }),
                const SizedBox(width: 12),
                _buildStatCard('Approved', approvedCount, Colors.green, () {
                  setState(() => _filterStatus = 'approved');
                }),
                const SizedBox(width: 12),
                _buildStatCard('Rejected', rejectedCount, Colors.red, () {
                  setState(() => _filterStatus = 'rejected');
                }),
              ],
            ),
          ),
          
          // Filter Chip Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _filterStatus == 'all',
                  onSelected: (_) => setState(() => _filterStatus = 'all'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Pending'),
                  selected: _filterStatus == 'pending',
                  onSelected: (_) => setState(() => _filterStatus = 'pending'),
                  backgroundColor: Colors.orange.shade50,
                  selectedColor: Colors.orange.shade100,
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Approved'),
                  selected: _filterStatus == 'approved',
                  onSelected: (_) => setState(() => _filterStatus = 'approved'),
                  backgroundColor: Colors.green.shade50,
                  selectedColor: Colors.green.shade100,
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Rejected'),
                  selected: _filterStatus == 'rejected',
                  onSelected: (_) => setState(() => _filterStatus = 'rejected'),
                  backgroundColor: Colors.red.shade50,
                  selectedColor: Colors.red.shade100,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Applications List
          Expanded(
            child: _buildBody(appVM, filteredApps),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Card(
          color: color.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ApplicationViewModel appVM, List<Map<String, dynamic>> applications) {
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

    if (applications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_open, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _filterStatus == 'all' 
                  ? 'No applications found' 
                  : 'No $_filterStatus applications',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadApplications,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: applications.length,
        itemBuilder: (context, index) {
          final application = applications[index];
          return _buildApplicationCard(application);
        },
      ),
    );
  }

  Widget _buildApplicationCard(Map<String, dynamic> application) {
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
    
    final studentName = application['profiles']?['full_name'] ?? 'Unknown Student';
    final studentEmail = application['profiles']?['email'] ?? 'No email';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToDetail(application),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Student Avatar
                  CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.2),
                    child: Text(
                      studentName.isNotEmpty ? studentName[0].toUpperCase() : '?',
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Student Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          studentName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          studentEmail,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, color: statusColor, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          status.toUpperCase(),
                          style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Modules
              const Divider(),
              Row(
                children: [
                  const Icon(Icons.book, size: 14, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      application['module1_name'] ?? 'No Module',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              if (application['module2_name'] != null && application['module2_name'].isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.book_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          application['module2_name'],
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              // Year of Study
              Row(
                children: [
                  const Icon(Icons.school, size: 12, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Year ${application['year_of_study']}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}