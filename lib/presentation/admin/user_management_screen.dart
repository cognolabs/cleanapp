import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cognoapp/presentation/admin/admin_provider.dart';
import 'package:cognoapp/presentation/common_widgets/app_bar.dart';
import 'package:cognoapp/presentation/common_widgets/app_button.dart';
import 'package:cognoapp/presentation/zone_ward/zone_ward_provider.dart';
import 'package:cognoapp/core/widgets/custom_snackbar.dart';
import 'package:cognoapp/config/theme.dart';
import 'package:cognoapp/data/models/admin/user_detail_model.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    
    // Fetch users when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).fetchUsers();
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);
    final users = adminProvider.filteredUsers;
    
    return Scaffold(
      appBar: ModernAppBar(
        title: 'User Management',
        backgroundColor: Colors.white,
        showBackButton: true,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          adminProvider.setSearchQuery('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.neutral300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.neutral300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.primaryColor),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
              onChanged: (value) {
                adminProvider.setSearchQuery(value);
              },
            ),
          ),
          
          // Stats cards
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                _buildStatsCard(
                  icon: Icons.people,
                  title: 'Total Users',
                  value: adminProvider.users.length.toString(),
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 12),
                _buildStatsCard(
                  icon: Icons.admin_panel_settings,
                  title: 'Admins',
                  value: adminProvider.users.where((user) => user.isAdmin).length.toString(),
                  color: AppTheme.warningColor,
                ),
              ],
            ),
          ),
          
          // Loading indicator
          if (adminProvider.isLoading && adminProvider.users.isEmpty)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          // Error message
          else if (adminProvider.hasError && adminProvider.users.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppTheme.errorColor,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading users',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        adminProvider.errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      text: 'Retry',
                      onPressed: () {
                        adminProvider.fetchUsers();
                      },
                    ),
                  ],
                ),
              ),
            )
          // User list
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => adminProvider.fetchUsers(),
                child: users.isEmpty
                    ? const Center(
                        child: Text('No users found'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          return _buildUserCard(user);
                        },
                      ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildStatsCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(UserDetailModel user) {
    final zoneWardText = user.zoneId != null && user.wardId != null
        ? 'Zone ${user.zoneId} - Ward ${user.wardId}'
        : 'No zone/ward assigned';
        
    final statusColor = user.status == 'active'
        ? AppTheme.successColor
        : AppTheme.errorColor;
        
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          _showUserDetailBottomSheet(context, user);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // User avatar
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // User info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                user.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (user.isAdmin)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Admin',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              // Zone/Ward and Status information
              Row(
                children: [
                  // Zone/Ward info
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: user.zoneId != null && user.wardId != null
                              ? AppTheme.successColor
                              : AppTheme.warningColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            zoneWardText,
                            style: TextStyle(
                              fontSize: 14,
                              color: user.zoneId != null && user.wardId != null
                                  ? AppTheme.textPrimaryColor
                                  : AppTheme.warningColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          user.status?.toUpperCase() ?? 'UNKNOWN',
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUserDetailBottomSheet(BuildContext context, UserDetailModel user) {
    // Validate user data to prevent crashes
    if (user.id.isEmpty) {
      CustomSnackbar.showError(
        context: context,
        message: 'Invalid user data. Please refresh the user list.',
      );
      return;
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return UserDetailBottomSheet(user: user);
      },
    );
  }
}

class UserDetailBottomSheet extends StatefulWidget {
  final UserDetailModel user;

  const UserDetailBottomSheet({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  _UserDetailBottomSheetState createState() => _UserDetailBottomSheetState();
}

class _UserDetailBottomSheetState extends State<UserDetailBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);
    final zoneWardProvider = Provider.of<ZoneWardProvider>(context);
    
    final zoneWardText = widget.user.zoneId != null && widget.user.wardId != null
        ? 'Zone ${widget.user.zoneId} - Ward ${widget.user.wardId}'
        : 'No zone/ward assigned';
        
    final statusColor = widget.user.status == 'active'
        ? AppTheme.successColor
        : AppTheme.errorColor;
    
    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: AppTheme.neutral300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          
          // User info
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // User avatar
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      child: Text(
                        widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // User info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.user.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.user.email,
                            style: TextStyle(
                              color: AppTheme.textSecondaryColor,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: widget.user.isAdmin
                                      ? AppTheme.primaryColor.withOpacity(0.1)
                                      : AppTheme.neutral200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  widget.user.isAdmin ? 'Admin' : 'User',
                                  style: TextStyle(
                                    color: widget.user.isAdmin
                                        ? AppTheme.primaryColor
                                        : AppTheme.textSecondaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: statusColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.user.status?.toUpperCase() ?? 'UNKNOWN',
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Created date
                _buildDetailItem(
                  icon: Icons.calendar_today,
                  title: 'Created on',
                  value: widget.user.createdAt != null
                      ? '${widget.user.createdAt!.day}/${widget.user.createdAt!.month}/${widget.user.createdAt!.year}'
                      : 'Unknown',
                ),
                
                const SizedBox(height: 12),
                
                // Last login
                _buildDetailItem(
                  icon: Icons.access_time,
                  title: 'Last login',
                  value: widget.user.lastLogin != null
                      ? '${widget.user.lastLogin!.day}/${widget.user.lastLogin!.month}/${widget.user.lastLogin!.year} at ${widget.user.lastLogin!.hour}:${widget.user.lastLogin!.minute.toString().padLeft(2, '0')}'
                      : 'Never',
                ),
                
                const SizedBox(height: 12),
                
                // Zone/Ward
                _buildDetailItem(
                  icon: Icons.location_on,
                  title: 'Zone/Ward',
                  value: zoneWardText,
                  valueColor: widget.user.zoneId != null && widget.user.wardId != null
                      ? null
                      : AppTheme.warningColor,
                ),
                
                const SizedBox(height: 24),
                
                // Action Buttons
                Row(
                  children: [
                    // Change Zone/Ward button
                    Expanded(
                      child: AppButton(
                        text: 'Change Zone/Ward',
                        icon: Icons.edit_location_alt,
                        type: ButtonType.secondary,
                        onPressed: () {
                          Navigator.pop(context);
                          _showZoneWardSelectionDialog(context, widget.user);
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Toggle user status button
                Row(
                  children: [
                    // Toggle status button
                    Expanded(
                      child: AppButton(
                        text: widget.user.status == 'active'
                            ? 'Deactivate User'
                            : 'Activate User',
                        icon: widget.user.status == 'active'
                            ? Icons.person_off
                            : Icons.person,
                        type: ButtonType.warning,
                        onPressed: () {
                          _showConfirmStatusChangeDialog(
                            context, 
                            widget.user,
                            widget.user.status == 'active' ? 'inactive' : 'active',
                          );
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Toggle admin role button
                Row(
                  children: [
                    // Toggle role button
                    Expanded(
                      child: AppButton(
                        text: widget.user.isAdmin
                            ? 'Remove Admin Role'
                            : 'Make Admin',
                        icon: widget.user.isAdmin
                            ? Icons.person_off
                            : Icons.admin_panel_settings,
                        type: ButtonType.error,
                        onPressed: () {
                          _showConfirmRoleChangeDialog(
                            context, 
                            widget.user,
                            widget.user.isAdmin ? 'user' : 'admin',
                          );
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: AppTheme.textSecondaryColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  void _showZoneWardSelectionDialog(BuildContext context, UserDetailModel user) {
    // Get the zone ward provider
    final zoneWardProvider = Provider.of<ZoneWardProvider>(context, listen: false);
    
    // Initialize it to fetch zones
    zoneWardProvider.initialize();
    
    // Show the dialog
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Text('Change Zone/Ward for ${user.name}'),
        content: const SizedBox(
          width: double.maxFinite,
          child: ZoneWardSelectionDialog(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          Consumer<ZoneWardProvider>(
            builder: (context, provider, child) {
              return TextButton(
                onPressed: provider.selectedZoneId != null && provider.selectedWardId != null
                    ? () async {
                        final adminProvider = Provider.of<AdminProvider>(context, listen: false);
                        final success = await adminProvider.updateUserZoneWard(
                          user.id,
                          provider.selectedZoneId!,
                          provider.selectedWardId!,
                        );
                        
                        if (context.mounted) {
                          Navigator.pop(context);
                          if (success) {
                            CustomSnackbar.show(
                              context: context,
                              message: 'Zone/Ward updated successfully',
                            );
                          }
                        }
                      }
                    : null,
                child: const Text('Update'),
              );
            },
          ),
        ],
      ),
    );
  }
  
  void _showConfirmStatusChangeDialog(BuildContext context, UserDetailModel user, String newStatus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${newStatus == 'active' ? 'Activate' : 'Deactivate'} User'),
        content: Text(
          'Are you sure you want to ${newStatus == 'active' ? 'activate' : 'deactivate'} ${user.name}?'
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final adminProvider = Provider.of<AdminProvider>(context, listen: false);
              final success = await adminProvider.updateUserStatus(user.id, newStatus);
              
              if (context.mounted) {
                Navigator.pop(context); // Close bottom sheet
                if (success) {
                  CustomSnackbar.show(
                    context: context,
                    message: 'User ${newStatus == 'active' ? 'activated' : 'deactivated'} successfully',
                  );
                }
              }
            },
            child: Text(
              newStatus == 'active' ? 'Activate' : 'Deactivate',
              style: TextStyle(
                color: newStatus == 'active' ? AppTheme.successColor : AppTheme.errorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showConfirmRoleChangeDialog(BuildContext context, UserDetailModel user, String newRole) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${newRole == 'admin' ? 'Make Admin' : 'Remove Admin Role'}'),
        content: Text(
          'Are you sure you want to ${newRole == 'admin' ? 'make' : 'remove'} ${user.name} ${newRole == 'admin' ? 'an admin' : 'from admin role'}?'
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final adminProvider = Provider.of<AdminProvider>(context, listen: false);
              final success = await adminProvider.updateUserRole(user.id, newRole);
              
              if (context.mounted) {
                Navigator.pop(context); // Close bottom sheet
                if (success) {
                  CustomSnackbar.show(
                    context: context,
                    message: newRole == 'admin'
                        ? '${user.name} is now an admin'
                        : 'Admin role removed from ${user.name}',
                  );
                }
              }
            },
            child: Text(
              newRole == 'admin' ? 'Make Admin' : 'Remove Admin',
              style: TextStyle(
                color: AppTheme.errorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ZoneWardSelectionDialog extends StatefulWidget {
  const ZoneWardSelectionDialog({Key? key}) : super(key: key);

  @override
  _ZoneWardSelectionDialogState createState() => _ZoneWardSelectionDialogState();
}

class _ZoneWardSelectionDialogState extends State<ZoneWardSelectionDialog> {
  @override
  Widget build(BuildContext context) {
    final zoneWardProvider = Provider.of<ZoneWardProvider>(context);
    
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (zoneWardProvider.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (zoneWardProvider.hasError)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppTheme.errorColor,
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      zoneWardProvider.errorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.errorColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        zoneWardProvider.fetchZones();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Zone selection
                const Text(
                  'Zone',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.neutral300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: zoneWardProvider.selectedZoneId,
                      hint: const Text('Select a zone'),
                      isExpanded: true,
                      items: zoneWardProvider.zones.isNotEmpty 
                        ? zoneWardProvider.zones.map((zone) {
                            return DropdownMenuItem<int>(
                              value: zone,
                              child: Text('Zone $zone'),
                            );
                          }).toList()
                        : [
                            const DropdownMenuItem<int>(
                              value: null,
                              enabled: false,
                              child: Text('No zones available'),
                            ),
                          ],
                      onChanged: (value) {
                        if (value != null) {
                          zoneWardProvider.selectZone(value);
                        }
                      },
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Ward selection
                const Text(
                  'Ward',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.neutral300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: zoneWardProvider.selectedWardId,
                      hint: const Text('Select a ward'),
                      isExpanded: true,
                      items: zoneWardProvider.wards.isNotEmpty
                        ? zoneWardProvider.wards.map((ward) {
                            return DropdownMenuItem<int>(
                              value: ward.wardId,
                              child: Text('${ward.name} (Ward ${ward.wardId})'),
                            );
                          }).toList()
                        : [
                            const DropdownMenuItem<int>(
                              value: null,
                              enabled: false,
                              child: Text('No wards available'),
                            ),
                          ],
                      onChanged: zoneWardProvider.selectedZoneId == null
                          ? null
                          : (value) {
                              if (value != null) {
                                zoneWardProvider.selectWard(value);
                              }
                            },
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
