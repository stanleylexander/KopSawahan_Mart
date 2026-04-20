import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import 'login.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final Color primaryRed = const Color(0xFFB71C1C);
  final Color creamBackground = const Color(0xFFFFF8F6);

  TextEditingController? _nameController;
  TextEditingController? _emailController;
  TextEditingController? _phoneController;

  bool isLoading = true;
  DateTime? selectedDate;
  String? _selectedGender = "male";
  String? _profileImage = '';
  File? imageFile;

  TextEditingController get nameController {
    _nameController ??= TextEditingController();
    return _nameController!;
  }

  TextEditingController get emailController {
    _emailController ??= TextEditingController();
    return _emailController!;
  }

  TextEditingController get phoneController {
    _phoneController ??= TextEditingController();
    return _phoneController!;
  }

  String get selectedGenderValue {
    final value = _selectedGender;

    if (value == null || value.isEmpty || value == 'undefined' || value == 'null') {
      return "male";
    }

    return value;
  }

  String get profileImageValue {
    final value = _profileImage;

    if (value == null || value.isEmpty || value == 'undefined' || value == 'null') {
      return '';
    }

    return value;
  }

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final user = await UserService.getProfile(token);

    if (user != null) {
      nameController.text = user.name;
      emailController.text = user.email;
      phoneController.text = user.phoneNumber;
      _profileImage = user.image;

      if (user.dateOfBirth.isNotEmpty) {
        selectedDate = DateTime.tryParse(user.dateOfBirth);
      }

      _selectedGender = user.gender.toLowerCase().isEmpty ? "male" : user.gender.toLowerCase();
    } else {
      nameController.text = '';
      emailController.text = '';
      phoneController.text = '';
      _profileImage = '';
    }

    if (!mounted) {
      return;
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    _nameController?.dispose();
    _emailController?.dispose();
    _phoneController?.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) {
      return;
    }

    setState(() {
      imageFile = File(picked.path);
    });
  }

  Future<void> handleUpdateProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final success = await UserService.updateProfile(
      token,
      nameController.text,
      emailController.text,
      phoneController.text,
      selectedDate != null ? "${selectedDate!.toLocal()}".split(' ')[0] : "",
      selectedGenderValue,
      imageFile,
    );

    if (success) {
      await loadProfile();
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? "Profile berhasil diupdate" : "Gagal update profile",
        ),
      ),
    );
  }

  Future<void> handleLogout() async {
    await AuthService.logout();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => Login()),
        (route) => false,
      );
    }
  }

  Widget buildProfileAvatar() {
    Widget child;
    final hasRemoteImage = profileImageValue.isNotEmpty;

    if (imageFile != null) {
      child = Image.file(imageFile!, fit: BoxFit.cover);
    } else if (hasRemoteImage) {
      child = Image.network(
        UserService.getImageUrl(profileImageValue),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Center(
          child: Icon(
            Icons.person,
            size: 50,
            color: primaryRed,
          ),
        ),
      );
    } else {
      child = Center(
        child: Icon(
          Icons.person,
          size: 50,
          color: primaryRed,
        ),
      );
    }

    return GestureDetector(
      onTap: pickImage,
      child: Stack(
        children: [
          Container(
            width: 94,
            height: 94,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: ClipOval(child: child),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.shade100,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                color: primaryRed,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamBackground,
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryRed, Colors.red.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : RefreshIndicator(
              onRefresh: loadProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryRed, Colors.red.shade500],
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        children: [
                          buildProfileAvatar(),
                          const SizedBox(height: 12),
                          Text(
                            nameController.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            emailController.text,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Ketuk foto untuk mengganti gambar profil",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.shade50,
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildInput("Nama", nameController),
                          _buildInput("Email", emailController),
                          _buildInput("No HP", phoneController),
                          _buildDatePicker(),
                          _buildGenderRadio(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ElevatedButton.icon(
                        onPressed: handleUpdateProfile,
                        icon: const Icon(Icons.save),
                        label: const Text("Simpan Perubahan"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ElevatedButton.icon(
                        onPressed: handleLogout,
                        icon: const Icon(Icons.logout),
                        label: const Text("Logout"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryRed,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Tanggal Lahir", style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: selectedDate ?? DateTime(2000),
                firstDate: DateTime(1950),
                lastDate: DateTime.now(),
              );

              if (pickedDate != null) {
                setState(() {
                  selectedDate = pickedDate;
                });
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                selectedDate != null
                    ? "${selectedDate!.toLocal()}".split(' ')[0]
                    : "Pilih tanggal lahir",
                style: TextStyle(
                  color: selectedDate != null ? Colors.black : Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderRadio() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Gender", style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedGenderValue,
                isExpanded: true,
                borderRadius: BorderRadius.circular(12),
                items: const [
                  DropdownMenuItem(
                    value: "male",
                    child: Text("Male"),
                  ),
                  DropdownMenuItem(
                    value: "female",
                    child: Text("Female"),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    _selectedGender = value;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
