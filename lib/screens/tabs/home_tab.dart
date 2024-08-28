import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/widgets/add_entry_dialog.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  HomeTabState createState() => HomeTabState();
}

class HomeTabState extends State<HomeTab> {
  List<Map<String, dynamic>> _entries = [];
  int _remainingCalories = 0;
  double _progressValue = 0.0;

  @override
  void initState() {
    super.initState();
    _loadEntries();
    _calculateRemainingCalories();
  }

  Future<void> _loadEntries() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? storedEntries = prefs.getStringList('entries');
    if (storedEntries != null) {
      setState(() {
        _entries = storedEntries.map((entry) {
          final Map<String, dynamic> decodedEntry =
              Map<String, dynamic>.from(jsonDecode(entry));
          if (decodedEntry['timestamp'] == null) {
            decodedEntry['timestamp'] = DateTime.now().toIso8601String();
          }
          return decodedEntry;
        }).toList();

        _entries.sort((a, b) {
          DateTime aTime = DateTime.parse(a['timestamp']);
          DateTime bTime = DateTime.parse(b['timestamp']);
          return aTime.compareTo(bTime);
        });
      });
    }
  }

  Future<void> _saveEntries() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> entries = _entries.map((e) => jsonEncode(e)).toList();
    await prefs.setStringList('entries', entries);
  }

  Future<void> _calculateRemainingCalories() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? projectedTotal =
        int.tryParse(prefs.getString('projectedTotal') ?? '0');
    if (projectedTotal == null || projectedTotal == 0) {
      int restingCalories =
          int.tryParse(prefs.getString('restingCalories') ?? '0') ?? 0;
      int activeCalories =
          int.tryParse(prefs.getString('activeCalories') ?? '0') ?? 0;
      projectedTotal = restingCalories + activeCalories;
    }
    int goalDelta = int.tryParse(prefs.getString('goalDelta') ?? '0') ?? 0;
    int totalEntriesCalories = _entries.fold<int>(
      0,
      (sum, item) => sum + (item['calories'] ?? 0) as int,
    );
    setState(() {
      _remainingCalories = projectedTotal! + goalDelta - totalEntriesCalories;
      if (totalEntriesCalories == 0) {
        _progressValue = 0.0;
      } else {
        _progressValue =
            totalEntriesCalories / (_remainingCalories + totalEntriesCalories);
      }
      if (_progressValue > 1.0) {
        _progressValue = 1.0;
      }
    });
  }

  void _addEntry(String name, int calories, DateTime? timestamp) {
    setState(() {
      _entries.add({
        'name': name,
        'calories': calories,
        'timestamp':
            timestamp?.toIso8601String() ?? DateTime.now().toIso8601String()
      });
    });
    _saveEntries();
    _calculateRemainingCalories();
  }

  void _editEntry(int index, String name, int calories, DateTime? timestamp) {
    setState(() {
      _entries[index] = {
        'name': name,
        'calories': calories,
        'timestamp':
            timestamp?.toIso8601String() ?? DateTime.now().toIso8601String()
      };
    });
    _saveEntries();
    _calculateRemainingCalories();
  }

  void _deleteEntry(int index) {
    setState(() {
      _entries.removeAt(index);
    });
    _saveEntries();
    _calculateRemainingCalories();
  }

  void _confirmDeleteEntry(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this entry?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteEntry(index);
              },
            ),
          ],
        );
      },
    );
  }

  void _showAddEntryDialog({Map<String, dynamic>? entryToEdit, int? index}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddEntryDialog(
          onAdd: (name, calories, timestamp) {
            if (entryToEdit != null && index != null) {
              _editEntry(index, name, calories, timestamp);
            } else {
              _addEntry(name, calories, timestamp);
            }
          },
          entryToEdit: entryToEdit,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Remaining Calories: $_remainingCalories'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: LinearProgressIndicator(
              value: _progressValue,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _entries.length + 1,
              itemBuilder: (context, index) {
                if (index == _entries.length) {
                  return const SizedBox(height: 64);
                }
                final entry = _entries[index];
                return ListTile(
                  title: Text(entry['name']),
                  subtitle: Text(
                    entry['timestamp'] != null
                        ? DateFormat.jm()
                            .format(DateTime.parse(entry['timestamp']))
                        : 'No time set',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${entry['calories']} cal'),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showAddEntryDialog(
                            entryToEdit: entry, index: index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _confirmDeleteEntry(index),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          _showAddEntryDialog();
        },
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}
