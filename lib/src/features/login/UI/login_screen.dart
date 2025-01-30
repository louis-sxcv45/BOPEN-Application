import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:project_pkl/src/common_widgets/custom_button.dart';
import 'package:project_pkl/src/style_manager/color_manager.dart';
import 'package:project_pkl/src/style_manager/font_family_manager.dart';
import 'package:project_pkl/src/style_manager/values_manager.dart';
import 'package:project_pkl/src/tab_bar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final userNameController = TextEditingController();
  final passwordController = TextEditingController();
  bool isObsecure = true;
  bool isLoading = false;

  Future<void> loginWithFirestore() async {
    setState(() {
      isLoading = true;
    });

    try {
      final username = userNameController.text.trim();
      final password = passwordController.text.trim();

      if (username.isEmpty || password.isEmpty) {
        throw Exception("Username dan password tidak boleh kosong");
      }

      final QuerySnapshot userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      if (!mounted) return;

      if (userQuery.docs.isNotEmpty) {
        final userData = userQuery.docs.first.data() as Map<String, dynamic>;
        final storedPassword = userData['password'];

        if (storedPassword == password) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const TabBarNavigation()),
          );
        } else {
          throw Exception("Password salah");
        }
      } else {
        throw Exception("User tidak ditemukan");
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

  @override
  void dispose() {
    userNameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'DPMPTSP BOPEN',
                textAlign: TextAlign.start,
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
                  controller: userNameController,
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    hintText: 'Username',
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
                    onTap: loginWithFirestore
                  )
            ],
          ),
        ),
      ),
    );
  }
}