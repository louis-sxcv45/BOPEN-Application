import 'package:flutter/material.dart';
import 'package:project_pkl/src/features/asn_page/UI/asn_data_screen.dart';
import 'package:project_pkl/src/features/login/UI/login_screen.dart';
import 'package:project_pkl/src/features/non_asn_page/non_asn_data_screen.dart';
import 'package:project_pkl/src/style_manager/color_manager.dart';
import 'package:project_pkl/src/style_manager/font_family_manager.dart';

class TabBarNavigation extends StatelessWidget {
  const TabBarNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'BOPEN DPMPTSP',
            style: TextStyle(
              fontSize: FontSizeManager.f20,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.logout,
              ),
              onPressed: (){
                Navigator.pushReplacement(
                  context, 
                  MaterialPageRoute(builder: (context) => const LoginScreen()));
              },
            )
          ],
          bottom: TabBar(
            indicatorColor: ColorManager.blue,
            labelColor: ColorManager.blue,
            tabs: [
              Tab(
                text: 'ASN',
              ),
              Tab(
                text: 'NON-ASN',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            AsnDataScreen(),
            NonAsnDataScreen(),
          ],
        ),
      ),
    );
  }
}