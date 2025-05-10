import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';

class ProfileOnboardingScreen extends StatefulWidget {
  const ProfileOnboardingScreen({super.key});

  @override
  State<ProfileOnboardingScreen> createState() => _ProfileOnboardingScreenState();
}

class _ProfileOnboardingScreenState extends State<ProfileOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  String _selectedGender = 'Male';
  DateTime? _selectedDate;
  
  int _currentStep = 0;
  final int _totalSteps = 4;
  bool _isLoading = false;

  @override
  void dispose() {
    _dateController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  double _getProgress() {
    return (_currentStep + 1) / _totalSteps;
  }

  Future<void> _saveProfileData() async {
    if (_formKey.currentState == null) {
      print('DEBUG: _formKey.currentState is null');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred. Please try again.')),
      );
      return;
    }
    
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      
      if (user == null) {
        print('DEBUG: User is null in _saveProfileData');
        throw Exception('User not found');
      }

      print('DEBUG: Creating updated user with data:');
      print('DEBUG: DOB: $_selectedDate');
      print('DEBUG: Weight: ${_weightController.text}');
      print('DEBUG: Height: ${_heightController.text}');
      print('DEBUG: Gender: $_selectedGender');

      final updatedUser = user.copyWith(
        dateOfBirth: _selectedDate,
        bodyWeight: double.parse(_weightController.text),
        bodyHeight: double.parse(_heightController.text),
        gender: _selectedGender,
        isProfileComplete: true,
      );

      print('DEBUG: Calling updateUserProfile');
      final success = await authProvider.updateUserProfile(updatedUser);
      print('DEBUG: Update result: $success');

      if (!success) {
        throw Exception('Failed to update profile: ${authProvider.error}');
      }

      if (mounted) {
        print('DEBUG: Navigation to home after profile update');
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
          (route) => false,
        );
      }
    } catch (e) {
      print('Error updating profile: $e');
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Failed to Save Data'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('An error occurred: ${e.toString()}'),
                const SizedBox(height: 16),
                const Text('Do you want to continue without saving data?'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('No'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/home',
                    (route) => false,
                  );
                },
                child: const Text('Yes, Continue'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('id', 'ID'),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd MMMM yyyy', 'id_ID').format(picked);
      });
    }
  }

  void _nextStep() {
    setState(() {
      if (_currentStep < _totalSteps - 1) {
        _currentStep++;
      } else {
        _confirmProfileData();
      }
    });
  }

  void _confirmProfileData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Profile Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please check your data before continuing:'),
            const SizedBox(height: 16),
            _buildInfoRow('Date of Birth', _dateController.text),
            _buildInfoRow('Gender', _selectedGender),
            _buildInfoRow('Weight', '${_weightController.text} kg'),
            _buildInfoRow('Height', '${_heightController.text} cm'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _saveProfileData();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }

  void _previousStep() {
    setState(() {
      if (_currentStep > 0) {
        _currentStep--;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Profile'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Stepper(
            currentStep: _currentStep,
            steps: [
              Step(
                title: const Text('Welcome'),
                content: _buildWelcomeStep(),
              ),
              Step(
                title: const Text('Date of Birth'),
                content: _buildDateOfBirthStep(),
              ),
              Step(
                title: const Text('Gender'),
                content: _buildGenderStep(),
              ),
              Step(
                title: const Text('Body Measurements'),
                content: _buildBodyMeasurementsStep(),
              ),
            ],
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  children: [
                    FilledButton(
                      onPressed: _isLoading ? null : _nextStep,
                      child: _isLoading 
                        ? const SizedBox(
                            width: 20, 
                            height: 20, 
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.0,
                            )
                          ) 
                        : Text(_currentStep == _totalSteps - 1 ? 'Finish' : 'Next'),
                    ),
                    if (_currentStep > 0) ...[
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: _isLoading ? null : _previousStep,
                        child: const Text('Back'),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Welcome to FoodWise!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'To give you the best experience, we need to collect some basic information about you.',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 24),
        Container(
          height: 180,
          color: Colors.green.withOpacity(0.1),
          child: const Center(
            child: Icon(
              Icons.eco,
              size: 80,
              color: Colors.green,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'This information helps us:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildInfoItem(
          icon: Icons.eco,
          text: 'Estimate the environmental impact of your food savings',
        ),
        _buildInfoItem(
          icon: Icons.insights,
          text: 'Provide tailored suggestions to reduce food waste',
        ),
        _buildInfoItem(
          icon: Icons.health_and_safety,
          text: 'Display relevant health information',
        ),
      ],
    );
  }

  Widget _buildInfoItem({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }

  Widget _buildDateOfBirthStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'When is Your Date of Birth?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'This information helps us provide recommendations appropriate for your age.',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _dateController,
          decoration: const InputDecoration(
            labelText: 'Date of Birth',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.calendar_today),
            hintText: 'Select your date of birth',
          ),
          readOnly: true,
          onTap: () => _selectDate(context),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select your date of birth';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildGenderStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Gender',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'This information helps us provide recommendations that match your needs.',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 24),
        DropdownButtonFormField<String>(
          value: _selectedGender,
          decoration: const InputDecoration(
            labelText: 'Gender',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.wc),
          ),
          items: const [
            DropdownMenuItem(
              value: 'Male',
              child: Text('Male'),
            ),
            DropdownMenuItem(
              value: 'Female',
              child: Text('Female'),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedGender = value;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildBodyMeasurementsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Body Measurements',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'This information helps us provide recommendations that match your physical condition.',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _weightController,
          decoration: const InputDecoration(
            labelText: 'Weight (kg)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.monitor_weight),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your weight';
            }
            try {
              final weight = double.parse(value);
              if (weight <= 0) {
                return 'Weight must be greater than 0';
              }
            } catch (e) {
              return 'Invalid format';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _heightController,
          decoration: const InputDecoration(
            labelText: 'Height (cm)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.height),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your height';
            }
            try {
              final height = double.parse(value);
              if (height <= 0) {
                return 'Height must be greater than 0';
              }
            } catch (e) {
              return 'Invalid format';
            }
            return null;
          },
        ),
      ],
    );
  }
} 