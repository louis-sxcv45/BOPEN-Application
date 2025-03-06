import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_pkl/src/common_widgets/custom_button.dart';
import 'package:project_pkl/src/style_manager/color_manager.dart';
import 'package:project_pkl/src/style_manager/font_family_manager.dart';
import 'package:project_pkl/src/style_manager/values_manager.dart';
import 'package:project_pkl/src/tab_bar.dart';
import 'package:project_pkl/src/features/register/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isObsecure = true;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userEmail = prefs.getString('userEmail');
    if (userEmail != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const TabBarNavigation()),
      );
    }
  }

  Future<void> loginWithEmailPassword() async {
    setState(() {
      isLoading = true;
    });

    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        throw Exception("Tidak ada koneksi internet");
      }

      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        throw Exception("Email dan password tidak boleh kosong");
      }

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Simpan sesi login di SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('userEmail', email);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const TabBarNavigation()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
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
                'Login',
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontWeight: FontWeightManager.bold,
                  fontSize: AppSize.s32
                ),
              ),
              
              SizedBox(height: AppSize.s12),

              SizedBox(
                width: 300,
                child: TextField(
                  controller: emailController,
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: ColorManager.black,
                        width: 5
                      )
                    )
                  ),
                ),
              ),
              
              SizedBox(height: AppSize.s12),

              SizedBox(
                width: 300,
                child: TextField(
                  controller: passwordController,
                  enabled: !isLoading,
                  obscureText: isObsecure,
                  decoration: InputDecoration(
                    suffix: IconButton(
                      icon: Icon(
                        isObsecure ? Icons.visibility : Icons.visibility_off
                      ),
                      onPressed: isLoading ? null : () {
                        setState(() {
                          isObsecure = !isObsecure;
                        });
                      },
                    ),
                    hintText: 'Password',
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: ColorManager.black,
                        width: 5
                      )
                    )
                  ),
                ),
              ),
              
              SizedBox(height: AppSize.s12),

              isLoading
                  ? const CircularProgressIndicator()
                  : CustomButton(
                      width: 137,
                      height: 35,
                      title: 'Login',
                      onTap: loginWithEmailPassword,
                    ),
              SizedBox(height: AppSize.s16),

              TextButton(
                onPressed: isLoading ? null : navigateToRegister,
                child: Text(
                  'Belum punya akun? Daftar',
                  style: TextStyle(
                    color: ColorManager.blue,
                    fontWeight: FontWeightManager.medium
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
