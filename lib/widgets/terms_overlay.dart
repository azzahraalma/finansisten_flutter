import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsOverlay extends StatefulWidget {
  const TermsOverlay({super.key});

  @override
  State<TermsOverlay> createState() => _TermsOverlayState();
}

class _TermsOverlayState extends State<TermsOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    await _controller.reverse();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: GestureDetector(
        onTap: _close,
        child: Container(
          color: Colors.black45,
          alignment: Alignment.center,
          child: SlideTransition(
            position: _slide,
            child: GestureDetector(
              onTap: () {},
              child: Material( 
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Syarat & Ketentuan',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF012249),
                            ),
                          ),
                          GestureDetector(
                            onTap: _close,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFFE3F2FD),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 18,
                                color: Color(0xFF012249),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),
                      Divider(color: Colors.grey.shade200),
                      const SizedBox(height: 8),

                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight:
                              MediaQuery.of(context).size.height * 0.45,
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionTitle('1. Penerimaan Syarat'),
                              _SectionBody(
                                'Dengan menggunakan aplikasi Finansisten, kamu menyetujui syarat dan ketentuan ini. Jika tidak setuju, mohon untuk tidak menggunakan layanan kami.',
                              ),
                              _SectionTitle('2. Penggunaan Akun'),
                              _SectionBody(
                                'Kamu bertanggung jawab penuh atas keamanan akun dan kata sandi yang kamu buat. Segala aktivitas yang terjadi di bawah akunmu adalah tanggung jawabmu sendiri.',
                              ),
                              _SectionTitle('3. Keamanan Data'),
                              _SectionBody(
                                'Kami berkomitmen menjaga kerahasiaan data pribadimu. Data yang kamu masukkan disimpan secara lokal di perangkatmu dan tidak dikirim ke server manapun.',
                              ),
                              _SectionTitle('4. Kebijakan Privasi'),
                              _SectionBody(
                                'Finansisten tidak akan menjual, menyewakan, atau membagikan informasi pribadimu kepada pihak ketiga tanpa izin eksplisit darimu.',
                              ),
                              _SectionTitle('5. Batasan Tanggung Jawab'),
                              _SectionBody(
                                'Finansisten tidak bertanggung jawab atas keputusan keuangan yang kamu ambil berdasarkan data yang tersimpan di aplikasi ini. Gunakan informasi dengan bijak.',
                              ),
                              _SectionTitle('6. Perubahan Syarat'),
                              _SectionBody(
                                'Kami berhak mengubah syarat dan ketentuan ini sewaktu-waktu. Perubahan akan diberitahukan melalui notifikasi di dalam aplikasi.',
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _close,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6DB5FD),
                            shape: const StadiumBorder(),
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'Mengerti',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF012249),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF012249),
        ),
      ),
    );
  }
}

class _SectionBody extends StatelessWidget {
  final String text;
  const _SectionBody(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 13,
        color: Colors.grey.shade700,
        height: 1.5,
      ),
    );
  }
}

void showTermsOverlay(BuildContext context) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: true,
      pageBuilder: (_, __, ___) => const TermsOverlay(),
    ),
  );
}