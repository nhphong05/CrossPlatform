import 'package:flutter/material.dart';

import '../models/lecturer.dart';
import 'lecturer_avatar.dart';

class LecturerCard extends StatelessWidget {
  const LecturerCard({
    required this.lecturer,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final Lecturer lecturer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                LecturerAvatar(image: lecturer.image, size: 64),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lecturer.fullname,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        lecturer.id,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Thao tác',
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Chỉnh sửa'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.delete_outline,
                          color: colors.error,
                        ),
                        title: Text('Xóa'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.class_outlined, size: 19, color: colors.primary),
                const SizedBox(width: 8),
                Text(
                  'Tổng số lớp',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
                const Spacer(),
                Text(
                  '${lecturer.sumClass}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
