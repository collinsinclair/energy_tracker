import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  SettingsTabState createState() => SettingsTabState();
}

class SettingsTabState extends State<SettingsTab> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _projectedTotalController =
      TextEditingController();
  final TextEditingController _restingCaloriesController =
      TextEditingController();
  final TextEditingController _activeCaloriesController =
      TextEditingController();
  final TextEditingController _goalDeltaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadValues();
  }

  void _loadValues() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _projectedTotalController.text = prefs.getString('projectedTotal') ?? '';
      _restingCaloriesController.text =
          prefs.getString('restingCalories') ?? '';
      _activeCaloriesController.text = prefs.getString('activeCalories') ?? '';
      _goalDeltaController.text = prefs.getString('goalDelta') ?? '';
    });
  }

  void _saveValues() async {
    if (_goalDeltaController.text.isEmpty) {
      _goalDeltaController.text = '0';
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('projectedTotal', _projectedTotalController.text);
    await prefs.setString('restingCalories', _restingCaloriesController.text);
    await prefs.setString('activeCalories', _activeCaloriesController.text);
    await prefs.setString('goalDelta', _goalDeltaController.text);
  }

  @override
  void dispose() {
    _projectedTotalController.dispose();
    _restingCaloriesController.dispose();
    _activeCaloriesController.dispose();
    _goalDeltaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Simple Energy Tracker'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              _buildTextField(
                controller: _projectedTotalController,
                label: 'Projected Total',
                validator: _validatePositiveInteger,
              ),
              _buildTextField(
                controller: _restingCaloriesController,
                label: 'Resting Calories',
                validator: _validatePositiveInteger,
              ),
              _buildTextField(
                controller: _activeCaloriesController,
                label: 'Active Calories',
                validator: _validatePositiveInteger,
              ),
              _buildTextField(
                controller: _goalDeltaController,
                label: 'Goal Delta',
                helperText:
                    'Use positive values for surpluses and negative values for deficits.',
                validator: _validateInteger,
              ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate() &&
                      _validateFormCombinations()) {
                    _saveValues();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Values saved!')),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? helperText,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        helperMaxLines: 2,
      ),
      keyboardType: TextInputType.number,
      validator: validator,
    );
  }

  String? _validatePositiveInteger(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final intValue = int.tryParse(value);
    if (intValue == null || intValue <= 0) {
      return 'Please enter a positive integer';
    }
    return null;
  }

  String? _validateInteger(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final intValue = int.tryParse(value);
    if (intValue == null) {
      return 'Please enter a valid integer';
    }
    return null;
  }

  bool _validateFormCombinations() {
    final isProjectedTotalValid = _projectedTotalController.text.isNotEmpty &&
        _validatePositiveInteger(_projectedTotalController.text) == null;
    final isRestingCaloriesValid = _restingCaloriesController.text.isNotEmpty &&
        _validatePositiveInteger(_restingCaloriesController.text) == null;
    final isActiveCaloriesValid = _activeCaloriesController.text.isNotEmpty &&
        _validatePositiveInteger(_activeCaloriesController.text) == null;

    if (!isProjectedTotalValid &&
        (!isRestingCaloriesValid || !isActiveCaloriesValid)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please set a valid projected total or both resting and active calories.'),
        ),
      );
      return false;
    }

    return true;
  }
}
