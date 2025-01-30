import 'package:dropdown_textfield/dropdown_textfield.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_pkl/src/common_widgets/custom_button.dart';
import 'package:project_pkl/src/features/voting_page/fill_%20bobot_page/fill_bobot_page.dart';
import 'package:project_pkl/src/style_manager/font_family_manager.dart';
import 'package:project_pkl/src/style_manager/values_manager.dart';

class VotingNonAsn extends StatefulWidget {
  const VotingNonAsn({super.key});

  @override
  State<VotingNonAsn> createState() => _VotingNonAsnState();
}

class _VotingNonAsnState extends State<VotingNonAsn> {
  final SingleValueDropDownController namaKaryawanController =
      SingleValueDropDownController();
  final TextEditingController bobotController = TextEditingController();

  String nama = '';
  String jabatan = '';
  int bobotDetails = 0;
  bool isLoading = false;
  bool isDataLoading = true;
  List<DropDownValueModel> pegawaiList = [];
  String? error;

  @override
  void initState() {
    super.initState();
    _loadPegawaiData();
  }

  Future<void> _loadPegawaiData() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('non_asn').get();
      if (mounted) {
        setState(() {
          pegawaiList = querySnapshot.docs.map((doc) {
            final data = doc.data();
            return DropDownValueModel(
              name: data['nama'] ?? 'Unknown Name',
              value: {
                'nama': data['nama'] ?? 'Unknown Name',
                'jabatan': data['jabatan'] ?? 'Unknown Jabatan',
              },
            );
          }).toList();
          isDataLoading = false;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = 'Error loading data: $e';
          isDataLoading = false;
          pegawaiList = [];
        });
      }
      debugPrint('Error fetching data: $e');
    }
  }

  void _navigateToFillBobotPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FillBobotPage()),
    );

    if (result != null && mounted) {
      setState(() {
        bobotDetails = result; // Menampilkan total bobot
      });
    }
  }

  Future<void> saveVotingData() async {
    if (nama.isEmpty || bobotDetails == 0) {
      _showErrorMessage('Please fill in all required fields');
      return;
    }

    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('penilaian_non_asn').add({
        'nama': nama,
        'jabatan': jabatan,
        'bobot': bobotDetails, // Now saving as integer
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _showSuccessMessage('Data saved successfully!');
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Error saving data: $e');
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _resetForm() {
    setState(() {
      nama = '';
      jabatan = '';
      bobotDetails = 0;
      bobotController.clear();
      namaKaryawanController.clearDropDown();
    });
  }

  @override
  void dispose() {
    namaKaryawanController.dispose();
    bobotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fill Voting Data ASN'),
      ),
      body: isDataLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : pegawaiList.isEmpty
                  ? const Center(child: Text('No data available'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropDownTextField(
                            controller: namaKaryawanController,
                            clearOption: true,
                            enableSearch: true,
                            textFieldDecoration: InputDecoration(
                              labelText: 'Pilih Karyawan',
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSize.s12),
                              ),
                            ),
                            dropDownList: pegawaiList,
                            onChanged: (value) {
                              if (value != null &&
                                  value is DropDownValueModel &&
                                  value.value is Map<String, dynamic>) {
                                final selectedValue =
                                    value.value as Map<String, dynamic>;
                                setState(() {
                                  nama = selectedValue['nama'] ?? '';
                                  jabatan = selectedValue['jabatan'] ?? '';
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(AppSize.s12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nama: $nama',
                                  style: TextStyle(
                                    fontSize: FontSizeManager.f12,
                                    fontFamily: FontFamilyManager.latoFont,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Jabatan: $jabatan',
                                  style: TextStyle(
                                    fontSize: FontSizeManager.f12,
                                    fontFamily: FontFamilyManager.latoFont,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (bobotDetails > 0)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(AppSize.s12),
                              ),
                              child: Text(
                                'Total Bobot: $bobotDetails',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          const SizedBox(height: 24),
                          CustomButton(
                            title: 'Isi Nilai Bobot',
                            onTap: _navigateToFillBobotPage,
                            width: 137,
                            height: 35,
                          ),
                          const SizedBox(height: 24),
                          isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : CustomButton(
                                width: 400,
                                height: 45,
                                  title: 'Simpan Data',
                                  onTap: saveVotingData,
                                ),
                        ],
                      ),
                    ),
    );
  }
}
