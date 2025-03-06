import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:project_pkl/src/features/assessment_history/asn_assessment_history_page.dart';
import 'package:project_pkl/src/features/collection_manager_service/collection_manager.dart';
import 'package:project_pkl/src/features/detail_page/asn_detail_page.dart';
import 'package:project_pkl/src/features/voting_page/voting_asn/voting_asn.dart';

class AsnDataScreen extends StatefulWidget {
  const AsnDataScreen({super.key});

  @override
  State<AsnDataScreen> createState() => _AsnDataScreenState();
}

class _AsnDataScreenState extends State<AsnDataScreen> {
  int sortColumnIndex = 3; // Default sort by bobot column (index 4)
  bool sortAscending = false; // Default descending order
  final AsnCollectionManager _collectionManager = AsnCollectionManager();
  String currentCollection = 'penilaian_asn';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _currentUserEmail;
  String? _currentUserRole;
  
  @override
  void initState() {
    super.initState();
    _loadCurrentCollection();
    _getCurrentUserInfo();
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

  Future<void> _getCurrentUserInfo() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Dapatkan email user
      final String email = user.email ?? '';
      
      // Dapatkan role user dari Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _currentUserEmail = email;
          _currentUserRole = userData['role'] as String?;
        });
      }
    }
  }

  Future<void> _loadCurrentCollection() async {
    String collection = await _collectionManager.getCurrentCollectionName();
    setState(() {
      currentCollection = collection;
    });
  }

  Future<void> _handleReset() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Reset'),
          content: const Text(
            'Apakah Anda yakin ingin mereset penilaian? '
            'Data saat ini akan diarsipkan dan form penilaian baru akan dibuat.'
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Reset'),
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await _collectionManager.resetAndCreateNewCollection();
                  await _loadCurrentCollection();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Berhasil mereset penilaian'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal mereset penilaian: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  List<Map<String, dynamic>> _sortData(List<Map<String, dynamic>> data) {
    if (sortColumnIndex == 3) { // Bobot column
      data.sort((a, b) {
        final double valueA = double.tryParse(a['data']['bobot']?.toString() ?? '0') ?? 0;
        final double valueB = double.tryParse(b['data']['bobot']?.toString() ?? '0') ?? 0;
        return sortAscending ? valueA.compareTo(valueB) : valueB.compareTo(valueA);
      });
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hasil Penilaian - ${_formatCollectionName(currentCollection)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AsnAssessmentHistoryPage(),
                ),
              );
            },
            tooltip: 'Lihat Riwayat Penilaian',
          ),
          if (_currentUserRole == "admin") // Hanya admin yang bisa reset
            IconButton(
              onPressed: _handleReset, 
              icon: const Icon(Icons.restart_alt),
              tooltip: 'Reset Penilaian',
            ),
        ],
      ),
      floatingActionButton: _currentUserRole == "penilai" ? FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const VotingDataASN()));
        },
        child: const Icon(Icons.add),
      ) : null, // Hanya penilai yang bisa menambah penilaian
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: 300, // Atur ukuran sesuai kebutuhan
              child: TextField(
                controller: _searchController,
                autofocus: false,
                decoration: const InputDecoration(
                  labelText: 'Cari Nama Pegawai',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection(currentCollection).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("No Data Found"),
                  );
                }
            
                // Dapatkan semua dokumen penilaian
                List<Map<String, dynamic>> employees = [];
                
                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final id = doc.id;
                  
                  // Jika penilai, filter untuk hanya menampilkan data yang dinilai oleh penilai saat ini
                  if (_currentUserRole == "penilai") {
                    // Periksa apakah ada data hasil_penilaian
                    if (data.containsKey('hasil_penilaian')) {
                      final List<dynamic> hasilPenilaian = data['hasil_penilaian'] as List<dynamic>;
                      
                      // Cek apakah penilai ini ada dalam daftar
                      final bool penilaiBerpartisipasi = hasilPenilaian.any((penilaian) => 
                        penilaian['email_penilai'] == _currentUserEmail);
                      
                      // Hanya tampilkan data jika penilai ini berpartisipasi
                      if (penilaiBerpartisipasi) {
                        // Kalkulasi bobot sebagai penjumlahan rata-rata dari semua penilai
                        double totalBobot = 0;
                        
                        // Jika ada hasil penilaian, hitung rata-rata
                        if (hasilPenilaian.isNotEmpty) {
                          for (var penilaian in hasilPenilaian) {
                            // Asumsikan setiap penilaian memiliki field 'nilai'
                            if (penilaian.containsKey('nilai')) {
                              totalBobot += (penilaian['nilai'] as num).toDouble();
                            }
                          }
                        }
                        
                        // Perbarui data dengan bobot yang dihitung
                        final Map<String, dynamic> updatedData = Map<String, dynamic>.from(data);
                        updatedData['bobot'] = totalBobot.round();
                        
                        employees.add({
                          'id': id,
                          'data': updatedData,
                        });
                      }
                    }
                  } else {
                    // Untuk user biasa, tampilkan semua data dengan bobot yang dihitung
                    // Kalkulasi bobot sebagai penjumlahan rata-rata dari semua penilai
                    double totalBobot = 0;
                    
                    if (data.containsKey('hasil_penilaian')) {
                      final List<dynamic> hasilPenilaian = data['hasil_penilaian'] as List<dynamic>;
                      
                      // Jika ada hasil penilaian, hitung rata-rata
                      if (hasilPenilaian.isNotEmpty) {
                        for (var penilaian in hasilPenilaian) {
                          // Asumsikan setiap penilaian memiliki field 'nilai'
                          if (penilaian.containsKey('nilai')) {
                            totalBobot += (penilaian['nilai'] as num).toDouble();
                          }
                        }
                      }
                    }
                    
                    // Perbarui data dengan bobot yang dihitung
                    final Map<String, dynamic> updatedData = Map<String, dynamic>.from(data);
                    updatedData['bobot'] = totalBobot.round();
                    
                    employees.add({
                      'id': id,
                      'data': updatedData,
                    });
                  }
                }

                if (_searchQuery.isNotEmpty) {
                  employees = employees.where((employee) {
                    final String nama = employee['data']['nama']?.toString().toLowerCase() ?? '';
                    return nama.contains(_searchQuery);
                  }).toList();
                }
                
                // Sort the data without setState
                employees = _sortData(employees);
            
                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return DataTable(
                        columnSpacing: 20,
                        sortColumnIndex: sortColumnIndex,
                        sortAscending: sortAscending,
                        columns: [
                          const DataColumn(
                            label: Expanded(child: Text('No')),
                          ),
                          DataColumn(
                            label: SizedBox(
                              width: constraints.maxWidth * 0.3,
                              child: const Text('Nama Pegawai',)
                            ),
                          ),
                          DataColumn(
                            label: SizedBox(
                              width: constraints.maxWidth * 0.2,
                              child: const Text('Jabatan')),
                          ),
                          DataColumn(
                            label: SizedBox(
                              width: constraints.maxWidth * 0.5,
                              child: const Text('Bobot')),
                            numeric: true,
                            onSort: (columnIndex, ascending) {
                              setState(() {
                                sortColumnIndex = columnIndex;
                                sortAscending = ascending;
                              });
                            },
                          ),
                        ],
                        rows: employees.asMap().entries.map((entry) {
                          final index = entry.key + 1;
                          final employee = entry.value;
                          final employeeData = employee['data'] as Map<String, dynamic>;
                      
                          return DataRow(
                            cells: [
                              DataCell(Text('$index')),
                              DataCell(
                                SizedBox(
                                  child: Text(
                                    employeeData['nama'] ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AsnDetailPage(
                                        documentId: employee['id'],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              DataCell(
                                Container(
                                  width: constraints.maxWidth * 0.2,
                                  padding: const EdgeInsets.only(right: 10),
                                  child: Text(
                                    employeeData['jabatan'] ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AsnDetailPage(
                                        documentId: employee['id'],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              DataCell(
                                SizedBox(
                                  width: constraints.maxWidth * 0.5,
                                  child: Text('${employeeData['bobot']?.toString() ?? 0}')),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AsnDetailPage(
                                        documentId: employee['id'],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        }).toList(),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}