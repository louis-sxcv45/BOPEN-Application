import 'package:flutter/material.dart';

class AsnDataScreen extends StatefulWidget {
  const AsnDataScreen({super.key});

  @override
  State<AsnDataScreen> createState() => _AsnDataScreenState();
}

class _AsnDataScreenState extends State<AsnDataScreen> {
  bool sortAscending = false;
  int sortColumnIndex = 4;

  void sort(int columnIndex, bool ascending){
    setState((){
      sortColumnIndex = columnIndex;
      sortAscending = ascending;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
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
                    onSort: (index, ascending) => sort(index, ascending),
                  ),
                  DataColumn(
                    label: Text('Nama Karyawan'),
                    onSort: (index, ascending) => sort(index, ascending),
                  ),
                  DataColumn(
                    label: Text('NIP'),
                    onSort: (index, ascending) => sort(index, ascending),
                  ),
                  DataColumn(
                    label: Text('Jabatan'),
                    onSort: (index, ascending) => sort(index, ascending),
                  ),
                  DataColumn(
                    label: Text('Bobot'),
                    numeric: true,
                    onSort: (index, ascending) => sort(index, ascending),
                  ),
                ],
                rows: [
                  DataRow(
                    cells: [
                      DataCell(Text('1')),
                      DataCell(Text('John Doe')),
                      DataCell(Text('123456')),
                      DataCell(Text('Manager')),
                      DataCell(Text('80')),
                    ],
                  ),
                  DataRow(
                    cells: [
                      DataCell(Text('2')),
                      DataCell(Text('Jane Smith')),
                      DataCell(Text('654321')),
                      DataCell(Text('Developer')),
                      DataCell(Text('100')),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
