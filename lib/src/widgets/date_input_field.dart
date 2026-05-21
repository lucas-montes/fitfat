import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A date input field that supports both manual dd/mm/yyyy entry and a date picker.
/// NOTE: The TextField accepts dd/mm/yyyy format. On submit, parses and calls onChanged.
///
/// Usage:
/// ```dart
/// DateInputField(
///   date: _myDate,
///   onChanged: (d) => setState(() => _myDate = d),
///   label: 'Birthdate',
///   firstDate: DateTime(1900),
///   lastDate: DateTime.now(),
/// )
/// ```
class DateInputField extends StatefulWidget {
  const DateInputField({
    super.key,
    required this.date,
    required this.onChanged,
    this.label = 'Date',
    this.firstDate,
    this.lastDate,
  });

  final DateTime date;
  final ValueChanged<DateTime> onChanged;
  final String label;
  final DateTime? firstDate;
  final DateTime? lastDate;

  @override
  State<DateInputField> createState() => _DateInputFieldState();
}

class _DateInputFieldState extends State<DateInputField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(widget.date),
    );
  }

  @override
  void didUpdateWidget(DateInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date) {
      _controller.text = DateFormat('dd/MM/yyyy').format(widget.date);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _parseAndSet(String text) {
    // Try dd/mm/yyyy
    try {
      final parts = text.trim().split('/');
      if (parts.length == 3) {
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);
        if (day != null && month != null && year != null) {
          final parsed = DateTime(year, month, day);
          // Accept only valid dates (month/day in range)
          if (parsed.month == month && parsed.day == day) {
            widget.onChanged(parsed);
            return;
          }
        }
      }
    } catch (_) {}
    // Fall back: reset to last valid
    _controller.text = DateFormat('dd/MM/yyyy').format(widget.date);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              label: Text(widget.label),
              hintText: 'dd/mm/yyyy',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 13),
            keyboardType: TextInputType.datetime,
            onSubmitted: _parseAndSet,
            onTap: () {
              // Select all when tapped for easy overwrite
              _controller.selection = TextSelection(
                baseOffset: 0,
                extentOffset: _controller.text.length,
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.calendar_month),
          tooltip: 'Pick date',
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: widget.date,
              firstDate: widget.firstDate ?? DateTime(1900),
              lastDate:
                  widget.lastDate ??
                  DateTime.now().add(const Duration(days: 365 * 10)),
            );
            if (picked != null) {
              widget.onChanged(picked);
            }
          },
        ),
      ],
    );
  }
}
