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

  @override
  void dispose(){
    userNameController.clear();
    passwordController.clear();
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
                
              SizedBox(
                height: AppSize.s12,
              ),
                
              Text(
                'Login',
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontWeight: FontWeightManager.bold,
                  fontSize: AppSize.s32
                ),
              ),
                
              SizedBox(
                height: AppSize.s12,
              ),
                
              SizedBox(
                width: 300,
                child: TextField(
                  controller: userNameController,
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
                
              SizedBox(
                height: AppSize.s12,
              ),
                
              SizedBox(
                width: 300,
                child: TextField(
                  controller: passwordController,
                  obscureText: isObsecure,
                  decoration: InputDecoration(
                    suffix: IconButton(
                      icon: Icon(
                        isObsecure ? Icons.visibility : Icons.visibility_off
                      ),
                      onPressed: () {
                        setState(() {
                          isObsecure =! isObsecure;
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
                
              SizedBox(
                height: AppSize.s12,
              ),
                
              CustomButton(
                title: 'Login', 
                onTap: (){
                  Navigator.pushAndRemoveUntil(
                    context, 
                    MaterialPageRoute(
                      builder: (context)=> TabBarNavigation()),
                      (Route<dynamic> route) => false
                    );
                })
            ],
          ),
        ),
      ),
    );
  }
}