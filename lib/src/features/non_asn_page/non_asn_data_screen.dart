import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:project_pkl/src/features/assessment_history/non_asn_assessment_history_page.dart';
import 'package:project_pkl/src/features/collection_manager_service/collection_manager.dart';
import 'package:project_pkl/src/features/detail_page/non_asn_detail_page.dart';
import 'package:project_pkl/src/features/voting_page/voting_non_asn/voting_non_asn.dart';

class NonAsnDataScreen extends StatefulWidget {
  const NonAsnDataScreen({super.key});

  @override
  State<NonAsnDataScreen> createState() => _NonAsnDataScreenState();
}

class _NonAsnDataScreenState extends State<NonAsnDataScreen> {
  int sortColumnIndex = 3; // Default sort by bobot column
  bool sortAscending = false; // Default descending order
  final NonAsnCollectionManager _collectionManager = NonAsnCollectionManager();
  String currentCollection = 'penilaian_non_asn';
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
    if (collectionName == 'penilaian_non_asn') {
      return 'Triwulan 1'; // Default collection (without number)
    }
    // Extract number from collection name (e.g., penilaian_non_asn_2 -> 2)
    final parts = collectionName.split('_');
    if (parts.length > 2) {
      final number = parts.last;
      return 'Triwulan $number';
    }
    return 'Triwulan 1'; // Fallback if format is not as expected
  }

  Future<void> _getCurrentUserInfo() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Get user email
      final String email = user.email ?? '';
      
      // Get user role from Firestore
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
                  builder: (context) => const NonAsnAssessmentHistoryPage(),
                ),
              );
            },
            tooltip: 'Lihat Riwayat Penilaian',
          ),
          if (_currentUserRole == "admin") // Only admin can reset
            IconButton(
              onPressed: _handleReset, 
              icon: const Icon(Icons.restart_alt),
              tooltip: 'Reset Penilaian',
            ),
        ],
      ),
      floatingActionButton: _currentUserRole == "penilai" ? FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const VotingNonAsn()));
        },
        child: const Icon(Icons.add),
      ) : null, // Only assessors can add assessments
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: 300,
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
            
                // Get all assessment documents
                List<Map<String, dynamic>> employees = [];
                
                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final id = doc.id;
                  
                  // If assessor, filter to show only data assessed by current assessor
                  if (_currentUserRole == "penilai") {
                    // Check if there are assessment results
                    if (data.containsKey('hasil_penilaian')) {
                      final List<dynamic> hasilPenilaian = data['hasil_penilaian'] as List<dynamic>;
                      
                      // Check if this assessor participated
                      final bool penilaiBerpartisipasi = hasilPenilaian.any((penilaian) => 
                        penilaian['email_penilai'] == _currentUserEmail);
                      
                      // Only show data if this assessor participated
                      if (penilaiBerpartisipasi) {
                        // Calculate weight as average of all assessors
                        double totalBobot = 0;
                        
                        // If assessment results exist, calculate average
                        if (hasilPenilaian.isNotEmpty) {
                          for (var penilaian in hasilPenilaian) {
                            // Assume each assessment has a 'nilai' field
                            if (penilaian.containsKey('nilai')) {
                              totalBobot += (penilaian['nilai'] as num).toDouble();
                            }
                          }
                        }
                        
                        // Update data with calculated weight
                        final Map<String, dynamic> updatedData = Map<String, dynamic>.from(data);
                        updatedData['bobot'] = totalBobot.round();
                        
                        employees.add({
                          'id': id,
                          'data': updatedData,
                        });
                      }
                    }
                  } else {
                    // For regular users, show all data with calculated weight
                    double totalBobot = 0;
                    
                    if (data.containsKey('hasil_penilaian')) {
                      final List<dynamic> hasilPenilaian = data['hasil_penilaian'] as List<dynamic>;
                      
                      // If assessment results exist, calculate average
                      if (hasilPenilaian.isNotEmpty) {
                        for (var penilaian in hasilPenilaian) {
                          // Assume each assessment has a 'nilai' field
                          if (penilaian.containsKey('nilai')) {
                            totalBobot += (penilaian['nilai'] as num).toDouble();
                          }
                        }
                      }
                    }
                    
                    // Update data with calculated weight
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
                                      builder: (context) => NonAsnDetailPage(
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
                                      builder: (context) => NonAsnDetailPage(
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
                                      builder: (context) => NonAsnDetailPage(
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