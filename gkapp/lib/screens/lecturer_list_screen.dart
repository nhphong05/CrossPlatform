import 'package:flutter/material.dart';

import '../models/lecturer.dart';
import '../services/lecturer_repository.dart';
import '../widgets/lecturer_card.dart';
import 'lecturer_form_dialog.dart';

enum _ClassFilter { all, withClasses, withoutClasses }

enum _LecturerSort {
  nameAscending,
  nameDescending,
  idAscending,
  idDescending,
  classesAscending,
  classesDescending,
}

class LecturerListScreen extends StatefulWidget {
  const LecturerListScreen({
    required this.repository,
    this.onLogout,
    super.key,
  });

  final LecturerRepository repository;
  final VoidCallback? onLogout;

  @override
  State<LecturerListScreen> createState() => _LecturerListScreenState();
}

class _LecturerListScreenState extends State<LecturerListScreen> {
  final _searchController = TextEditingController();
  List<Lecturer> _lecturers = [];
  bool _isLoading = true;
  String? _loadError;
  _ClassFilter _classFilter = _ClassFilter.all;
  _LecturerSort _lecturerSort = _LecturerSort.nameAscending;

  @override
  void initState() {
    super.initState();
    _loadLecturers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLecturers() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final lecturers = await widget.repository.getAll();
      if (!mounted) return;
      setState(() {
        _lecturers = lecturers;
        _isLoading = false;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.toString();
        _isLoading = false;
      });
    }
  }

  List<Lecturer> get _filteredLecturers {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = _lecturers.where((lecturer) {
      final matchesSearch =
          query.isEmpty ||
          lecturer.id.toLowerCase().contains(query) ||
          lecturer.fullname.toLowerCase().contains(query);
      final matchesClassFilter = switch (_classFilter) {
        _ClassFilter.all => true,
        _ClassFilter.withClasses => lecturer.sumClass > 0,
        _ClassFilter.withoutClasses => lecturer.sumClass == 0,
      };
      return matchesSearch && matchesClassFilter;
    }).toList();

    filtered.sort((first, second) {
      final comparison = switch (_lecturerSort) {
        _LecturerSort.nameAscending => first.fullname.toLowerCase().compareTo(
          second.fullname.toLowerCase(),
        ),
        _LecturerSort.nameDescending => second.fullname.toLowerCase().compareTo(
          first.fullname.toLowerCase(),
        ),
        _LecturerSort.idAscending => first.id.toLowerCase().compareTo(
          second.id.toLowerCase(),
        ),
        _LecturerSort.idDescending => second.id.toLowerCase().compareTo(
          first.id.toLowerCase(),
        ),
        _LecturerSort.classesAscending => first.sumClass.compareTo(
          second.sumClass,
        ),
        _LecturerSort.classesDescending => second.sumClass.compareTo(
          first.sumClass,
        ),
      };
      if (comparison != 0) return comparison;
      return first.id.toLowerCase().compareTo(second.id.toLowerCase());
    });
    return filtered;
  }

  Future<void> _openForm({Lecturer? lecturer}) async {
    final result = await showDialog<LecturerDraft>(
      context: context,
      builder: (_) => LecturerFormDialog(lecturer: lecturer),
    );
    if (result == null || !mounted) return;

    try {
      if (lecturer == null) {
        await widget.repository.create(result);
      } else {
        await widget.repository.update(
          Lecturer(
            id: lecturer.id,
            fullname: result.fullname,
            image: result.image,
            sumClass: result.sumClass,
          ),
        );
      }
      if (!mounted) return;
      _showMessage(
        lecturer == null ? 'Đã thêm giảng viên.' : 'Đã cập nhật giảng viên.',
      );
      await _loadLecturers();
    } on Exception catch (error) {
      if (mounted) _showMessage(error.toString(), isError: true);
    }
  }

  Future<void> _confirmDelete(Lecturer lecturer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa giảng viên?'),
        content: Text(
          'Bạn có chắc muốn xóa "${lecturer.fullname}" (${lecturer.id}) không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await widget.repository.delete(lecturer.id);
      if (!mounted) return;
      _showMessage('Đã xóa giảng viên.');
      await _loadLecturers();
    } on Exception catch (error) {
      if (mounted) _showMessage(error.toString(), isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredLecturers;
    final totalClasses = _lecturers.fold<int>(
      0,
      (total, lecturer) => total + lecturer.sumClass,
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                  sliver: SliverToBoxAdapter(child: _buildHeader()),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
                  sliver: SliverToBoxAdapter(
                    child: _buildSummary(totalClasses),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
                  sliver: SliverToBoxAdapter(child: _buildToolbar()),
                ),
                if (_loadError != null)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverToBoxAdapter(child: _buildError()),
                  ),
                if (_isLoading && _lecturers.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_loadError != null && _lecturers.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildUnavailableState(),
                  )
                else if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                    sliver: SliverLayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.crossAxisExtent;
                        final columns = width >= 920
                            ? 3
                            : width >= 600
                            ? 2
                            : 1;
                        return SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                mainAxisExtent: 178,
                              ),
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final lecturer = filtered[index];
                            return LecturerCard(
                              lecturer: lecturer,
                              onEdit: () => _openForm(lecturer: lecturer),
                              onDelete: () => _confirmDelete(lecturer),
                            );
                          }, childCount: filtered.length),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isWide = MediaQuery.sizeOf(context).width > 520;
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.school_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quản lý giảng viên',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
              ),
              Text(
                isWide
                    ? 'Hệ thống quản lý học phần · Khu vực quản trị'
                    : 'Hệ thống quản lý học phần',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (isWide && widget.onLogout != null)
          IconButton(
            onPressed: widget.onLogout,
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout_rounded),
          ),
        if (isWide)
          IconButton(
            onPressed: _loadLecturers,
            tooltip: 'Tải lại danh sách',
            icon: const Icon(Icons.refresh_rounded),
          )
        else
          PopupMenuButton<String>(
            tooltip: 'Tùy chọn',
            onSelected: (value) {
              if (value == 'refresh') {
                _loadLecturers();
              } else {
                widget.onLogout?.call();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.refresh_rounded),
                  title: Text('Tải lại danh sách'),
                ),
              ),
              if (widget.onLogout != null)
                const PopupMenuItem(
                  value: 'logout',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.logout_rounded),
                    title: Text('Đăng xuất'),
                  ),
                ),
            ],
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.more_vert_rounded),
            ),
          ),
        const SizedBox(width: 4),
        FilledButton.icon(
          onPressed: () => _openForm(),
          icon: const Icon(Icons.add_rounded),
          label: Text(isWide ? 'Thêm giảng viên' : 'Thêm'),
        ),
      ],
    );
  }

  Widget _buildSummary(int totalClasses) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth < 600
            ? (constraints.maxWidth - 12) / 2
            : 260.0;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _SummaryCard(
              width: cardWidth,
              title: 'Giảng viên',
              value: '${_lecturers.length}',
              icon: Icons.groups_2_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            _SummaryCard(
              width: cardWidth,
              title: 'Tổng số lớp',
              value: '$totalClasses',
              icon: Icons.menu_book_outlined,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ],
        );
      },
    );
  }

  Widget _buildToolbar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Tìm theo mã hoặc họ tên giảng viên...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Xóa tìm kiếm',
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Text(
              'Lọc theo số lớp:',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            _buildClassFilterChip(_ClassFilter.all, 'Tất cả'),
            _buildClassFilterChip(_ClassFilter.withClasses, 'Có lớp'),
            _buildClassFilterChip(_ClassFilter.withoutClasses, 'Chưa có lớp'),
            const SizedBox(width: 8),
            Icon(
              Icons.sort_rounded,
              color: Theme.of(context).colorScheme.secondary,
            ),
            DropdownButton<_LecturerSort>(
              key: const ValueKey('lecturer-sort'),
              value: _lecturerSort,
              underline: const SizedBox.shrink(),
              borderRadius: BorderRadius.circular(12),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _lecturerSort = value);
              },
              items: const [
                DropdownMenuItem(
                  value: _LecturerSort.nameAscending,
                  child: Text('Tên: A → Z'),
                ),
                DropdownMenuItem(
                  value: _LecturerSort.nameDescending,
                  child: Text('Tên: Z → A'),
                ),
                DropdownMenuItem(
                  value: _LecturerSort.idAscending,
                  child: Text('Mã: tăng dần'),
                ),
                DropdownMenuItem(
                  value: _LecturerSort.idDescending,
                  child: Text('Mã: giảm dần'),
                ),
                DropdownMenuItem(
                  value: _LecturerSort.classesAscending,
                  child: Text('Số lớp: tăng dần'),
                ),
                DropdownMenuItem(
                  value: _LecturerSort.classesDescending,
                  child: Text('Số lớp: giảm dần'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildClassFilterChip(_ClassFilter filter, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _classFilter == filter,
      onSelected: (_) => setState(() => _classFilter = filter),
    );
  }

  Widget _buildError() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_outlined, color: colors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Không tải được dữ liệu: $_loadError',
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
          TextButton(onPressed: _loadLecturers, child: const Text('Thử lại')),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasActiveFilters =
        _searchController.text.trim().isNotEmpty ||
        _classFilter != _ClassFilter.all;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasActiveFilters
                  ? Icons.search_off_rounded
                  : Icons.people_outline,
              size: 56,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              hasActiveFilters
                  ? 'Không tìm thấy giảng viên'
                  : 'Chưa có giảng viên',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 5),
            Text(
              hasActiveFilters
                  ? 'Thử đổi từ khóa tìm kiếm hoặc điều kiện lọc.'
                  : 'Thêm giảng viên đầu tiên để bắt đầu quản lý.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (!hasActiveFilters) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _openForm(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Thêm giảng viên'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUnavailableState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 52,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            const Text(
              'Không kết nối được máy chủ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 5),
            Text(
              'Kiểm tra backend và kết nối MongoDB rồi thử tải lại.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loadLecturers,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử kết nối lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.width,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final double width;
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 13),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
