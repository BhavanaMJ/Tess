import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
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
            backgroundColor: AppColors.violet,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete memory: $e'),
            backgroundColor: AppColors.danger,
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
                content: Text('Personal memory successfully committed.'),
                backgroundColor: AppColors.cyan,
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
    final filtered = _filteredMemories;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PERSONAL MEMORY BANK',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: AppColors.cyan,
              ),
            ),
            Text(
              'Continuous Context Continuity // Active Retention',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10.0,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            tooltip: 'Synchronize Memories',
            onPressed: _loadMemories,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.cyan,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Encode Memory',
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: _openCreateSheet,
      ),
      body: RefreshIndicator(
        onRefresh: _loadMemories,
        color: AppColors.cyan,
        backgroundColor: AppColors.bgSecondary,
        child: Column(
          children: [
            // Search Bar & Categories
            _buildSearchAndFilters(),
            // Error banner if any
            if (_errorMessage != null) _buildErrorBanner(),
            // Content List or Empty State
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.cyan),
                    )
                  : filtered.isEmpty
                      ? _buildEmptyState()
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

  Widget _buildSearchAndFilters() {
    return Container(
      color: AppColors.bgSecondary,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Column(
        children: [
          // Search input
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
            decoration: InputDecoration(
              hintText: 'Filter neural memory entities...',
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13.0),
              prefixIcon: const Icon(Icons.search_rounded, size: 18.0, color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.bgSurface,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: const BorderSide(color: AppColors.cyan),
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
                      setState(() => _selectedCategory = cat);
                    },
                    labelStyle: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                    selectedColor: AppColors.violet,
                    backgroundColor: AppColors.bgSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: BorderSide(
                        color: isSelected ? AppColors.violet : AppColors.border,
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

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: AppColors.danger.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20.0),
          const SizedBox(width: 10.0),
          Expanded(
            child: Text(
              _errorMessage ?? 'Memory synchronization failure',
              style: const TextStyle(color: AppColors.danger, fontSize: 12.0),
            ),
          ),
          TextButton(
            onPressed: _loadMemories,
            child: const Text('Retry', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64.0,
              height: 64.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cyan.withOpacity(0.1),
                border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
              ),
              child: const Icon(
                Icons.psychology_outlined,
                size: 32.0,
                color: AppColors.cyan,
              ),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'No Personal Memories Stored',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8.0),
            const Text(
              'Directives and preferences communicated to TESS will appear here to provide continuous personalized intelligence.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13.0,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20.0),
            OutlinedButton.icon(
              onPressed: _openCreateSheet,
              icon: const Icon(Icons.add, size: 16.0),
              label: const Text('Encode First Memory'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.cyan,
                side: const BorderSide(color: AppColors.cyan),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
