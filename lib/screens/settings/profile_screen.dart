import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/food_scan_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _usernameController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  String _selectedGender = 'Laki-laki';
  
  bool _isEditing = false;
  
  @override
  void initState() {
    super.initState();
    
    // Isi form dengan data user saat ini
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null) {
        _usernameController.text = user.username;
        if (user.bodyWeight != null) {
          _weightController.text = user.bodyWeight.toString();
        }
        if (user.bodyHeight != null) {
          _heightController.text = user.bodyHeight.toString();
        }
        if (user.gender != null) {
          _selectedGender = user.gender!;
        }
      }
    });
  }
  
  @override
  void dispose() {
    _usernameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }
  
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    
    if (currentUser == null) return;
    
    final updatedUser = currentUser.copyWith(
      username: _usernameController.text,
      bodyWeight: _weightController.text.isNotEmpty 
          ? double.parse(_weightController.text) 
          : null,
      bodyHeight: _heightController.text.isNotEmpty 
          ? double.parse(_heightController.text) 
          : null,
      gender: _selectedGender,
    );
    
    final success = await authProvider.updateUserProfile(updatedUser);
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui')),
        );
        setState(() {
          _isEditing = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.error ?? 'Gagal memperbarui profil')),
        );
      }
    }
  }
  
  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Akun'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus akun? Tindakan ini tidak dapat dibatalkan dan semua data Anda akan dihapus permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus Akun'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.deleteAccount();
      
      if (mounted) {
        if (!success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(authProvider.error ?? 'Gagal menghapus akun')),
          );
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final foodScanProvider = Provider.of<FoodScanProvider>(context, listen: false);
    final user = authProvider.user;
    
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('User tidak ditemukan'),
        ),
      );
    }
    
    return Scaffold(
      appBar: null,
      backgroundColor: Colors.transparent, // Buat latar belakang transparan

      body: SafeArea( // Tambahkan SafeArea di sini
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // User photo & basic info
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: user.photoURL.isNotEmpty
                          ? NetworkImage(user.photoURL)
                          : null,
                      child: user.photoURL.isEmpty
                          ? const Icon(Icons.person, size: 50)
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.username,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              
              // Statistik Pengguna
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Statistik Anda',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            'Total Scan',
                            '${foodScanProvider.foodScans.length}',
                            Icons.image_search,
                            Colors.blue,
                          ),
                          _buildStatItem(
                            'Food Waste',
                            '${foodScanProvider.totalWaste.toStringAsFixed(1)} g',
                            Icons.delete_outline,
                            Colors.red,
                          ),
                          _buildStatItem(
                            'CO2 Saved',
                            '${foodScanProvider.totalCarbonSaved.toStringAsFixed(1)} kg',
                            Icons.eco,
                            Colors.green,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Profile details form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detail Profil',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Username
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Pengguna',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      readOnly: !_isEditing,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama pengguna tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Gender
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
                      onChanged: _isEditing
                          ? (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedGender = value;
                                });
                              }
                            }
                          : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Body weight and height
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _weightController,
                            decoration: const InputDecoration(
                              labelText: 'Berat Badan (kg)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.monitor_weight),
                            ),
                            keyboardType: TextInputType.number,
                            readOnly: !_isEditing,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                final weight = double.tryParse(value);
                                if (weight == null) {
                                  return 'Format tidak valid';
                                }
                                if (weight <= 0) {
                                  return 'Berat harus > 0';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _heightController,
                            decoration: const InputDecoration(
                              labelText: 'Tinggi Badan (cm)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.height),
                            ),
                            keyboardType: TextInputType.number,
                            readOnly: !_isEditing,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                final height = double.tryParse(value);
                                if (height == null) {
                                  return 'Format tidak valid';
                                }
                                if (height <= 0) {
                                  return 'Tinggi harus > 0';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Logout button
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 16),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Keluar'),
                        content: const Text('Apakah Anda yakin ingin keluar dari akun?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Batal'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Keluar'),
                          ),
                        ],
                      ),
                    );
                    
                    if (confirm == true) {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      await authProvider.signOut();
                      if (mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/login',
                          (route) => false,
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Keluar dari Akun'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              
              // Danger zone
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Zona Bahaya',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Tindakan di bawah ini tidak dapat dibatalkan. Harap berhati-hati sebelum melanjutkan.',
                      style: TextStyle(
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.delete_forever),
                        label: const Text('Hapus Akun'),
                        onPressed: _confirmDeleteAccount,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
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
  
  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 28,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}