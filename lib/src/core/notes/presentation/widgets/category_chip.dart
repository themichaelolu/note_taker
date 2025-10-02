import 'package:flutter/material.dart';
import 'package:note_taker/src/core/notes/domains/entities/category.dart';

class CategoryChip extends StatelessWidget {
  final Category? category;
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const CategoryChip({
    super.key,
    required this.category,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 10)),
        showCheckmark: false,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: selected ? Colors.transparent : Colors.grey),
        ),
        selected: selected,
        onSelected: (_) => onSelected(),
        selectedColor: Colors.black,
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.black,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
