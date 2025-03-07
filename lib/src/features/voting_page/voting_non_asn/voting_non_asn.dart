import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_textfield/dropdown_textfield.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:project_pkl/src/common_widgets/custom_button.dart';
import 'package:project_pkl/src/common_widgets/voting_text_filed.dart';
import 'package:project_pkl/src/features/collection_manager_service/collection_manager.dart';
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
  final TextEditingController disiplinFieldController = TextEditingController();
  final TextEditingController orientasiFieldController = TextEditingController();
  final TextEditingController inovatifFieldController = TextEditingController();
  final TextEditingController penampilanFieldController = TextEditingController();

  final NonAsnCollectionManager _collectionManager = NonAsnCollectionManager();

  String nama = '';
  String jabatan = '';
  double totalBobot = 0;
  bool isLoading = false;
  bool isDataLoading = true;
  List<DropDownValueModel> pegawaiList = [];
  String? error;
  String currentCollection = 'penilaian_non_asn';
  String? _currentUserEmail;

  @override
  void initState() {
    super.initState();
    _loadCurrentCollection();
    _getCurrentUserInfo();
    _loadPegawaiData();
    
    // Add listeners for bobot calculation
    disiplinFieldController.addListener(_hitungTotalBobot);
    orientasiFieldController.addListener(_hitungTotalBobot);
    inovatifFieldController.addListener(_hitungTotalBobot);
    penampilanFieldController.addListener(_hitungTotalBobot);
  }

  Future<void> _getCurrentUserInfo() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUserEmail = user.email;
      });
    }
  }

  void _hitungTotalBobot() {
    setState(() {
      int disiplin = int.tryParse(disiplinFieldController.text) ?? 0;
      int orientasi = int.tryParse(orientasiFieldController.text) ?? 0;
      int inovatif = int.tryParse(inovatifFieldController.text) ?? 0;
      int penampilan = int.tryParse(penampilanFieldController.text) ?? 0;

      // Validasi nilai (maksimal 100 untuk total)
      disiplin = _validateInput(disiplin);
      orientasi = _validateInput(orientasi);
      inovatif = _validateInput(inovatif);
      penampilan = _validateInput(penampilan);

      // Menghitung rata-rata dari 7 kriteria
      totalBobot = ((disiplin + orientasi + inovatif + penampilan) / 4).round() as double;
    });
  }

  int _validateInput(int value) {
    // Memastikan nilai tidak melebihi 100
    return value > 100 ? 100 : value;
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
      final existingDocs = await collectionRef.where('nama', isEqualTo: nama).get();

      // Menyiapkan data detail penilaian
      final Map<String, dynamic> detailPenilaian = {
        'disiplin': int.tryParse(disiplinFieldController.text) ?? 0,
        'orientasi_pelayanan': int.tryParse(orientasiFieldController.text) ?? 0,
        'inovatif': int.tryParse(inovatifFieldController.text) ?? 0,
        'penampilan': int.tryParse(penampilanFieldController.text) ?? 0,
      };

      // Use regular DateTime instead of FieldValue.serverTimestamp() in arrays
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;

      // Menyiapkan data penilaian penilai
      final Map<String, dynamic> penilaianData = {
        'email_penilai': _currentUserEmail,
        'nilai': totalBobot.round(),
        'detail_penilaian': detailPenilaian,
        'timestamp': now, // Use regular datetime for inside arrays
      };

      if (existingDocs.docs.isNotEmpty) {
        // Dokumen non-ASN sudah ada, perbarui atau tambah hasil penilaian
        final docRef = existingDocs.docs.first.reference;
        final docData = existingDocs.docs.first.data();
        
        // Periksa apakah ada hasil_penilaian
        if (docData.containsKey('hasil_penilaian')) {
          final List<dynamic> hasilPenilaian = List<dynamic>.from(docData['hasil_penilaian']);
          
          // Cari penilaian dari email yang sama
          bool penilaianDitemukan = false;
          for (int i = 0; i < hasilPenilaian.length; i++) {
            if (hasilPenilaian[i]['email_penilai'] == _currentUserEmail) {
              // Perbarui penilaian yang sudah ada
              hasilPenilaian[i] = penilaianData;
              penilaianDitemukan = true;
              break;
            }
          }
          
          // Jika tidak ada penilaian dari email ini, tambahkan ke list
          if (!penilaianDitemukan) {
            hasilPenilaian.add(penilaianData);
          }
          
          // Update dokumen dengan hasil penilaian yang baru
          await docRef.update({
            'hasil_penilaian': hasilPenilaian,
            'timestamp': FieldValue.serverTimestamp(),
          });
        } else {
          // Buat array hasil_penilaian baru
          await docRef.update({
            'hasil_penilaian': [penilaianData],
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      } else {
        // Create new document
        await collectionRef.add({
          'nama': nama,
          'jabatan': jabatan,
          'hasil_penilaian': [penilaianData],
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
        title: const Text('Form Penilaian Non ASN'),
      ),
      body: isDataLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : pegawaiList.isEmpty
                  ? const Center(child: Text('Tidak ada data tersedia'))
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
                            searchTextStyle: const TextStyle(
                              color: Colors.black
                            ),
                            listTextStyle: const TextStyle(
                              color: Colors.black
                            ),
                            textFieldDecoration: InputDecoration(
                              labelText: 'Pilih Pegawai Non ASN',
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
                          const SizedBox(height: 24),
                          Text(
                            'Kriteria Penilaian (Nilai 0-100)',
                            style: TextStyle(
                              fontSize: FontSizeManager.f16,
                              fontWeight: FontWeight.bold,
                              fontFamily: FontFamilyManager.latoFont,
                            ),
                          ),
                          const SizedBox(height: 12),
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
                              'Total Bobot: ${totalBobot.toString()}',
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
                                  title: 'Simpan Penilaian',
                                  onTap: saveVotingData,
                                ),
                        ],
                      ),
                    ),
    );
  }
}