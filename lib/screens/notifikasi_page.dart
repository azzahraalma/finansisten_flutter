import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';

class NotifikasiPage extends StatefulWidget {
  const NotifikasiPage({super.key});

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  final db = DatabaseHelper.instance;

  bool isLoading = true;

  List<Map<String, dynamic>> notifikasiList = [];

  @override
  void initState() {
    super.initState();
    _loadNotif();
  }

  Future<void> _loadNotif() async {
    final data = await db.getNotifications();

    setState(() {
      notifikasiList = data;
      isLoading = false;
    });
  }

  Future<void> _clearNotif() async {
    await db.clearNotifications();

    setState(() {
      notifikasiList.clear();
    });
  }

  // =========================
  // GROUP NOTIFICATION
  // =========================

  Map<String, List<Map<String, dynamic>>> _grouped() {
    final sekarang = DateTime.now();

    final hariIni =
        DateTime(sekarang.year, sekarang.month, sekarang.day);

    final kemarin =
        hariIni.subtract(const Duration(days: 1));

    final awalMinggu =
        hariIni.subtract(Duration(days: hariIni.weekday - 1));

    final Map<String, List<Map<String, dynamic>>> groups = {
      'Hari Ini': [],
      'Kemarin': [],
      'Minggu Ini': [],
      'Lebih Lama': [],
    };

    for (final notif in notifikasiList) {
      final date = DateTime.parse(notif['waktu']);

      final day =
          DateTime(date.year, date.month, date.day);

      if (day == hariIni) {
        groups['Hari Ini']!.add(notif);
      } else if (day == kemarin) {
        groups['Kemarin']!.add(notif);
      } else if (!day.isBefore(awalMinggu)) {
        groups['Minggu Ini']!.add(notif);
      } else {
        groups['Lebih Lama']!.add(notif);
      }
    }

    groups.removeWhere((key, value) => value.isEmpty);

    return groups;
  }

  // =========================
  // FORMAT TIME
  // =========================

  String _formatTimestamp(String isoString) {
    final date = DateTime.parse(isoString);

    return DateFormat(
      'HH:mm - d MMM',
      'id_ID',
    ).format(date);
  }

  // =========================
  // ICON
  // =========================

  IconData _iconFor(String? tipe) {
    switch (tipe) {
      case 'pengeluaran':
        return Icons.south_west;

      case 'pemasukan':
        return Icons.north_east;

      case 'tabungan':
        return Icons.savings_outlined;

      case 'hapus':
        return Icons.delete_outline;

      case 'warning_budget':
        return Icons.warning_amber_rounded;

      default:
        return Icons.notifications_outlined;
    }
  }

  Color _iconColor(String? tipe) {
    switch (tipe) {
      case 'warning_budget':
        return Colors.orange;

      case 'hapus':
        return Colors.red;

      default:
        return const Color(0xFF4A90D9);
    }
  }

  // =========================
  // UI
  // =========================

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped();

    return Scaffold(
      backgroundColor: const Color(0xFF6DB5FD),

      body: SafeArea(
        bottom: false,

        child: Column(
          children: [
            // ================= HEADER =================

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),

              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,

                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),

                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),

                  const Text(
                    "Notifikasi",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF012249),
                    ),
                  ),

                  PopupMenuButton(
                    icon: const Icon(
                      Icons.more_vert,
                      color: Colors.white,
                    ),

                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'clear',
                        child: Text('Hapus Semua'),
                      ),
                    ],

                    onSelected: (v) async {
                      if (v == 'clear') {
                        await _clearNotif();
                      }
                    },
                  ),
                ],
              ),
            ),

            // ================= BODY =================

            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 20),

                width: double.infinity,

                decoration: const BoxDecoration(
                  color: Colors.white,

                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(50),
                  ),
                ),

                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : notifikasiList.isEmpty
                        ? _buildEmpty()
                        : ListView(
                            padding:
                                const EdgeInsets.fromLTRB(
                              20,
                              20,
                              20,
                              40,
                            ),

                            children: grouped.entries.map((entry) {
                              return Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,

                                children: [
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(
                                      bottom: 6,
                                      top: 8,
                                    ),

                                    child: Text(
                                      entry.key,

                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight:
                                            FontWeight.w600,
                                        color:
                                            Color(0xFF8BAFC9),
                                      ),
                                    ),
                                  ),

                                  ...entry.value
                                      .map(
                                        (notif) =>
                                            _notifTile(notif),
                                      )
                                      .toList(),
                                ],
                              );
                            }).toList(),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // NOTIF TILE
  // =========================

  Widget _notifTile(Map<String, dynamic> notif) {
    final tipe = notif['tipe'];

    final judul =
        notif['judul'] ?? 'Notifikasi';

    final pesan =
        notif['pesan'] ?? '';

    final detail =
        notif['detail'] ?? '';

    final timestamp =
        _formatTimestamp(notif['waktu']);

    return Column(
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(vertical: 12),

          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              // ICON

              Container(
                width: 44,
                height: 44,

                decoration: BoxDecoration(
                  color:
                      _iconColor(tipe).withOpacity(0.15),

                  shape: BoxShape.circle,
                ),

                child: Icon(
                  _iconFor(tipe),

                  color: _iconColor(tipe),
                ),
              ),

              const SizedBox(width: 12),

              // TEXT

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      judul,

                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF012249),
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      pesan,

                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                      ),
                    ),

                    if (detail.isNotEmpty) ...[
                      const SizedBox(height: 2),

                      Text(
                        detail,

                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFF012249),
                        ),
                      ),
                    ],

                    const SizedBox(height: 6),

                    Align(
                      alignment: Alignment.centerRight,

                      child: Text(
                        timestamp,

                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6DB5FD),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Divider(color: Colors.grey.shade200),
      ],
    );
  }

  // =========================
  // EMPTY
  // =========================

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [
          Container(
            width: 80,
            height: 80,

            decoration: const BoxDecoration(
              color: Color(0xFFE3F2FD),
              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.notifications_off_outlined,
              color: Color(0xFF6DB5FD),
              size: 36,
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            "Belum ada notifikasi",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF012249),
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            "Notifikasi akan muncul di sini",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}