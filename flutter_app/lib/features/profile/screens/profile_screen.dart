import 'package:flutter/material.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../shared/mascot/tess_mascot.dart';
import '../../../shared/mascot/tess_mascot_state.dart';
import '../../../shared/widgets/tess_button.dart';
import '../../../shared/widgets/tess_card.dart';
import '../../memory/screens/memory_screen.dart';

/// Profile & Settings Screen.
/// Provides account details, persistent Theme Selector (Light, Dark, System),
/// Companion telemetry, and system actions.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        title: Text(
          'Sign Out of TESS',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        content: Text(
          'Are you sure you wish to end your session? Your synchronized memories and tasks will remain safely stored.',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w600)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = _authService.currentUser;
    final userEmail = user?.email ?? 'commander@tess.ai';
    final metadata = user?.userMetadata ?? {};
    final callsign = metadata['callsign'] as String? ?? 'Commander';
    final userId = user?.id ?? 'simulated_user_id';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. User Identity & Companion Presence Card
            TessCard(
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppColors.vibrantMint, AppColors.tessTeal],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.vibrantMint.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        userEmail.isNotEmpty ? userEmail[0].toUpperCase() : 'C',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          callsign,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          userEmail,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.tessTeal,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${userId.length > 16 ? "${userId.substring(0, 16)}..." : userId}',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const TessMascot(
                    state: TessMascotState.idle,
                    size: 38.0,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Theme Mode Selector Card (Light, Dark, System)
            AnimatedBuilder(
              animation: ThemeController.instance,
              builder: (context, _) {
                final currentMode = ThemeController.instance.themeMode;

                return TessCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.palette_outlined,
                            size: 18,
                            color: AppColors.tessTeal,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'APPEARANCE & THEME',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildThemeOption(
                              context: context,
                              label: 'Light',
                              icon: Icons.wb_sunny_rounded,
                              isSelected: currentMode == ThemeMode.light,
                              onTap: () => ThemeController.instance.setThemeMode(ThemeMode.light),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildThemeOption(
                              context: context,
                              label: 'Dark',
                              icon: Icons.nightlight_round,
                              isSelected: currentMode == ThemeMode.dark,
                              onTap: () => ThemeController.instance.setThemeMode(ThemeMode.dark),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildThemeOption(
                              context: context,
                              label: 'System',
                              icon: Icons.settings_suggest_rounded,
                              isSelected: currentMode == ThemeMode.system,
                              onTap: () => ThemeController.instance.setThemeMode(ThemeMode.system),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // 3. Personal Memory Bank Shortcut
            TessCard(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MemoryScreen()),
                );
              },
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.vibrantMint.withValues(alpha: isDark ? 0.20 : 0.12),
                      border: Border.all(
                        color: AppColors.vibrantMint.withValues(alpha: isDark ? 0.40 : 0.30),
                      ),
                    ),
                    child: const Icon(Icons.psychology_outlined, color: AppColors.tessTeal, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Personal Memory Bank',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Browse semantic preferences & episodic continuity',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. Runtime & Health Telemetry Card
            TessCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.hub_outlined, size: 16, color: AppColors.tessTeal),
                          const SizedBox(width: 8),
                          Text(
                            'SYSTEM TELEMETRY',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: _checkBackendConnection,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Text(
                            _isCheckingBackend ? 'CHECKING...' : 'TEST NODE',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.tessTeal,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSettingRow(
                    context: context,
                    icon: Icons.computer_rounded,
                    label: 'Client Architecture',
                    value: 'Flutter 3.50 (Dart 3)',
                  ),
                  const Divider(height: 16),
                  _buildSettingRow(
                    context: context,
                    icon: Icons.dns_outlined,
                    label: 'FastAPI Backend',
                    value: _backendOnline == null
                        ? 'Connecting...'
                        : (_backendOnline! ? 'Healthy (HTTP 200)' : 'Unreachable'),
                    statusColor: _backendOnline == true ? AppColors.success : AppColors.danger,
                  ),
                  const Divider(height: 16),
                  _buildSettingRow(
                    context: context,
                    icon: Icons.shield_outlined,
                    label: 'Identity Vault',
                    value: 'Supabase GoTrue JWT',
                  ),
                  const Divider(height: 16),
                  _buildSettingRow(
                    context: context,
                    icon: Icons.lock_clock_outlined,
                    label: 'Session Persistence',
                    value: 'Hardware Encrypted',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 5. Sign Out Button
            TessButton(
              label: 'Sign Out Session',
              icon: Icons.logout_rounded,
              variant: TessButtonVariant.destructive,
              onPressed: _confirmSignOut,
            ),
            const SizedBox(height: 16),

            // 6. Build Info Footer
            Center(
              child: Text(
                '${AppConstants.appName} v${AppConstants.appVersion} • Expressive Companion Edition',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedBg = isDark
        ? AppColors.vibrantMint.withValues(alpha: 0.18)
        : AppColors.vibrantMint.withValues(alpha: 0.14);
    const selectedBorder = AppColors.vibrantMint;
    final unselectedBg = isDark ? AppColors.darkSurfaceSubtle : AppColors.lightSurfaceSubtle;
    final unselectedBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : unselectedBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? selectedBorder : unselectedBorder,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? AppColors.tessTeal
                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? AppColors.vibrantMint : AppColors.tessTeal)
                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    Color? statusColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(icon, size: 16, color: statusColor ?? AppColors.tessTeal),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: statusColor ?? (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
            fontWeight: statusColor != null ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
