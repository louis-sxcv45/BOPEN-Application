import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:project_pkl/src/features/detail_page/asn_detail_page.dart';
import 'package:project_pkl/src/features/voting_page/voting_asn/voting_asn.dart';

class AsnDataScreen extends StatefulWidget {
  const AsnDataScreen({super.key});

  @override
  State<AsnDataScreen> createState() => _AsnDataScreenState();
}

class _AsnDataScreenState extends State<AsnDataScreen> {
  int sortColumnIndex = 4; // Default sort by bobot column (index 4)
  bool sortAscending = false; // Default descending order

  List<Map<String, dynamic>> _sortData(List<Map<String, dynamic>> data) {
    if (sortColumnIndex == 4) { // Bobot column
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const VotingDataASN()));
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("penilaian_asn").snapshots(),
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
            scrollDirection: Axis.horizontal,
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
                        child: Text('Nama Karyawan')
                      ),
                    ),
                    const DataColumn(
                      label: Expanded(child: Text('NIP')),
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
                          SizedBox(
                            width: 200,
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
                          Text(
                            employeeData['nip'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
                            width: 200,
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
                          Text('${employeeData['bobot'] ?? 0}'),
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
    );
  }
}
