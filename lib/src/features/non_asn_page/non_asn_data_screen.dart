import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:project_pkl/src/features/voting_page/voting_non_asn/voting_non_asn.dart';

class NonAsnDataScreen extends StatefulWidget {
  const NonAsnDataScreen({super.key});

  @override
  State<NonAsnDataScreen> createState() => _NonAsnDataScreenState();
}

class _NonAsnDataScreenState extends State<NonAsnDataScreen> {
  int sortColumnIndex = 3; // Default sort by bobot column (index 4)
  bool sortAscending = false; // Default descending order

  List<Map<String, dynamic>> _sortData(List<Map<String, dynamic>> data) {
    if (sortColumnIndex == 3) { // Bobot column
      data.sort((a, b) {
        final num valueA = a['bobot'] ?? 0;
        final num valueB = b['bobot'] ?? 0;
        return sortAscending ? valueA.compareTo(valueB) : valueB.compareTo(valueA);
      });
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const VotingNonAsn()));
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("penilaian_non_asn").snapshots(),
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
            return doc.data() as Map<String, dynamic>;
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
                        child: Text('Nama Karyawan',)
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
                
                    return DataRow(
                      cells: [
                        DataCell(Text('$index')),
                        DataCell(
                          Text(
                            employee['nama'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DataCell(
                          Text(
                            employee['jabatan'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DataCell(Text('${employee['bobot'] ?? 0}')),
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
