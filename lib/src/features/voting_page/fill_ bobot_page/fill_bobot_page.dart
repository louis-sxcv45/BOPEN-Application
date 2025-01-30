import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:project_pkl/src/common_widgets/custom_button.dart';
import 'package:project_pkl/src/common_widgets/voting_text_filed.dart';

class FillBobotPage extends StatefulWidget {
  final String nama;
  final String nip;
  final String jabatan;

  const FillBobotPage({
    super.key,
    required this.nama,
    required this.nip,
    required this.jabatan,
  });

  @override
  State<FillBobotPage> createState() => _FillBobotPageState();
}

class _FillBobotPageState extends State<FillBobotPage> {
  final TextEditingController disiplinFieldController = TextEditingController();
  final TextEditingController orientasiFieldController = TextEditingController();
  final TextEditingController inovatifFieldController = TextEditingController();
  final TextEditingController penampilanFieldController = TextEditingController();

  int totalBobot = 0;

  @override
  void initState() {
    super.initState();
    
    // Tambahkan listener agar totalBobot selalu diperbarui saat input berubah
    disiplinFieldController.addListener(_hitungTotalBobot);
    orientasiFieldController.addListener(_hitungTotalBobot);
    inovatifFieldController.addListener(_hitungTotalBobot);
    penampilanFieldController.addListener(_hitungTotalBobot);
  }

  @override
  void dispose() {
    // Hapus listener untuk menghindari memory leak
    disiplinFieldController.removeListener(_hitungTotalBobot);
    orientasiFieldController.removeListener(_hitungTotalBobot);
    inovatifFieldController.removeListener(_hitungTotalBobot);
    penampilanFieldController.removeListener(_hitungTotalBobot);

    disiplinFieldController.dispose();
    orientasiFieldController.dispose();
    inovatifFieldController.dispose();
    penampilanFieldController.dispose();

    super.dispose();
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

  Future<void> _saveData() async {
  try {
    final docRef = FirebaseFirestore.instance.collection('penilaian_asn').doc(widget.nip);

    await docRef.set({
      'nama': widget.nama,
      'nip': widget.nip,
      'jabatan': widget.jabatan,
      'disiplin': int.tryParse(disiplinFieldController.text) ?? 0,
      'orientasi_pelayanan': int.tryParse(orientasiFieldController.text) ?? 0,
      'inovatif': int.tryParse(inovatifFieldController.text) ?? 0,
      'penampilan': int.tryParse(penampilanFieldController.text) ?? 0,
      'bobot': totalBobot,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)); // 🔹 Gunakan merge agar tidak membuat data ganda

    // Kembali ke halaman sebelumnya dengan mengirim total bobot
    Navigator.pop(context, totalBobot);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Gagal menyimpan data")),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Isi Nilai Bobot')),
      body: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: SingleChildScrollView(
          child: Column(
            children: [
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
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Total Bobot: $totalBobot',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ),
              const SizedBox(height: 16),
              CustomButton(
                title: 'Simpan',
                onTap: _saveData,
                width: 137,
                height: 35,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
