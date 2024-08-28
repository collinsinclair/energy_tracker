import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddEntryDialog extends StatefulWidget {
  final void Function(String name, int calories, DateTime timestamp) onAdd;
  final Map<String, dynamic>? entryToEdit;
  const AddEntryDialog({required this.onAdd, this.entryToEdit, super.key});
  @override
  AddEntryDialogState createState() => AddEntryDialogState();
}

class AddEntryDialogState extends State<AddEntryDialog> {
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    if (widget.entryToEdit != null) {
      _nameController.text = widget.entryToEdit!['name'];
      _caloriesController.text = widget.entryToEdit!['calories'].toString();
      _selectedDate = DateTime.parse(widget.entryToEdit!['timestamp']);
    } else {
      _selectedDate = DateTime.now();
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );

    if (time != null) {
      setState(() {
        _selectedDate = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  void _setTimeToNow() {
    setState(() {
      _selectedDate = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Entry'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _caloriesController,
              decoration: const InputDecoration(labelText: 'Calories'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a calorie value';
                }
                final parsedValue = int.tryParse(value);
                if (parsedValue == null) {
                  return 'Please enter a valid number';
                }
                if (parsedValue <= 0) {
                  return 'Please enter a positive number';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(DateFormat.jm().format(_selectedDate)),
                const Spacer(),
                TextButton(
                  onPressed: _pickTime,
                  child: const Text('Select Time'),
                ),
                TextButton(
                  onPressed: _setTimeToNow,
                  child: const Text('Now'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final name = _nameController.text;
              final calories = int.parse(_caloriesController.text);
              widget.onAdd(name, calories, _selectedDate);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
