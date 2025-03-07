import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_pkl/src/features/collection_manager_service/collection_manager.dart';

class AsnDetailPage extends StatefulWidget {
  final String documentId;
  final String? collectionName;

  const AsnDetailPage({super.key, required this.documentId, this.collectionName});

  @override
  State<AsnDetailPage> createState() => _AsnDetailPageState();
}

class _AsnDetailPageState extends State<AsnDetailPage> {
  final AsnCollectionManager _collectionManager = AsnCollectionManager();
  String? currentCollection;

  @override
  void initState() {
    super.initState();
    _loadCollection();
  }

  Future<void> _loadCollection() async {
    String collection = widget.collectionName ?? await _collectionManager.getCurrentCollectionName();
    setState(() {
      currentCollection = collection;
    });
  }

  Future<String> _getNamaPenilai(String emailPenilai) async {
  try {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: emailPenilai)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final userData = querySnapshot.docs.first.data();
      return userData['nama'] ?? 'Unknown'; // Ambil nama pengguna
    }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
    return 'Unknown'; // Fallback jika data tidak ditemukan
  }

  String _formatCollectionName(String collectionName) {
  if (collectionName == 'penilaian_asn') {
    return 'Triwulan 1'; // Jika koleksi default (tanpa angka)
  }
  // Ekstrak angka dari nama koleksi (misal: penilaian_asn_2 -> 2)
  final parts = collectionName.split('_');
  if (parts.length > 2) {
    final number = parts.last;
    return 'Triwulan $number';
  }
  return 'Triwulan 1'; // Fallback jika format tidak sesuai
  }

  @override
  Widget build(BuildContext context) {
    if (currentCollection == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pegawai'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection(currentCollection!)
            .doc(widget.documentId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Data pegawai tidak ditemukan'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          // Extract hasil_penilaian list from data
          final List<dynamic> hasilPenilaian = data.containsKey('hasil_penilaian')
              ? data['hasil_penilaian'] as List<dynamic>
              : [];

          // Calculate total bobot from all evaluators
          /*double totalBobot = 0;
          if (hasilPenilaian.isNotEmpty) {
            for (var penilaian in hasilPenilaian) {
              if (penilaian.containsKey('nilai')) {
                totalBobot += (penilaian['nilai'] as num).toDouble();
              }
            }
          }
          // Bulatkan ke bilangan bulat
          totalBobot = totalBobot.round() as double;*/

          // Calculate average for each parameter
          Map<String, double> parameterAverages = {};
          if (hasilPenilaian.isNotEmpty) {
            List<String> parameters = [
              'berorientasi_pelayanan',
              'akuntable',
              'kompeten',
              'harmonis',
              'loyal',
              'adaptif',
              'kolaboratif',
            ];

            for (var parameter in parameters) {
              double total = 0;
              int count = 0;
              for (var penilaian in hasilPenilaian) {
                if (penilaian['detail_penilaian'] != null && penilaian['detail_penilaian'][parameter] != null) {
                  total += (penilaian['detail_penilaian'][parameter] as num).toDouble();
                  count++;
                }
              }
              parameterAverages[parameter] = count > 0 ? (total / count).roundToDouble() : 0;
            }
          }

          // Calculate grand total from parameter averages
          double grandTotal = parameterAverages.values.reduce((a, b) => a + b);

          //Calculate total bobot as average of parameter averages
          double totalBobot = grandTotal / parameterAverages.length;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const CircleAvatar(
                            radius: 50,
                            child: Icon(Icons.person, size: 50),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            data['nama'] ?? '',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            data['nip'] ?? '',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              data['jabatan'] ?? '',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Collection Info Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.folder_outlined, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Periode Penilaian: ${_formatCollectionName(currentCollection!)}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Header for all evaluations
                  if (hasilPenilaian.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12.0),
                      child: Text(
                        'Hasil Penilaian dari Semua Penilai',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  // Dynamic Cards for each evaluator's assessment
                  ...hasilPenilaian.asMap().entries.map((entry) {
                    final index = entry.key;
                    final penilaian = entry.value;
                    final emailPenilai = penilaian['email_penilai'] ?? 'Unknown Penilai';
                    final detailPenilaian = penilaian['detail_penilaian'] as Map<String, dynamic>? ?? {};
                    final nilai = penilaian['nilai'] ?? 0;
                    final timestamp = penilaian['timestamp'];
                    // Generate a color based on the evaluator index
                    final Color cardColor = Colors.primaries[index % Colors.primaries.length];

                    return FutureBuilder<String>(
                      future: _getNamaPenilai(emailPenilai), // Ambil nama penilai
                      builder: (context, snapshot) {
                        ///final namaPenilai = snapshot.data ?? 'Unknown Penilai'; // Default jika data tidak ditemukan

                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: BorderSide(color: Colors.blue.withOpacity(0.3), width: 1.5),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.person_outline, color: cardColor),
                                    const SizedBox(width: 8),
                                    /*Expanded(
                                      child: Text(
                                       'Penilai: $namaPenilai', // Tampilkan nama penilai
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: cardColor,
                                        ),
                                      ),
                                    ),*/
                                  ],
                                ),
                                const Divider(thickness: 1.5),
                                const SizedBox(height: 12),
                                _buildScoreItem(
                                  'Berorientasi Pelayanan',
                                  detailPenilaian['berorientasi_pelayanan']?.toString() ?? '0',
                                  Colors.blue,
                                ),
                                _buildScoreItem(
                                  'Akuntable',
                                  detailPenilaian['akuntable']?.toString() ?? '0',
                                  Colors.green,
                                ),
                                _buildScoreItem(
                                  'Kompeten',
                                  detailPenilaian['kompeten']?.toString() ?? '0',
                                  Colors.orange,
                                ),
                                _buildScoreItem(
                                  'Harmonis',
                                  detailPenilaian['harmonis']?.toString() ?? '0',
                                  Colors.purple,
                                ),
                                _buildScoreItem(
                                  'Loyal',
                                  detailPenilaian['loyal']?.toString() ?? '0',
                                  Colors.red,
                                ),
                                _buildScoreItem(
                                  'Adaptif',
                                  detailPenilaian['adaptif']?.toString() ?? '0',
                                  Colors.yellow.shade800,
                                ),
                                _buildScoreItem(
                                  'Kolaboratif',
                                  detailPenilaian['kolaboratif']?.toString() ?? '0',
                                  Colors.brown,
                                ),
                                const Divider(thickness: 1.5),
                                _buildTotalScore(
                                  nilai.toString(),
                                  cardColor,
                                ),
                                if (timestamp != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      'Waktu penilaian: ${_formatTimestamp(timestamp)}',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),

                  // If there are no evaluations yet
                  if (hasilPenilaian.isEmpty)
                    const Card(
                      elevation: 2,
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            'Belum ada hasil penilaian untuk pegawai ini',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Grand Total Card
                  if (hasilPenilaian.isNotEmpty)
                    Card(
                      elevation: 6,
                      margin: const EdgeInsets.only(top: 24, bottom: 16),
                      color: Colors.blue.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: const BorderSide(color: Colors.blue, width: 2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.summarize, color: Colors.blue),
                                SizedBox(width: 8),
                                Text(
                                  'Ringkasan Penilaian',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(thickness: 2, color: Colors.blue),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Jumlah Penilai:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${hasilPenilaian.length}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...parameterAverages.entries.map((entry) {
                              return _buildScoreItem(
                                entry.key.replaceAll('_', ' ').toUpperCase(),
                                entry.value.toString(),
                                Colors.blue,
                              );
                            }).toList(),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Grand Total:',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(color: Colors.blue, width: 2),
                                  ),
                                  child: Text(
                                    totalBobot.round().toString(),
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Timestamp info for the overall document
                  const SizedBox(height: 16),
                  if (data['timestamp'] != null)
                    Center(
                      child: Text(
                        'Data terakhir diperbarui: ${_formatTimestamp(data['timestamp'])}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScoreItem(String label, String score, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              score,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalScore(String score, [Color color = Colors.blue]) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Total Bobot',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: color),
          ),
          child: Text(
            score,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    DateTime date;

    if (timestamp is Timestamp) {
      // Handle Firebase Timestamp type
      date = timestamp.toDate();
    } else if (timestamp is int) {
      // Handle integer timestamp (milliseconds since epoch)
      date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else {
      // Return placeholder if timestamp is in an unexpected format
      return 'Waktu tidak tersedia';
    }

    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute < 10 ? '0${date.minute}' : date.minute}';
  }
}