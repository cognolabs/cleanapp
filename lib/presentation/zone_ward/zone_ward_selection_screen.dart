import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cognoapp/core/widgets/custom_snackbar.dart';
import 'package:cognoapp/presentation/zone_ward/zone_ward_provider.dart';
import 'package:cognoapp/presentation/authentication/auth_provider.dart';
import 'package:cognoapp/presentation/common_widgets/app_button.dart';
import 'package:cognoapp/config/theme.dart';

class ZoneWardSelectionScreen extends StatefulWidget {
  const ZoneWardSelectionScreen({Key? key}) : super(key: key);

  @override
  _ZoneWardSelectionScreenState createState() => _ZoneWardSelectionScreenState();
}

class _ZoneWardSelectionScreenState extends State<ZoneWardSelectionScreen> {
  @override
  void initState() {
    super.initState();
    
    // Fetch zones when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ZoneWardProvider>(context, listen: false).fetchZones();
    });
  }

  @override
  Widget build(BuildContext context) {
    final zoneWardProvider = Provider.of<ZoneWardProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Zone and Ward'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        // Remove back button to force selection
        automaticallyImplyLeading: false,
      ),
      body: zoneWardProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : zoneWardProvider.hasError
              ? _buildErrorView(zoneWardProvider.errorMessage)
              : _buildSelectionContent(context, zoneWardProvider, authProvider),
    );
  }

  Widget _buildErrorView(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppTheme.errorColor,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This could be due to network issues or server connection problems. Please make sure you are connected to the internet.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'Retry',
              onPressed: () {
                Provider.of<ZoneWardProvider>(context, listen: false).fetchZones();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionContent(BuildContext context, ZoneWardProvider provider, AuthProvider authProvider) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instructions
          Text(
            'Please select your zone and ward',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'This helps us show relevant issues in your area',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Zone selection
          Text(
            'Zone',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          
          const SizedBox(height: 8),
          
          _buildZoneSelector(provider),
          
          const SizedBox(height: 24),
          
          // Ward selection (shows only when zone is selected)
          if (provider.selectedZoneId != null) ...[
            Text(
              'Ward',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            
            const SizedBox(height: 8),
            
            _buildWardSelector(provider),
          ],
          
          const Spacer(),
          
          // Continue button (enabled only when both zone and ward are selected)
          AppButton(
            text: 'Continue to Dashboard',
            onPressed: provider.selectedZoneId != null && provider.selectedWardId != null
                ? () {
                    // Mark zone/ward selection as complete
                    authProvider.completeZoneWardSelection();
                    
                    // Check if the user is an admin and redirect to admin dashboard
                    if (authProvider.isAdmin) {
                      Navigator.pushReplacementNamed(context, '/admin/dashboard');
                    } else {
                      Navigator.pushReplacementNamed(context, '/dashboard');
                    }
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildZoneSelector(ZoneWardProvider provider) {
    // Create a properly formatted list of dropdown items
    final List<DropdownMenuItem<int>> dropdownItems = [];
    
    if (provider.zones.isEmpty) {
      // Add a placeholder item when no zones are available
      dropdownItems.add(const DropdownMenuItem<int>(
        value: null,
        enabled: false,
        child: Text('No zones available'),
      ));
    } else {
      // Add actual zone items
      for (int zoneId in provider.zones) {
        dropdownItems.add(DropdownMenuItem<int>(
          value: zoneId,
          child: Text('Zone $zoneId'),
        ));
      }
    }
    
    return AbsorbPointer(
      // Enable the widget only if there are zones available
      absorbing: provider.zones.isEmpty,
      child: Container(
        height: 50, // Fixed height to ensure it's tappable
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.neutral300),
          color: Colors.white, // Ensure a visible background
        ),
        child: DropdownButtonHideUnderline(
          child: ButtonTheme(
            alignedDropdown: true,
            child: DropdownButton<int>(
              value: provider.selectedZoneId,
              isExpanded: true,
              hint: const Text('Select a zone'),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              borderRadius: BorderRadius.circular(12),
              icon: const Icon(Icons.arrow_drop_down),
              iconSize: 24,
              elevation: 16,
              items: dropdownItems,
              onChanged: provider.zones.isEmpty ? null : (int? zoneId) {
                if (zoneId != null) {
                  provider.selectZone(zoneId);
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWardSelector(ZoneWardProvider provider) {
    // Create a properly formatted list of dropdown items
    final List<DropdownMenuItem<int>> dropdownItems = [];
    
    if (provider.wards.isEmpty) {
      // Add a placeholder item when no wards are available
      dropdownItems.add(const DropdownMenuItem<int>(
        value: null,
        enabled: false,
        child: Text('No wards available'),
      ));
    } else {
      // Add actual ward items
      for (var ward in provider.wards) {
        dropdownItems.add(DropdownMenuItem<int>(
          value: ward.wardId,
          child: Text('${ward.name} (Ward ${ward.wardId})'),
        ));
      }
    }
    
    return AbsorbPointer(
      // Enable the widget only if there are wards available
      absorbing: provider.wards.isEmpty,
      child: Container(
        height: 50, // Fixed height to ensure it's tappable
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.neutral300),
          color: Colors.white, // Ensure a visible background
        ),
        child: DropdownButtonHideUnderline(
          child: ButtonTheme(
            alignedDropdown: true,
            child: DropdownButton<int>(
              value: provider.selectedWardId,
              isExpanded: true,
              hint: const Text('Select a ward'),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              borderRadius: BorderRadius.circular(12),
              icon: const Icon(Icons.arrow_drop_down),
              iconSize: 24,
              elevation: 16,
              items: dropdownItems,
              onChanged: provider.wards.isEmpty ? null : (int? wardId) {
                if (wardId != null) {
                  provider.selectWard(wardId);
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
