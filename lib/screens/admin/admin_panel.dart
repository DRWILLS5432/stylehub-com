import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stylehub/constants/app/app_colors.dart';
import 'package:stylehub/constants/app/textstyle.dart';
import 'package:stylehub/constants/localization/locales.dart';
import 'package:stylehub/services/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseService _firebaseService = FirebaseService();
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    const UsersScreen(),
    const ApprovalRequestsScreen(),
    const HelpDeskScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Admin Dashboard', style: appTextStyle18(AppColors.mainBlackTextColor)),
        backgroundColor: AppColors.appBGColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              Icons.logout,
              color: AppColors.mainBlackTextColor,
            ),
            onPressed: () {
              ///Show a logout Dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      child: Text(
                        'Cancel',
                        style: appTextStyle14(AppColors.mainBlackTextColor),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    TextButton(
                      child: Text(
                        'Logout',
                        style: appTextStyle14(AppColors.mainBlackTextColor),
                      ),

                      onPressed: () => _firebaseService.logout(context),
                      // () => Navigator.pushNamedAndRemoveUntil(context, '/login_screen', (route) => false),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) => setState(() => _selectedIndex = index),
      selectedItemColor: AppColors.mainBlackTextColor,
      unselectedItemColor: Colors.grey,
      backgroundColor: AppColors.appBGColor.withValues(alpha: 0.4),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.people_alt),
          label: 'Users',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment),
          label: 'Approvals',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.support_agent),
          label: 'Support',
        ),
      ],
    );
  }
}

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  Future<void> _toggleSuspendUser(BuildContext context, String userId, bool isSuspended) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'suspended': !isSuspended,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isSuspended ? 'User unsuspended successfully' : 'User suspended successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update user status: an error occurred')),
      );
    }
  }

  // Delete a user from Firestore
  Future<void> _deleteUser(BuildContext context, String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete user: an error occurred')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: an error occurred'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No users found.'));
        }

        final users = snapshot.data!.docs;

        // Calculate counts
        int customerCount = 0;
        int stylistCount = 0;

        for (var user in users) {
          final role = (user.data() as Map<String, dynamic>)['role'] ?? 'User';
          if (role == 'Stylist') {
            stylistCount++;
          } else {
            customerCount++;
          }
        }

        final totalUsers = users.length;

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              automaticallyImplyLeading: false,
              expandedHeight: 400.h,
              pinned: true,
              backgroundColor: AppColors.appBGColor,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: AppColors.appBGColor,
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 16.h),
                      _buildPieChart(customerCount, stylistCount),
                      SizedBox(height: 16.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatCard(
                            title: LocaleData.totalUsers.getString(context).toUpperCase(),
                            value: totalUsers.toString(),
                            color: Colors.blue,
                          ),
                          SizedBox(width: 16.w),
                          _buildStatCard(
                            title: LocaleData.customer.getString(context).toUpperCase(),
                            value: customerCount.toString(),
                            color: Colors.blue,
                          ),
                          SizedBox(width: 16.w),
                          _buildStatCard(
                            title: LocaleData.stylist.getString(context).toUpperCase(),
                            value: stylistCount.toString(),
                            color: Colors.purple,
                          ),
                        ],
                      ),
                      _buildLegend(),
                    ],
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final userDoc = users[index];
                  final userData = userDoc.data() as Map<String, dynamic>;
                  final role = userData['role'] ?? 'User';
                  final isSuspended = userData['suspended'] as bool? ?? false;

                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserDetailScreen(userId: userDoc.id),
                      ),
                    ),
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        color: AppColors.appBGColor,
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: role == 'Stylist' ? Colors.purple[100] : Colors.blue[100],
                                    child: Icon(
                                      role == 'Stylist' ? Icons.brush : Icons.person,
                                      color: role == 'Stylist' ? Colors.purple : Colors.blue,
                                    ),
                                  ),
                                  SizedBox(width: 16.w),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: isSuspended ? Colors.grey : Colors.black,
                                        ),
                                      ),
                                      Text(
                                        role,
                                        style: TextStyle(
                                          color: role == 'Stylist' ? Colors.purple : Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                child: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (isSuspended)
                                Padding(
                                  padding: EdgeInsets.only(left: 8.w),
                                  child: const Text(
                                    'Suspended',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              const Spacer(),
                              IconButton(
                                icon: Icon(
                                  isSuspended ? Icons.check_circle : Icons.block,
                                  color: isSuspended ? Colors.green : Colors.red,
                                ),
                                tooltip: isSuspended ? 'Unsuspend User' : 'Suspend User',
                                onPressed: () => _toggleSuspendUser(context, userDoc.id, isSuspended),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.black),
                                tooltip: 'Delete User',
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Confirm Delete'),
                                      content: const Text('Are you sure you want to delete this user? This action cannot be undone.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            _deleteUser(context, userDoc.id);
                                            Navigator.pop(context);
                                          },
                                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: users.length,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            title,
            style: appTextStyle12K(AppColors.newThirdGrayColor),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(int customers, int stylists) {
    final total = customers + stylists;
    if (total == 0) return const SizedBox.shrink();

    return SizedBox(
      height: 140.h,
      child: PieChart(
        PieChartData(
          sectionsSpace: 4,
          centerSpaceRadius: 40,
          sections: [
            PieChartSectionData(
              color: Colors.blue,
              value: customers.toDouble(),
              title: '${((customers / total) * 100).toStringAsFixed(1)}%',
              titleStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              radius: 40,
            ),
            PieChartSectionData(
              color: Colors.purple,
              value: stylists.toDouble(),
              title: '${((stylists / total) * 100).toStringAsFixed(1)}%',
              titleStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              radius: 40,
            ),
          ],
        ),
        duration: const Duration(milliseconds: 300),
      ),
    );
  }

  Widget _buildLegend() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Icon(Icons.circle, color: Colors.blue, size: 16),
            SizedBox(width: 4),
            Text('Customers'),
          ],
        ),
        SizedBox(width: 20),
        Row(
          children: [
            Icon(Icons.circle, color: Colors.purple, size: 16),
            SizedBox(width: 4),
            Text('Stylists'),
          ],
        ),
      ],
    );
  }
}

class UserDetailScreen extends StatelessWidget {
  final String userId;

  const UserDetailScreen({super.key, required this.userId});

  Future<Map<String, int>> _getAppointmentStats() async {
    // Query for all appointments where userId matches either clientId or specialistId
    final allAppointments = await FirebaseFirestore.instance
        .collection('appointments')
        .where(Filter.or(
          Filter('clientId', isEqualTo: userId),
          Filter('specialistId', isEqualTo: userId),
        ))
        .get();

    // Query for cancelled appointments
    final cancelledAppointments = await FirebaseFirestore.instance
        .collection('appointments')
        .where(Filter.or(
          Filter('clientId', isEqualTo: userId),
          Filter('specialistId', isEqualTo: userId),
        ))
        .where('status', isEqualTo: 'cancelled')
        .get();

    // Query for booked appointments
    final bookedAppointments = await FirebaseFirestore.instance
        .collection('appointments')
        .where(Filter.or(
          Filter('clientId', isEqualTo: userId),
          Filter('specialistId', isEqualTo: userId),
        ))
        .where('status', isEqualTo: 'booked')
        .get();

    return {
      'total': allAppointments.docs.length,
      'cancelled': cancelledAppointments.docs.length,
      'booked': bookedAppointments.docs.length,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Details')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('User not found.'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailItem('Name', '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'),
                _buildDetailItem('Email', userData['email'] ?? 'Not available'),
                _buildDetailItem('Role', userData['role'] ?? 'Not set'),
                _buildDetailItem('Profession', userData['profession'] ?? 'Not set'),
                _buildDetailItem('Experience', userData['experience'] ?? 'Not set'),
                _buildDetailItem('Status', userData['status'] ?? 'Not set'),
                _buildDetailItem('Registration Date', userData['createdAt'] != null ? userData['createdAt'].toDate().toString() : 'N/A'),
                FutureBuilder<Map<String, int>>(
                  future: _getAppointmentStats(),
                  builder: (context, appointmentSnapshot) {
                    if (appointmentSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (appointmentSnapshot.hasError) {
                      return const Text('Error fetching appointment stats');
                    }
                    final stats = appointmentSnapshot.data ?? {'total': 0, 'cancelled': 0, 'booked': 0};
                    return Column(
                      children: [
                        _buildDetailItem('Total Appointments', stats['total'].toString()),
                        _buildDetailItem('Cancelled Appointments', stats['cancelled'].toString()),
                        _buildDetailItem('Booked Appointments', stats['booked'].toString()),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6.h),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.appBGColor, width: 2.w),
        borderRadius: BorderRadius.circular(20.dg),
        color: AppColors.appBGColor,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 10.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: SizedBox(child: Text('$label:', style: appTextStyle12K(AppColors.mainBlackTextColor)))),
            const SizedBox(width: 16),
            Text(
              value,
              style: appTextStyle16500(AppColors.mainBlackTextColor),
            ),
          ],
        ),
      ),
    );
  }
}

// Approval Requests Screen (Updated)

class ApprovalRequestsScreen extends StatelessWidget {
  const ApprovalRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No pending requests.'));
          }

          final users = snapshot.data!.docs;
          final pendingUsers = users.where((userDoc) {
            final userData = userDoc.data() as Map<String, dynamic>;
            return _hasPendingFields(userData);
          }).toList();

          if (pendingUsers.isEmpty) {
            return const Center(child: Text('No pending requests.'));
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: pendingUsers.length,
            itemBuilder: (context, index) {
              final userDoc = pendingUsers[index];
              final userData = userDoc.data() as Map<String, dynamic>;
              final userId = userDoc.id;

              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ApprovalDetailScreen(
                      userId: userId,
                      userData: userData,
                    ),
                  ),
                ),
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.appBGColor,
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            userData['email'] ?? 'No email',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  bool _hasPendingFields(Map<String, dynamic> userData) {
    const fieldKeys = ['profession', 'experience', 'city', 'address', 'bio', 'phone', 'previousWork', 'categories'];
    return fieldKeys.any((field) => userData['${field}Status'] == 'pending');
  }
}

class ApprovalDetailScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const ApprovalDetailScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  State<ApprovalDetailScreen> createState() => _ApprovalDetailScreenState();
}

class _ApprovalDetailScreenState extends State<ApprovalDetailScreen> {
  // Track loading state for each field
  final Map<String, bool> _loadingFields = {};

  @override
  Widget build(BuildContext context) {
    final pendingFields = _getPendingFields(widget.userData);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.userData['firstName'] ?? ''} ${widget.userData['lastName'] ?? ''}'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.userData['email'] ?? 'No email',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            if (pendingFields.isEmpty)
              const Center(
                child: Text(
                  'No pending fields to review',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
            else
              ...pendingFields.map((field) => _buildPendingField(context, widget.userId, field)),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getPendingFields(Map<String, dynamic> userData) {
    List<Map<String, dynamic>> pendingFields = [];
    const fieldKeys = ['profession', 'experience', 'city', 'address', 'bio', 'phone', 'previousWork', 'categories'];

    for (final field in fieldKeys) {
      final statusField = '${field}Status';
      if (userData[statusField] == 'pending') {
        pendingFields.add({
          'field': field,
          'statusField': statusField,
          'value': userData[field],
        });
      }
    }
    return pendingFields;
  }

  Widget _buildPendingField(
    BuildContext context,
    String userId,
    Map<String, dynamic> fieldInfo,
  ) {
    final field = fieldInfo['field'];
    final statusField = fieldInfo['statusField'];
    final value = fieldInfo['value'];

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.appBGColor,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Field: ${field.toUpperCase()}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          if (field == 'previousWork') _buildImageGrid(value) else Text('Value: $value'),
          const SizedBox(height: 12),
          _buildApprovalButtons(userId, statusField),
        ],
      ),
    );
  }

  Widget _buildImageGrid(dynamic imageUrls) {
    List<String> urls = [];
    if (imageUrls is List) {
      urls = imageUrls.whereType<String>().toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Submitted Images:',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: urls.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    urls[index],
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 150,
                        height: 150,
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 150,
                        height: 150,
                        color: Colors.grey[200],
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, color: Colors.red),
                            Text('Failed to load'),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildApprovalButtons(String userId, String statusField) {
    final isLoading = _loadingFields[statusField] ?? false;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isLoading)
          const CircularProgressIndicator()
        else ...[
          OutlinedButton.icon(
            icon: const Icon(Icons.check, color: Colors.green),
            label: const Text('Approve'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green,
              side: const BorderSide(color: Colors.green),
            ),
            onPressed: () => _handleApproval(
              userId: userId,
              statusField: statusField,
              status: 'approved',
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.close, color: Colors.red),
            label: const Text('Reject'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
            onPressed: () => _handleApproval(
              userId: userId,
              statusField: statusField,
              status: 'rejected',
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _handleApproval({
    required String userId,
    required String statusField,
    required String status,
  }) async {
    setState(() {
      _loadingFields[statusField] = true;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        statusField: status,
        'lastReviewed': FieldValue.serverTimestamp(),
      });

      // Update local userData to reflect the new status
      setState(() {
        widget.userData[statusField] = status;
        _loadingFields[statusField] = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Field ${statusField.replaceAll('Status', '')} $status successfully')),
      );
    } catch (e) {
      setState(() {
        _loadingFields[statusField] = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }
}
// class ApprovalRequestsScreen extends StatelessWidget {
//   const ApprovalRequestsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: StreamBuilder<QuerySnapshot>(
//         stream: FirebaseFirestore.instance.collection('users').snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }
//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(child: Text('No pending requests.'));
//           }

//           // Group pending requests by user
//           final users = snapshot.data!.docs;
//           final pendingUsers = users.where((userDoc) {
//             final userData = userDoc.data() as Map<String, dynamic>;
//             return _hasPendingFields(userData);
//           }).toList();

//           if (pendingUsers.isEmpty) {
//             return const Center(child: Text('No pending requests.'));
//           }

//           return ListView.builder(
//             itemCount: pendingUsers.length,
//             itemBuilder: (context, index) {
//               final userDoc = pendingUsers[index];
//               final userData = userDoc.data() as Map<String, dynamic>;
//               final userId = userDoc.id;
//               final pendingFields = _getPendingFields(userData);

//               return _buildUserCard(
//                 context,
//                 userId: userId,
//                 userEmail: userData['email'] ?? 'No email',
//                 pendingFields: pendingFields,
//               );
//             },
//           );
//         },
//       ),
//     );
//   }

//   bool _hasPendingFields(Map<String, dynamic> userData) {
//     const fieldKeys = ['profession', 'experience', 'city', 'address', 'bio', 'phone', 'previousWork', 'categories'];
//     return fieldKeys.any((field) => userData['${field}Status'] == 'pending');
//   }

//   List<Map<String, dynamic>> _getPendingFields(Map<String, dynamic> userData) {
//     List<Map<String, dynamic>> pendingFields = [];
//     const fieldKeys = ['profession', 'experience', 'city', 'address', 'bio', 'phone', 'previousWork', 'categories'];

//     for (final field in fieldKeys) {
//       final statusField = '${field}Status';
//       if (userData[statusField] == 'pending') {
//         pendingFields.add({
//           'field': field,
//           'statusField': statusField,
//           'value': userData[field],
//         });
//       }
//     }
//     return pendingFields;
//   }

//   Widget _buildUserCard(
//     BuildContext context, {
//     required String userId,
//     required String userEmail,
//     required List<Map<String, dynamic>> pendingFields,
//   }) {
//     return Card(
//       margin: const EdgeInsets.all(8.0),
//       child: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(userEmail, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 8),
//             ...pendingFields.map((field) => _buildPendingField(context, userId, field)),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildPendingField(
//     BuildContext context,
//     String userId,
//     Map<String, dynamic> fieldInfo,
//   ) {
//     final field = fieldInfo['field'];
//     final statusField = fieldInfo['statusField'];
//     final value = fieldInfo['value'];

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const SizedBox(height: 8),
//         Text('Field: ${field.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w500)),
//         if (field == 'previousWork') _buildImageGrid(value) else Text('Value: $value'),
//         _buildApprovalButtons(userId, statusField),
//         const Divider(),
//       ],
//     );
//   }

//   Widget _buildImageGrid(dynamic imageUrls) {
//     List<String> urls = [];
//     if (imageUrls is List) {
//       urls = imageUrls.whereType<String>().toList();
//     }

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Submitted Images:',
//           style: TextStyle(fontWeight: FontWeight.w500),
//         ),
//         const SizedBox(height: 8),
//         SizedBox(
//           height: 150,
//           child: ListView.builder(
//             scrollDirection: Axis.horizontal,
//             itemCount: urls.length,
//             itemBuilder: (context, index) {
//               return Padding(
//                 padding: const EdgeInsets.only(right: 8),
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(8),
//                   child: Image.network(
//                     urls[index],
//                     width: 150,
//                     height: 150,
//                     fit: BoxFit.cover,
//                     loadingBuilder: (context, child, loadingProgress) {
//                       if (loadingProgress == null) return child;
//                       return Container(
//                         width: 150,
//                         height: 150,
//                         color: Colors.grey[200],
//                         child: const Center(
//                           child: CircularProgressIndicator(),
//                         ),
//                       );
//                     },
//                     errorBuilder: (context, error, stackTrace) {
//                       return Container(
//                         width: 150,
//                         height: 150,
//                         color: Colors.grey[200],
//                         child: const Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(Icons.error, color: Colors.red),
//                             Text('Failed to load'),
//                           ],
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildApprovalButtons(String userId, String statusField) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.end,
//       children: [
//         OutlinedButton.icon(
//           icon: const Icon(Icons.check, color: Colors.green),
//           label: const Text('Approve'),
//           style: OutlinedButton.styleFrom(
//             foregroundColor: Colors.green,
//             side: const BorderSide(color: Colors.green),
//           ),
//           onPressed: () => _handleApproval(
//             userId: userId,
//             statusField: statusField,
//             status: 'approved',
//           ),
//         ),
//         const SizedBox(width: 8),
//         OutlinedButton.icon(
//           icon: const Icon(Icons.close, color: Colors.red),
//           label: const Text('Reject'),
//           style: OutlinedButton.styleFrom(
//             foregroundColor: Colors.red,
//             side: const BorderSide(color: Colors.red),
//           ),
//           onPressed: () => _handleApproval(
//             userId: userId,
//             statusField: statusField,
//             status: 'rejected',
//           ),
//         ),
//       ],
//     );
//   }

//   void _handleApproval({
//     required String userId,
//     required String statusField,
//     required String status,
//   }) {
//     FirebaseFirestore.instance.collection('users').doc(userId).update({
//       statusField: status,
//       'lastReviewed': FieldValue.serverTimestamp(),
//     });
//   }
// }

// Help Desk Screen
class HelpDeskScreen extends StatelessWidget {
  const HelpDeskScreen({super.key});

  Future<void> _launchEmail(BuildContext context, String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      // Optional: queryParameters like subject/body
    );

    try {
      final launched = await launchUrl(
        emailUri,
        mode: LaunchMode.externalApplication, // Force it to use Gmail
      );

      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch Gmail or email app.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: an error occurred')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('supportTickets').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final ticket = snapshot.data!.docs[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: AppColors.appBGColor,
              child: ListTile(
                leading: Icon(
                  Icons.support_agent,
                  color: _getStatusColor(ticket['status']),
                ),
                title: Text(ticket['subject'], style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('From: ${ticket['userEmail']}'),
                    Text('Status: ${ticket['status']}'),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showTicketDetails(context, ticket),
              ),
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.orange;
      case 'closed':
        return Colors.green;
      case 'pending':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _showTicketDetails(BuildContext context, DocumentSnapshot ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ticket['subject']),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(onTap: () => _launchEmail(context, ticket['userEmail']), child: Text('From: ${ticket['userEmail']}')),
              const SizedBox(height: 12),
              Text('Message:', style: TextStyle(fontWeight: FontWeight.w500)),
              Text(ticket['message']),
              const SizedBox(height: 20),
              Text('Status: ${ticket['status']}', style: TextStyle(color: _getStatusColor(ticket['status']), fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: appTextStyle14(AppColors.mainBlackTextColor),
              )),
          if (ticket['status'] != 'closed')
            TextButton(onPressed: () => _updateTicketStatus(context, ticket.id, 'closed'), child: Text('Mark Closed', style: appTextStyle14(AppColors.mainBlackTextColor))),
        ],
      ),
    );
  }

  void _updateTicketStatus(context, String ticketId, String status) {
    FirebaseFirestore.instance.collection('supportTickets').doc(ticketId).update({'status': status});
    Navigator.pop(context);
  }
}
