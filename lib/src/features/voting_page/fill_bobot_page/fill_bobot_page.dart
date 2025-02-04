import 'package:flutter/material.dart';
import 'package:project_pkl/src/common_widgets/custom_button.dart';
import 'package:project_pkl/src/common_widgets/voting_text_filed.dart';
import 'package:project_pkl/src/style_manager/values_manager.dart';

class FillBobotPage extends StatefulWidget {
  const FillBobotPage({super.key});

  @override
  State<FillBobotPage> createState() => _FillBobotPageState();
}

class _FillBobotPageState extends State<FillBobotPage> {
  final displinFieldController = TextEditingController();
  final orientasiFieldController = TextEditingController();
  final inovatifFieldController = TextEditingController();
  final penampilanFieldController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fill Bobot Page'),
      ),
      body: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppMargin.m8
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              VotingTextField(
                title: 'Displin',
                votingFieldController: displinFieldController,
                hintText: 'Bobot Displin',
              ),
              VotingTextField(
                title: 'Orientasi Pelayanan',
                votingFieldController: orientasiFieldController,
                hintText: 'Bobot Orientasi Pelayanan',
              ),
              VotingTextField(
                title: 'Inovatif',
                votingFieldController: inovatifFieldController,
                hintText: 'Bobot Inovatif',
              ),
              VotingTextField(
                title: 'Penampilan, kecakapan, kerjasama dan tanggung jawab',
                votingFieldController: penampilanFieldController,
                hintText: 'Bobot Penampilan, kecakapan, kerjasama dan tanggung jawab',
              ),


              const SizedBox(
                height: AppSize.s12,
              ),

              CustomButton(
                title: 'Simpan', 
                onTap: () {
                    int totalBobot = (int.parse(displinFieldController.text) + int.parse(orientasiFieldController.text) + int.parse(inovatifFieldController.text) + int.parse(penampilanFieldController.text)) ~/ 4;
                  Navigator.pop(context, totalBobot);
                }, 
                width: 137, 
                height: 35
              )
            ],
          ),
        ),
      ),
    );
  }
}