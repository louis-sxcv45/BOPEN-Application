import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_textfield/dropdown_textfield.dart';
import 'package:flutter/material.dart';
import 'package:project_pkl/src/common_widgets/custom_button.dart';
import 'package:project_pkl/src/style_manager/values_manager.dart';
import 'package:project_pkl/src/common_widgets/voting_text_filed.dart';
import 'package:project_pkl/src/style_manager/font_family_manager.dart';

class VotingDataASN extends StatefulWidget {
  const VotingDataASN({super.key});
  @override
  State<VotingDataASN> createState() => _VotingDataASNState();
}

class _VotingDataASNState extends State<VotingDataASN> {
  final SingleValueDropDownController namaKaryawanController =
      SingleValueDropDownController();
  final TextEditingController disiplinFieldController = TextEditingController();
  final TextEditingController orientasiFieldController = TextEditingController();
  final TextEditingController inovatifFieldController = TextEditingController();
  final TextEditingController penampilanFieldController = TextEditingController();

  String nip = '';
  String nama = '';
  String jabatan = '';
  int totalBobot = 0;
  bool isLoading = false;
  bool isDataLoading = true;
  List<DropDownValueModel> pegawaiList = [];
  String? error;

  @override
  void initState() {
    super.initState();
    _loadPegawaiData();
    
    // Add listeners for bobot calculation
    disiplinFieldController.addListener(_hitungTotalBobot);
    orientasiFieldController.addListener(_hitungTotalBobot);
    inovatifFieldController.addListener(_hitungTotalBobot);
    penampilanFieldController.addListener(_hitungTotalBobot);
  }

  void _hitungTotalBobot() {
    setState(() {
      int disiplin = int.tryParse(disiplinFieldController.text) ?? 0;
      int orientasi = int.tryParse(orientasiFieldController.text) ?? 0;
      int inovatif = int.tryParse(inovatifFieldController.text) ?? 0;
      int penampilan = int.tryParse(penampilanFieldController.text) ?? 0;

      totalBobot = (disiplin + orientasi + inovatif + penampilan) ~/ 4;
    });
  }

  Future<void> _loadPegawaiData() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('asn').get();
      if (mounted) {
        setState(() {
          pegawaiList = querySnapshot.docs.map((doc) {
            final data = doc.data();
            return DropDownValueModel(
              name: data['nama'] ?? 'Unknown Name',
              value: {
                'nip': data['nip'] ?? 'Unknown NIP',
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

  Future<void> saveVotingData() async {
    if (nama.isEmpty || totalBobot == 0) {
      _showErrorMessage('Harap isi semua data yang diperlukan');
      return;
    }

    setState(() => isLoading = true);

    try {
      final collectionRef = FirebaseFirestore.instance.collection('penilaian_asn');
      final existingDocs = await collectionRef.where('nip', isEqualTo: nip).get();

      if (existingDocs.docs.isNotEmpty) {
        // Update existing document
        await collectionRef.doc(existingDocs.docs.first.id).update({
          'disiplin': int.tryParse(disiplinFieldController.text) ?? 0,
          'orientasi_pelayanan': int.tryParse(orientasiFieldController.text) ?? 0,
          'inovatif': int.tryParse(inovatifFieldController.text) ?? 0,
          'penampilan': int.tryParse(penampilanFieldController.text) ?? 0,
          'bobot': totalBobot,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        // Create new document
        await collectionRef.add({
          'nama': nama,
          'nip': nip,
          'jabatan': jabatan,
          'disiplin': int.tryParse(disiplinFieldController.text) ?? 0,
          'orientasi_pelayanan': int.tryParse(orientasiFieldController.text) ?? 0,
          'inovatif': int.tryParse(inovatifFieldController.text) ?? 0,
          'penampilan': int.tryParse(penampilanFieldController.text) ?? 0,
          'bobot': totalBobot,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        _showSuccessMessage('Data berhasil disimpan!');
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Error menyimpan data: $e');
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
      nip = '';
      jabatan = '';
      totalBobot = 0;
      disiplinFieldController.clear();
      orientasiFieldController.clear();
      inovatifFieldController.clear();
      penampilanFieldController.clear();
      namaKaryawanController.clearDropDown();
    });
  }

  @override
  void dispose() {
    namaKaryawanController.dispose();
    disiplinFieldController.dispose();
    orientasiFieldController.dispose();
    inovatifFieldController.dispose();
    penampilanFieldController.dispose();
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
                                borderRadius: BorderRadius.circular(AppSize.s12),
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
                                  nip = selectedValue['nip'] ?? '';
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
                                  'NIP: $nip',
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
                          const SizedBox(height: 24),
                          VotingTextField(
                            title: 'Disiplin',
                            votingFieldController: disiplinFieldController,
                            hintText: 'Bobot Disiplin',
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
                            title: 'Penampilan, Kecakapan, Kerjasama, dan Tanggung Jawab',
                            votingFieldController: penampilanFieldController,
                            hintText: 'Bobot Penampilan, Kecakapan, Kerjasama, dan Tanggung Jawab',
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(AppSize.s12),
                            ),
                            child: Text(
                              'Total Bobot: $totalBobot',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : CustomButton(
                                  width: double.infinity,
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
