import 'package:flutter/material.dart';

class TambahTransaksiCard extends StatelessWidget {
  final TextEditingController amountController;
  final String selectedJenis;
  final String? selectedKategori;
  final List<Map<String, dynamic>> kategoriItems;
  final ValueChanged<String> onJenisChanged;
  final ValueChanged<String?> onKategoriChanged;
  final VoidCallback onTambah;
  final VoidCallback onTambahKategori;

  const TambahTransaksiCard({
    super.key,
    required this.amountController,
    required this.selectedJenis,
    required this.selectedKategori,
    required this.kategoriItems,
    required this.onJenisChanged,
    required this.onKategoriChanged,
    required this.onTambah,
    required this.onTambahKategori,
  });

  @override
  Widget build(BuildContext context) {
    final validSelectedKategori = kategoriItems.any(
          (k) => k['nama'].toString() == selectedKategori,
        )
        ? selectedKategori
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tambah Transaksi',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF012249),
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: _inputBox(
                    child: Row(
                      children: [
                        const Text(
                          'Rp ',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF012249),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: amountController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF012249),
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Jumlah',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: _inputBox(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedJenis,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF012249),
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Color(0xFF012249),
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF012249),
                          fontWeight: FontWeight.w600,
                        ),
                        items: ['pemasukan', 'pengeluaran'].map((e) {
                          return DropdownMenuItem<String>(
                            value: e,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              e == 'pemasukan' ? 'Pemasukan' : 'Pengeluaran',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) onJenisChanged(v);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Center(
              child: SizedBox(
                width: 200,
                child: _inputBox(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: validSelectedKategori,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF012249),
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Color(0xFF012249),
                      ),
                      hint: const Text(
                        'Pilih Kategori',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF012249),
                        ),
                      ),
                      alignment: Alignment.centerLeft,
                      items: [
                        ...kategoriItems.map(
                          (k) => DropdownMenuItem<String>(
                            value: k['nama'],
                            alignment: Alignment.centerLeft,
                            child: Text(
                              k['nama'],
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const DropdownMenuItem<String>(
                          value: '__tambah__',
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              Icon(
                                Icons.add,
                                size: 18,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Tambah Kategori',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == '__tambah__') {
                          onTambahKategori();
                        } else {
                          onKategoriChanged(value);
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            Center(
              child: ElevatedButton.icon(
                onPressed: onTambah,
                icon: const Icon(Icons.add, size: 16),
                label: const Text(
                  'Tambah',
                  style: TextStyle(fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 201, 232, 255),
                  foregroundColor: const Color(0xFF012249),
                  elevation: 0,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputBox({required Widget child}) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 201, 232, 255),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}