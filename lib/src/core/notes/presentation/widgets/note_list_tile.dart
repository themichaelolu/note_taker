import 'package:flutter/material.dart';
import 'package:flutter_quill/quill_delta.dart' as quill;
import 'package:note_taker/src/core/notes/data/models/note_model.dart';
import 'package:note_taker/src/core/notes/domains/entities/category.dart';

class NoteListTile extends StatelessWidget {
  final NoteModel note;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const NoteListTile({Key? key, required this.note, this.onTap, this.onDelete})
    : super(key: key);

  String _snippet(quill.Delta d) {
    final buffer = StringBuffer();
    for (final op in d.toList()) {
      if (op.value is String) buffer.write(op.value as String);
      if (buffer.length > 120) break;
    }
    final s = buffer.toString().replaceAll('\n', ' ').trim();
    if (s.length > 110) return '${s.substring(0, 110)}…';
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(note.colorValue);
    final updated = note.updatedAt;
    final created = note.createdAt;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.black12,
                child: Icon(
                  note.category.icon,
                  size: 20,
                  color: Colors.black54,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            note.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'delete') {
                              onDelete?.call();
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              child: Text('Delete'),
                              value: 'delete',
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      _snippet(note.bodyDelta),
                      style: TextStyle(color: Colors.black87),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Updated: ${_fmtDate(updated)}',
                          style: TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                        SizedBox(width: 10),
                        if (note.tags.isNotEmpty)
                          Expanded(
                            child: Wrap(
                              spacing: 6,
                              children: note.tags
                                  .take(3)
                                  .map(
                                    (t) => Chip(
                                      label: Text(
                                        t,
                                        style: TextStyle(fontSize: 11),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
