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
  String _selectedGender = 'Laki-laki';
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
        const SnackBar(content: Text('Terjadi kesalahan. Silakan coba lagi.')),
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
        throw Exception('User tidak ditemukan');
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
        throw Exception('Gagal memperbarui profil: ${authProvider.error}');
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
            title: const Text('Gagal Menyimpan Data'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Terjadi kesalahan: ${e.toString()}'),
                const SizedBox(height: 16),
                const Text('Apakah Anda ingin melanjutkan tanpa menyimpan data?'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tidak'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/home',
                    (route) => false,
                  );
                },
                child: const Text('Ya, Lanjutkan'),
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
        title: const Text('Konfirmasi Data Profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mohon periksa data Anda sebelum melanjutkan:'),
            const SizedBox(height: 16),
            _buildInfoRow('Tanggal Lahir', _dateController.text),
            _buildInfoRow('Jenis Kelamin', _selectedGender),
            _buildInfoRow('Berat Badan', '${_weightController.text} kg'),
            _buildInfoRow('Tinggi Badan', '${_heightController.text} cm'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kembali'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _saveProfileData();
            },
            child: const Text('Simpan'),
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
        title: const Text('Lengkapi Profil'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Stepper(
            currentStep: _currentStep,
            steps: [
              Step(
                title: const Text('Selamat Datang'),
                content: _buildWelcomeStep(),
              ),
              Step(
                title: const Text('Tanggal Lahir'),
                content: _buildDateOfBirthStep(),
              ),
              Step(
                title: const Text('Jenis Kelamin'),
                content: _buildGenderStep(),
              ),
              Step(
                title: const Text('Ukuran Tubuh'),
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
                        : Text(_currentStep == _totalSteps - 1 ? 'Selesai' : 'Lanjut'),
                    ),
                    if (_currentStep > 0) ...[
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: _isLoading ? null : _previousStep,
                        child: const Text('Kembali'),
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
          'Selamat Datang di FoodWise!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Untuk memberi Anda pengalaman terbaik, kami perlu mengumpulkan beberapa informasi dasar tentang Anda.',
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
          'Informasi ini membantu kami:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildInfoItem(
          icon: Icons.eco,
          text: 'Memperkirakan dampak lingkungan dari penghematan makanan Anda',
        ),
        _buildInfoItem(
          icon: Icons.insights,
          text: 'Memberikan saran yang disesuaikan untuk mengurangi limbah makanan',
        ),
        _buildInfoItem(
          icon: Icons.health_and_safety,
          text: 'Menampilkan informasi kesehatan yang relevan',
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
          'Kapan Tanggal Lahir Anda?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Informasi ini membantu kami menyediakan rekomendasi yang sesuai dengan usia Anda.',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _dateController,
          decoration: const InputDecoration(
            labelText: 'Tanggal Lahir',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.calendar_today),
            hintText: 'Pilih tanggal lahir Anda',
          ),
          readOnly: true,
          onTap: () => _selectDate(context),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Silakan pilih tanggal lahir Anda';
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
          'Jenis Kelamin Anda',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Informasi ini membantu kami menyediakan rekomendasi yang sesuai dengan kebutuhan Anda.',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 24),
        DropdownButtonFormField<String>(
          value: _selectedGender,
          decoration: const InputDecoration(
            labelText: 'Jenis Kelamin',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.wc),
          ),
          items: const [
            DropdownMenuItem(
              value: 'Laki-laki',
              child: Text('Laki-laki'),
            ),
            DropdownMenuItem(
              value: 'Perempuan',
              child: Text('Perempuan'),
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
          'Ukuran Tubuh Anda',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Informasi ini membantu kami menyediakan rekomendasi yang sesuai dengan kondisi fisik Anda.',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _weightController,
          decoration: const InputDecoration(
            labelText: 'Berat Badan (kg)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.monitor_weight),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Silakan masukkan berat badan Anda';
            }
            try {
              final weight = double.parse(value);
              if (weight <= 0) {
                return 'Berat badan harus lebih dari 0';
              }
            } catch (e) {
              return 'Format tidak valid';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _heightController,
          decoration: const InputDecoration(
            labelText: 'Tinggi Badan (cm)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.height),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Silakan masukkan tinggi badan Anda';
            }
            try {
              final height = double.parse(value);
              if (height <= 0) {
                return 'Tinggi badan harus lebih dari 0';
              }
            } catch (e) {
              return 'Format tidak valid';
            }
            return null;
          },
        ),
      ],
    );
  }
} 