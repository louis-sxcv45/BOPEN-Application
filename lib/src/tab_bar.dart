import 'package:flutter/material.dart';
import 'package:project_pkl/src/features/asn_page/UI/asn_data_screen.dart';
import 'package:project_pkl/src/style_manager/color_manager.dart';

class TabBarNavigation extends StatelessWidget {
  const TabBarNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'DPMPTSP BOPEN',
            style: TextStyle(),
          ),
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
            Container(
              color: ColorManager.yellow,
            ),
          ],
        ),
      ),
    );
  }
}