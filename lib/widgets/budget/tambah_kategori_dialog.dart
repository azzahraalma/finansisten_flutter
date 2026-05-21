import 'package:flutter/material.dart';

class TambahKategoriDialog extends StatelessWidget {
  const TambahKategoriDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => const TambahKategoriDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = TextEditingController();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 201, 232, 255),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.category_outlined,
                  size: 34, color: Color(0xFF012249)),
            ),
            const SizedBox(height: 18),
            const Text('Tambah Kategori',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF012249))),
            const SizedBox(height: 4),
            const Text('untuk budget kamu',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 22),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 201, 232, 255),
                borderRadius: BorderRadius.circular(18),
              ),
              child: TextField(
                controller: ctrl,
                autofocus: true,
                textAlignVertical: TextAlignVertical.center,
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF012249)),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Contoh: Hiburan',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                  prefixIconConstraints:
                      BoxConstraints(minWidth: 42, minHeight: 42),
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.edit_outlined,
                        color: Color(0xFF012249), size: 20),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Batal',
                        style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.pop(context, ctrl.text.trim()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6DB5FD),
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Tambah',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}