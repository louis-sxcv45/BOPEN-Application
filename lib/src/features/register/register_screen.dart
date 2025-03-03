import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:project_pkl/src/common_widgets/custom_button.dart';
import 'package:project_pkl/src/style_manager/color_manager.dart';
import 'package:project_pkl/src/style_manager/font_family_manager.dart';
import 'package:project_pkl/src/style_manager/values_manager.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final namaController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool isObsecurePassword = true;
  bool isObsecureConfirmPassword = true;
  bool isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> registerUser() async {
    setState(() {
      isLoading = true;
    });

    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        throw Exception("Tidak ada koneksi internet");
      }

      final nama = namaController.text.trim();
      final email = emailController.text.trim();
      final password = passwordController.text.trim();
      final confirmPassword = confirmPasswordController.text.trim();

      // Validasi form
      if (nama.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
        throw Exception("Semua field harus diisi");
      }

      if (password != confirmPassword) {
        throw Exception("Password dan konfirmasi password tidak sama");
      }

      // Cek apakah email sudah terdaftar di Firebase Authentication
      try {
        final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        final User? user = userCredential.user;
        if (user != null) {
          // Simpan data pengguna ke Firestore
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'nama': nama,
            'email': email,
            //'password': password,
            'role': 'pegawai', // Default role untuk user baru
            'createdAt': FieldValue.serverTimestamp(),
          });

          if (!mounted) return;

          // Tampilkan pesan sukses
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Registrasi berhasil. Silakan login."),
              backgroundColor: Colors.green,
            ),
          );

          // Kembali ke halaman login
          Navigator.pop(context);
        }
      } on FirebaseAuthException catch (e) {
        throw Exception(_getFirebaseAuthErrorMessage(e.code));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String _getFirebaseAuthErrorMessage(String code) {
    switch (code) {
      case "email-already-in-use":
        return "Email sudah terdaftar.";
      case "invalid-email":
        return "Format email tidak valid.";
      case "weak-password":
        return "Password terlalu lemah. Gunakan minimal 6 karakter.";
      default:
        return "Terjadi kesalahan. Coba lagi nanti.";
    }
  }

  @override
  void dispose() {
    namaController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        centerTitle: true,
      ),
      body: Container(
        alignment: Alignment.center,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'BOPEN DPMPTSP',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppSize.s32,
                  fontWeight: FontWeightManager.bold,
                  color: ColorManager.blue
                ),
              ),
              
              SizedBox(height: AppSize.s12),
              
              Text(
                'Register',
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontWeight: FontWeightManager.bold,
                  fontSize: AppSize.s32
                ),
              ),
              
              SizedBox(height: AppSize.s20),

              // Nama field
              SizedBox(
                width: 300,
                child: TextField(
                  controller: namaController,
                  enabled: !isLoading,
                  decoration: const InputDecoration(
                    hintText: 'Nama Lengkap',
                    border: UnderlineInputBorder(),
                  ),
                ),
              ),

              SizedBox(height: AppSize.s12),

              // Email field
              SizedBox(
                width: 300,
                child: TextField(
                  controller: emailController,
                  enabled: !isLoading,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'Email',
                    border: UnderlineInputBorder(),
                  ),
                ),
              ),

              SizedBox(height: AppSize.s12),

              // Password field
              SizedBox(
                width: 300,
                child: TextField(
                  controller: passwordController,
                  enabled: !isLoading,
                  obscureText: isObsecurePassword,
                  decoration: InputDecoration(
                    suffixIcon: IconButton(
                      icon: Icon(
                        isObsecurePassword ? Icons.visibility : Icons.visibility_off
                      ),
                      onPressed: () {
                        setState(() {
                          isObsecurePassword = !isObsecurePassword;
                        });
                      },
                    ),
                    hintText: 'Password',
                    border: const UnderlineInputBorder(),
                  ),
                ),
              ),

              SizedBox(height: AppSize.s12),

              // Confirm Password field
              SizedBox(
                width: 300,
                child: TextField(
                  controller: confirmPasswordController,
                  enabled: !isLoading,
                  obscureText: isObsecureConfirmPassword,
                  decoration: InputDecoration(
                    suffixIcon: IconButton(
                      icon: Icon(
                        isObsecureConfirmPassword ? Icons.visibility : Icons.visibility_off
                      ),
                      onPressed: () {
                        setState(() {
                          isObsecureConfirmPassword = !isObsecureConfirmPassword;
                        });
                      },
                    ),
                    hintText: 'Konfirmasi Password',
                    border: const UnderlineInputBorder(),
                  ),
                ),
              ),

              SizedBox(height: AppSize.s20),

              isLoading 
                ? const CircularProgressIndicator()
                : CustomButton(
                    width: 137,
                    height: 35,
                    title: 'Register',
                    onTap: registerUser,
                  ),
                  
              SizedBox(height: AppSize.s16),

              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: Text(
                  'Sudah punya akun? Login',
                  style: TextStyle(
                    color: ColorManager.blue,
                    fontWeight: FontWeightManager.medium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
