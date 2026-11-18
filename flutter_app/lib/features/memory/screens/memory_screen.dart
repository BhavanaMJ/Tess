import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/memory_model.dart';
import '../services/memory_service.dart';
import '../widgets/create_memory_sheet.dart';
import '../widgets/memory_card.dart';

/// MemoryScreen manages continuous personal memory entities for TESS context continuity
class MemoryScreen extends StatefulWidget {
  final MemoryService? memoryService;

  const MemoryScreen({super.key, this.memoryService});

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  late final MemoryService _memoryService;
  List<MemoryModel> _memories = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedCategory = 'ALL';
  String _searchQuery = '';

  final List<String> _categories = [
    'ALL',
    'WORK',
    'PERSONAL',
    'PREFERENCE',
    'HEALTH',
    'PROJECT',
  ];

  @override
  void initState() {
    super.initState();
    _memoryService = widget.memoryService ?? MemoryService();
    _loadMemories();
  }

  Future<void> _loadMemories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _memoryService.getMemories();
      if (mounted) {
        setState(() {
          _memories = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleDelete(String memoryId) async {
    try {
      await _memoryService.deleteMemory(memoryId);
      setState(() {
        _memories.removeWhere((m) => m.id == memoryId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Memory entity purged from neural context.'),
            backgroundColor: AppColors.tessTeal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete memory: $e'),
            backgroundColor: AppColors.accentDanger,
          ),
        );
      }
    }
  }

  void _openCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CreateMemorySheet(
        onSave: ({
          required String category,
          required String content,
          required int importance,
        }) async {
          final newMem = await _memoryService.createMemory(
            category: category,
            content: content,
            importance: importance,
          );
          if (mounted) {
            setState(() {
              _memories.insert(0, newMem);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Personal memory successfully saved.'),
                backgroundColor: AppColors.tessTeal,
              ),
            );
          }
        },
      ),
    );
  }

  List<MemoryModel> get _filteredMemories {
    return _memories.where((m) {
      final matchesCategory = _selectedCategory == 'ALL' ||
          m.category.toUpperCase() == _selectedCategory;
      final matchesQuery = _searchQuery.isEmpty ||
          m.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.category.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filtered = _filteredMemories;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Memory Bank',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            Text(
              'Continuous Context & Personal Preferences',
              style: TextStyle(
                fontSize: 11.0,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
            tooltip: 'Synchronize Memories',
            onPressed: _loadMemories,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.tessTeal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Remember This',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        onPressed: _openCreateSheet,
      ),
      body: RefreshIndicator(
        onRefresh: _loadMemories,
        color: AppColors.tessTeal,
        child: Column(
          children: [
            // Search Bar & Categories
            _buildSearchAndFilters(isDark),
            // Error banner if any
            if (_errorMessage != null) _buildErrorBanner(),
            // Content List or Empty State
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.tessTeal),
                    )
                  : filtered.isEmpty
                      ? _buildEmptyState(isDark)
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(top: 8.0, bottom: 80.0),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final mem = filtered[index];
                            return MemoryCard(
                              memory: mem,
                              onDelete: () => _handleDelete(mem.id),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(bool isDark) {
    final barBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final inputBg = isDark ? AppColors.darkSurfaceElevated : AppColors.lightSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return Container(
      color: barBg,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10.0),
      child: Column(
        children: [
          // Search input
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
            style: TextStyle(color: textPrimary, fontSize: 13.5),
            decoration: InputDecoration(
              hintText: 'Search personal memories...',
              hintStyle: TextStyle(color: textMuted, fontSize: 13.0),
              prefixIcon: Icon(Icons.search_rounded, size: 18.0, color: textMuted),
              filled: true,
              fillColor: inputBg,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
              border: OutlineInputBorder(
                borderRadius: AppRadius.pill,
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.pill,
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: AppRadius.pill,
                borderSide: BorderSide(color: AppColors.tessTeal),
              ),
            ),
          ),
          const SizedBox(height: 10.0),
          // Category chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedCategory = cat);
                    },
                    labelStyle: TextStyle(
                      fontSize: 11.0,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    ),
                    selectedColor: AppColors.tessTeal,
                    backgroundColor: inputBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.pill,
                      side: BorderSide(
                        color: isSelected ? AppColors.tessTeal : borderColor,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Container(
              width: 56.0,
              height: 56.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.tessTeal.withOpacity(0.12),
                border: Border.all(color: AppColors.tessTeal.withOpacity(0.3)),
              ),
              child: const Icon(
                Icons.psychology_outlined,
                size: 28.0,
                color: AppColors.tessTeal,
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              _searchQuery.isNotEmpty ? 'No Memories Found' : 'No Personal Memories Stored',
              style: TextStyle(
                fontSize: 15.0,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 6.0),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No memories matched "$_searchQuery" in category $_selectedCategory.'
                  : 'Tap "+ Remember This" to teach TESS your work habits, preferences, and personal notes.',
              textAlign: TextAlign.center,
              style: TextStyle(color: textSecondary, fontSize: 13.0, height: 1.4),
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 18.0),
              OutlinedButton.icon(
                onPressed: _openCreateSheet,
                icon: const Icon(Icons.add, size: 16.0),
                label: const Text('Encode First Memory'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.tessTeal,
                  side: const BorderSide(color: AppColors.tessTeal),
                  shape: const RoundedRectangleBorder(borderRadius: AppRadius.pill),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppColors.accentDanger.withOpacity(0.1),
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.accentDanger.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.accentDanger, size: 18.0),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              _errorMessage ?? 'Memory synchronization failed',
              style: const TextStyle(color: AppColors.accentDanger, fontSize: 12.0),
            ),
          ),
          TextButton(
            onPressed: _loadMemories,
            child: const Text('Retry', style: TextStyle(color: AppColors.accentDanger)),
          ),
        ],
      ),
    );
  }
}
