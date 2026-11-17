import 'package:flutter/material.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/tess_button.dart';
import '../../../shared/widgets/tess_card.dart';

class ProfileScreen extends StatefulWidget {
  final AuthService? authService;
  final ApiClient? apiClient;

  const ProfileScreen({
    super.key,
    this.authService,
    this.apiClient,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final AuthService _authService;
  late final ApiClient _apiClient;
  bool _isCheckingBackend = false;
  bool? _backendOnline;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _apiClient = widget.apiClient ?? ApiClient();
    _checkBackendConnection();
  }

  Future<void> _checkBackendConnection() async {
    setState(() => _isCheckingBackend = true);
    final isHealthy = await _apiClient.checkHealth();
    if (mounted) {
      setState(() {
        _backendOnline = isHealthy;
        _isCheckingBackend = false;
      });
    }
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        title: const Text(
          'TERMINATE NEURAL SESSION',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontFamily: 'monospace',
            color: AppColors.textPrimary,
          ),
        ),
        content: const Text(
          'Are you certain you wish to sign out? Unsynchronized local cache will remain secure on this device.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DISCONNECT', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _authService.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final userEmail = user?.email ?? 'commander@tess.ai';
    final metadata = user?.userMetadata ?? {};
    final callsign = metadata['callsign'] as String? ?? 'Commander';
    final userId = user?.id ?? 'simulated_user_id';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TESS IDENTITY & SYSTEM',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // User Persona Card
            TessCard(
              borderColor: AppColors.violet.withValues(alpha: 0.3),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppColors.violet, AppColors.cyan],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.violet.withValues(alpha: 0.4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        userEmail.isNotEmpty ? userEmail[0].toUpperCase() : 'C',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          callsign,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          userEmail,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.cyan,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'UID: ${userId.length > 18 ? "${userId.substring(0, 18)}..." : userId}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // System Telemetry Card
            TessCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'RUNTIME ENVIRONMENT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: AppColors.textPrimary,
                          fontFamily: 'monospace',
                        ),
                      ),
                      InkWell(
                        onTap: _checkBackendConnection,
                        child: Text(
                          _isCheckingBackend ? 'CHECKING...' : 'PING BACKEND',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.cyan,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSettingRow(Icons.phone_android, 'Client Platform', 'Flutter 3 (Dart 3)'),
                  const Divider(color: AppColors.border, height: 16),
                  _buildSettingRow(
                    Icons.dns,
                    'FastAPI Node',
                    _backendOnline == null
                        ? 'Checking...'
                        : (_backendOnline! ? 'Online (HTTP 200)' : 'Offline / Unreachable'),
                    statusColor: _backendOnline == true ? AppColors.success : AppColors.danger,
                  ),
                  const Divider(color: AppColors.border, height: 16),
                  _buildSettingRow(Icons.lock_outline, 'Auth Provider', 'Supabase GoTrue (JWT)'),
                  const Divider(color: AppColors.border, height: 16),
                  _buildSettingRow(Icons.vpn_key_outlined, 'Session State', 'Active & Persisted'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout Action
            TessButton(
              label: 'Terminate Session',
              icon: Icons.logout_rounded,
              variant: TessButtonVariant.cyan,
              onPressed: _confirmSignOut,
            ),
            const SizedBox(height: 16),

            // Build Info
            const Center(
              child: Text(
                '${AppConstants.appName} v${AppConstants.appVersion} • Supabase Auth Active',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow(
    IconData icon,
    String label,
    String value, {
    Color? statusColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: statusColor ?? AppColors.cyan),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            color: statusColor ?? AppColors.textMuted,
            fontFamily: 'monospace',
            fontWeight: statusColor != null ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
