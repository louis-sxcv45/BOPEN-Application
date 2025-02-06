import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:project_pkl/src/features/collection_manager_service/collection_manager.dart';
import 'package:project_pkl/src/features/detail_page/non_asn_detail_page.dart';
import 'package:project_pkl/src/features/voting_page/voting_non_asn/voting_non_asn.dart';

class NonAsnDataScreen extends StatefulWidget {
  const NonAsnDataScreen({super.key});

  @override
  State<NonAsnDataScreen> createState() => _NonAsnDataScreenState();
}

class _NonAsnDataScreenState extends State<NonAsnDataScreen> {
  int sortColumnIndex = 3; // Default sort by bobot column (index 4)
  bool sortAscending = false; // Default descending order
  final NonAsnCollectionManager _collectionManager = NonAsnCollectionManager();
  String currentCollection = 'penilaian_non_asn';

  @override
  void initState() {
    super.initState();
    _loadCurrentCollection();
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
        final num valueA = a['data']['bobot'] ?? 0;
        final num valueB = b['data']['bobot'] ?? 0;
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
          'Data Non ASN - $currentCollection',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _handleReset, 
            icon: const Icon(Icons.restart_alt),
            tooltip: 'Reset Penilaian',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const VotingNonAsn()));
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
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

          List<Map<String, dynamic>> employees = snapshot.data!.docs.map((doc) {
            return{ 
              'id':doc.id,
              'data':doc.data() as Map<String, dynamic>
            };
          }).toList();

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
                    const DataColumn(
                      label: Expanded(
                        child: Text(
                          'Nama Pegawai',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )
                      ),
                    ),
                    const DataColumn(
                      label: Expanded(child: Text('Jabatan')),
                    ),
                    DataColumn(
                      label: const Expanded(child: Text('Bobot')),
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
                          Text(
                            employeeData['nama'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
                          Text(
                            employeeData['jabatan'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
                          Text('${employeeData['bobot'] ?? 0}'),
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
    );
  }
}
