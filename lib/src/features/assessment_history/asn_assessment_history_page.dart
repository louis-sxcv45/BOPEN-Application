import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_pkl/src/features/collection_manager_service/collection_manager.dart';
import 'package:project_pkl/src/features/detail_page/asn_detail_page.dart';

class AsnAssessmentHistoryPage extends StatefulWidget {
  const AsnAssessmentHistoryPage({super.key});

  @override
  State<AsnAssessmentHistoryPage> createState() => _AsnAssessmentHistoryPageState();
}

class _AsnAssessmentHistoryPageState extends State<AsnAssessmentHistoryPage> {
  final AsnCollectionManager _collectionManager = AsnCollectionManager();
  List<String> availableCollections = [];
  Map<String, bool> expandedStates = {};
  int sortColumnIndex = 3;
  bool sortAscending = false;

  @override
  void initState() {
    super.initState();
    _collectionManager.setupCollectionChangeListener();
    _loadCollections();
  }

  Future<void> _loadCollections() async {
    final collections = await _collectionManager.getAvailableCollections();
    setState(() {
      availableCollections = collections.reversed.toList(); // Newest first
      expandedStates = {for (var collection in collections) collection: false};
    });
  }

  Future<void> _deleteCollection(String collectionName) async {
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text(
            'Anda yakin ingin menghapus ${_formatCollectionName(collectionName)}? '
            'Tindakan ini tidak dapat dibatalkan.',
          ),
          actions: [
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Hapus'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirm) {
      try {
        // Mark the collection as deleted first
        await FirebaseFirestore.instance
            .collection('collection_metadata')
            .doc('deleted_collections')
            .set({
          collectionName: true
        }, SetOptions(merge: true));

        // Find the highest available version AFTER marking as deleted
        final int highestVersion = await _collectionManager.findHighestAvailableVersion();
        print('Highest available version found: $highestVersion'); // Debug log

        // Update the current version in Firebase
        await _collectionManager.updateCurrentVersion(highestVersion);

        // Now delete the documents in the collection
        final QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection(collectionName)
            .get();

        final batch = FirebaseFirestore.instance.batch();
        for (var doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();

        // Double-check version was updated correctly
        final currentVersion = await _collectionManager.getCurrentVersion();
        print('Current version after update: $currentVersion'); // Debug log

        // Update UI
        setState(() {
          availableCollections.remove(collectionName);
          expandedStates.remove(collectionName);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Collection berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Reload collections
        await _loadCollections();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus collection: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _formatCollectionName(String name) {
    if (name == 'penilaian_asn') {
      return 'Periode Penilaian 1';
    }
    final periodNumber = name.split('_').last;
    return 'Periode Penilaian $periodNumber';
  }

  List<Map<String, dynamic>> _sortData(List<Map<String, dynamic>> data) {
    if (sortColumnIndex == 3) {
      data.sort((a, b) {
        final double valueA = double.tryParse(a['data']['bobot']?.toString() ?? '0') ?? 0;
        final double valueB = double.tryParse(b['data']['bobot']?.toString() ?? '0') ?? 0;
        return sortAscending ? valueA.compareTo(valueB) : valueB.compareTo(valueA);
      });
    }
    return data;
  }

  Widget _buildAssessmentTable(String collectionName) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collectionName)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Text("Tidak ada data untuk periode ini"),
            ),
          );
        }

        List<Map<String, dynamic>> employees = snapshot.data!.docs.map((doc) {
          return {
            'id': doc.id,
            'data': doc.data() as Map<String, dynamic>
          };
        }).toList();

        employees = _sortData(employees);

        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: LayoutBuilder(
            builder: (context, constraints){
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
                                collectionName: collectionName,
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
                                collectionName: collectionName,
                              ),
                            ),
                          );
                        },
                      ),
                      DataCell(
                        SizedBox(
                          width: constraints.maxWidth * 0.5,
                          child: Text('${employeeData['bobot'] ?? 0}')),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AsnDetailPage(
                                documentId: employee['id'],
                                collectionName: collectionName,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Penilaian ASN'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: availableCollections.length,
        itemBuilder: (context, index) {
          final collection = availableCollections[index];
          final isExpanded = expandedStates[collection] ?? false;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                ListTile(
                  title: Text(
                    _formatCollectionName(collection),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Hanya tampilkan tombol hapus jika bukan collection aktif
                      //if (index != 0) // Assuming newest collection is at index 0
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _deleteCollection(collection),
                          tooltip: 'Hapus Periode Penilaian',
                        ),
                      IconButton(
                        icon: Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                        ),
                        onPressed: () {
                          setState(() {
                            expandedStates[collection] = !isExpanded;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                if (isExpanded)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildAssessmentTable(collection),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}