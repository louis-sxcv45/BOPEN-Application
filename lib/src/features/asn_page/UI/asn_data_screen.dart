import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:project_pkl/src/features/voting_page/voting_asn/voting_asn.dart';

class AsnDataScreen extends StatefulWidget {
  const AsnDataScreen({super.key});

  @override
  State<AsnDataScreen> createState() => _AsnDataScreenState();
}

void readDataASN() async {
  CollectionReference penilaianASN = FirebaseFirestore.instance.collection("penilaian_asn");

  QuerySnapshot querySnapshot = await penilaianASN.snapshots().first;
  querySnapshot.docs.forEach((element) {
    debugPrint(element['nama']);
  });
}

class _AsnDataScreenState extends State<AsnDataScreen> {
  int? sortColumnIndex;
  bool sortAscending = false; // Set default sorting to descending

  void sort<T>(Comparable<T> Function(Map<String, dynamic>) getField, bool ascending, List<Map<String, dynamic>> data) {
    setState(() {
      data.sort((a, b) {
        final fieldA = getField(a);
        final fieldB = getField(b);
        return ascending ? Comparable.compare(fieldA, fieldB) : Comparable.compare(fieldB, fieldA);
      });
    });
  }

  @override
  void initState() {
    super.initState();
    readDataASN();
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

          // Ambil data dari Firestore dan konversi ke daftar map
          final employees = snapshot.data!.docs.map((doc) {
            return doc.data() as Map<String, dynamic>;
          }).toList();

          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topLeft,
                  child: DataTable(
                    sortColumnIndex: sortColumnIndex,
                    sortAscending: sortAscending,
                    columns: [
                      DataColumn(
                        label: Text('No'),
                      ),
                      DataColumn(
                        label: Text('Nama Karyawan'),
                        onSort: (index, ascending) {
                          setState(() {
                            sortColumnIndex = index;
                            sortAscending = ascending;
                          });
                          sort<String>(
                            (employee) => employee['nama'] ?? '',
                            ascending,
                            employees,
                          );
                        },
                      ),
                      DataColumn(
                        label: Text('NIP'),
                        onSort: (index, ascending) {
                          setState(() {
                            sortColumnIndex = index;
                            sortAscending = ascending;
                          });
                          sort<String>(
                            (employee) => employee['nip'] ?? '',
                            ascending,
                            employees,
                          );
                        },
                      ),
                      DataColumn(
                        label: Text('Jabatan'),
                        onSort: (index, ascending) {
                          setState(() {
                            sortColumnIndex = index;
                            sortAscending = ascending;
                          });
                          sort<String>(
                            (employee) => employee['jabatan'] ?? '',
                            ascending,
                            employees,
                          );
                        },
                      ),
                      DataColumn(
                        label: Text('Bobot'),
                        numeric: true,
                        onSort: (index, ascending) {
                          setState(() {
                            sortColumnIndex = index;
                            sortAscending = ascending;
                          });
                          sort<num>(
                            (employee) => employee['bobot'] ?? 0,
                            ascending,
                            employees,
                          );
                        },
                      ),
                    ],
                    rows: employees.asMap().entries.map((entry) {
                      final index = entry.key + 1; // Gunakan index sebagai nomor
                      final employee = entry.value;

                      return DataRow(
                        cells: [
                          DataCell(Text('$index')), // Nomor otomatis
                          DataCell(Text(employee['nama'] ?? '')),
                          DataCell(Text(employee['nip'] ?? '')),
                          DataCell(Text(employee['jabatan'] ?? '')),
                          DataCell(Text('${employee['bobot'] ?? 0}')),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
