import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_textfield/dropdown_textfield.dart';
import 'package:flutter/material.dart';
import 'package:project_pkl/src/common_widgets/custom_button.dart';
import 'package:project_pkl/src/common_widgets/voting_text_filed.dart';
import 'package:project_pkl/src/features/collection_manager_service/collection_manager.dart';
import 'package:project_pkl/src/style_manager/font_family_manager.dart';
import 'package:project_pkl/src/style_manager/values_manager.dart';

class VotingDataASN extends StatefulWidget {
  const VotingDataASN({super.key});
  @override
  State<VotingDataASN> createState() => _VotingDataASNState();
}

class _VotingDataASNState extends State<VotingDataASN> {
  final SingleValueDropDownController namaKaryawanController =
      SingleValueDropDownController();
  final TextEditingController oritentasiPelayananFieldController = TextEditingController();
  final TextEditingController akuntableFieldController = TextEditingController();
  final TextEditingController kompetenFieldController = TextEditingController();
  final TextEditingController harmonisFieldController = TextEditingController();
  final TextEditingController loyalFieldController = TextEditingController();
  final TextEditingController adaptifFieldController = TextEditingController();
  final TextEditingController kolaboratifFieldController = TextEditingController();

  final AsnCollectionManager _collectionManager = AsnCollectionManager();

  String nip = '';
  String nama = '';
  String jabatan = '';
  int totalBobot = 0;
  bool isLoading = false;
  bool isDataLoading = true;
  List<DropDownValueModel> pegawaiList = [];
  String? error;
  String currentCollection = 'penilaian_asn';

  @override
  void initState() {
    super.initState();
    _loadCurrentCollection();
    _loadPegawaiData();
    
    // Add listeners for bobot calculation
    oritentasiPelayananFieldController.addListener(_hitungTotalBobot);
    akuntableFieldController.addListener(_hitungTotalBobot);
    kompetenFieldController.addListener(_hitungTotalBobot);
    harmonisFieldController.addListener(_hitungTotalBobot);
    loyalFieldController.addListener(_hitungTotalBobot);
    adaptifFieldController.addListener(_hitungTotalBobot);
    kolaboratifFieldController.addListener(_hitungTotalBobot);
  }

  void _hitungTotalBobot() {
    setState(() {
      int berorientasi_pelayanan = int.tryParse(oritentasiPelayananFieldController.text) ?? 0;
      int akuntable = int.tryParse(akuntableFieldController.text) ?? 0;
      int kompeten = int.tryParse(kompetenFieldController.text) ?? 0;
      int harmonis = int.tryParse(harmonisFieldController.text) ?? 0;
      int loyal = int.tryParse(loyalFieldController.text) ?? 0;
      int adaptif = int.tryParse(adaptifFieldController.text) ?? 0;
      int kolaboratif = int.tryParse(kolaboratifFieldController.text) ?? 0;

      double rataRata = (berorientasi_pelayanan + akuntable + kompeten + harmonis + loyal + adaptif + kolaboratif) / 7;
      totalBobot = rataRata.round();
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

  Future<void> _loadCurrentCollection() async {
    String collection = await _collectionManager.getCurrentCollectionName();
    setState(() {
      currentCollection = collection;
    });
  }

  Future<void> saveVotingData() async {
    if (nama.isEmpty || totalBobot == 0) {
      _showErrorMessage('Harap isi semua data yang diperlukan');
      return;
    }

    setState(() => isLoading = true);

    try {
      final collectionRef = FirebaseFirestore.instance.collection(currentCollection);
      final existingDocs = await collectionRef.where('nip', isEqualTo: nip).get();

      if (existingDocs.docs.isNotEmpty) {
        // Update existing document
        await collectionRef.doc(existingDocs.docs.first.id).update({
          'berorientasi_pelayanan': int.tryParse(oritentasiPelayananFieldController.text) ?? 0,
          'akuntable': int.tryParse(akuntableFieldController.text) ?? 0,
          'kompeten': int.tryParse(kompetenFieldController.text) ?? 0,
          'harmonis': int.tryParse(harmonisFieldController.text) ?? 0,
          'loyal': int.tryParse(loyalFieldController.text) ?? 0,
          'adaptif': int.tryParse(adaptifFieldController.text) ?? 0,
          'kolaboratif': int.tryParse(kolaboratifFieldController.text) ?? 0,
          'bobot': totalBobot,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        // Create new document
        await collectionRef.add({
          'nama': nama,
          'nip': nip,
          'jabatan': jabatan,
          'berorientasi_pelayanan': int.tryParse(oritentasiPelayananFieldController.text) ?? 0,
          'akuntable': int.tryParse(akuntableFieldController.text) ?? 0,
          'kompeten': int.tryParse(kompetenFieldController.text) ?? 0,
          'harmonis': int.tryParse(harmonisFieldController.text) ?? 0,
          'loyal': int.tryParse(loyalFieldController.text) ?? 0,
          'adaptif': int.tryParse(adaptifFieldController.text) ?? 0,
          'kolaboratif': int.tryParse(adaptifFieldController.text) ?? 0,
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
      oritentasiPelayananFieldController.clear();
      akuntableFieldController.clear();
      kompetenFieldController.clear();
      harmonisFieldController.clear();
      loyalFieldController.clear();
      adaptifFieldController.clear();
      kolaboratifFieldController.clear();
      namaKaryawanController.clearDropDown();
    });
  }

  @override
  void dispose() {
    namaKaryawanController.dispose();
    oritentasiPelayananFieldController.dispose();
    akuntableFieldController.dispose();
    kompetenFieldController.dispose();
    harmonisFieldController.dispose();
    loyalFieldController.dispose();
    adaptifFieldController.dispose();
    kolaboratifFieldController.dispose();
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
                            clearIconProperty: IconProperty(
                              color: Colors.black
                            ),
                            searchTextStyle: TextStyle(
                              color: Colors.black
                            ),
                            listTextStyle: TextStyle(
                              color: Colors.black
                            ),
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
                            title: 'Berorientasi Pelayanan (Komitmen Memberikan Pelayanan Prima Demi Kepuasan Masyarakat)',
                            votingFieldController: oritentasiPelayananFieldController,
                            hintText: 'Bobot Berorientasi Pelayanan',
                          ),
                          VotingTextField(
                            title: 'Akuntable (Tanggung Jawab Atas Kepercayaan Yang Diberikan)',
                            votingFieldController: akuntableFieldController,
                            hintText: 'Bobot Akuntable',
                          ),
                          VotingTextField(
                            title: 'Kompeten (Terus Belajar dan Mengembangkan Kapabilitas)',
                            votingFieldController: kompetenFieldController,
                            hintText: 'Bobot Kompeten',
                          ),
                          VotingTextField(
                            title: 'Harmonis (Saling Perduli dan Menghargai Perbedaan)',
                            votingFieldController: harmonisFieldController,
                            hintText: 'Bobot Harmonis',
                          ),
                          VotingTextField(
                            title: 'Loyal (Dedikasi dan Mengutamakan Kepentingan Bangsa dan Negara)',
                            votingFieldController: loyalFieldController,
                            hintText: 'Bobot Loyal',
                          ),
                          VotingTextField(
                            title: 'Adaptif (Inovasi dan Antusias dalam Menggerakkan Serta Menghadapi Perubahan)',
                            votingFieldController: adaptifFieldController,
                            hintText: 'Bobot Adaptif',
                          ),
                          VotingTextField(
                            title: 'Kolaboratif (Membangun Kerjasama Yang Sinergis)',
                            votingFieldController: kolaboratifFieldController,
                            hintText: 'Bobot Kolaboratif',
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