import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const int _idReminderHarian = 1001;
  static const int _idLaporanBulanan = 1002;

  static Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await jadwalkanReminderHarian();
    await jadwalkanLaporanBulanan();
  }

  static AndroidNotificationDetails _androidDetail({
    required String channelId,
    required String channelName,
    required String channelDesc,
    Importance importance = Importance.high,
    Priority priority = Priority.high,
  }) {
    return AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: importance,
      priority: priority,
      showWhen: true,
    );
  }

  static const DarwinNotificationDetails _iosDetail = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  static Future<void> show({
    required int id,
    required String title,
    required String body,
    String? detail,
  }) async {
    final androidDetail = _androidDetail(
      channelId: 'finansisten_umum',
      channelName: 'Notifikasi Umum',
      channelDesc: 'Notifikasi transaksi dan budget',
    );

    await _plugin.show(
      id,
      title,
      detail != null && detail.isNotEmpty ? '$body\n$detail' : body,
      NotificationDetails(android: androidDetail, iOS: _iosDetail),
    );
  }

  static Future<void> showWarningBudget({
    required String namaKategori,
    required int persen,
    required String sisaBudget,
    required String totalBudget,
  }) async {
    final bool melebihi = persen >= 100;

    final String judul = melebihi
        ? '🚨 Budget $namaKategori Habis!'
        : '⚠️ Peringatan Budget!';

    final String pesan = melebihi
        ? 'Budget $namaKategori sudah melebihi batas! Total $totalBudget'
        : 'Budget $namaKategori sudah mencapai $persen%. Sisa $sisaBudget dari $totalBudget';

    final androidDetail = _androidDetail(
      channelId: 'finansisten_budget',
      channelName: 'Peringatan Budget',
      channelDesc: 'Notifikasi saat budget hampir habis atau melebihi batas',
      importance: Importance.max,
      priority: Priority.max,
    );

    await _plugin.show(
      namaKategori.hashCode,
      judul,
      pesan,
      NotificationDetails(android: androidDetail, iOS: _iosDetail),
    );
  }

  static Future<void> showTransaksiDitambahkan({
    required String jenis,
    required String namaKategori,
    required String nominal,
  }) async {
    final bool isPemasukan = jenis == 'pemasukan';

    final String judul = isPemasukan
        ? 'Pemasukan Dicatat ✅'
        : 'Pengeluaran Dicatat';

    final String pesan = isPemasukan
        ? '$namaKategori berhasil dicatat. +$nominal'
        : '$namaKategori berhasil dicatat. -$nominal';

    final androidDetail = _androidDetail(
      channelId: 'finansisten_transaksi',
      channelName: 'Transaksi',
      channelDesc: 'Notifikasi setiap transaksi ditambahkan',
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      judul,
      pesan,
      NotificationDetails(android: androidDetail, iOS: _iosDetail),
    );
  }

  static Future<void> showBudgetDitambahkan({
    required String namaKategori,
    required String nominal,
  }) async {
    final androidDetail = _androidDetail(
      channelId: 'finansisten_budget_baru',
      channelName: 'Budget Baru',
      channelDesc: 'Notifikasi saat budget baru dibuat',
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Budget Baru Ditambahkan 💰',
      'Budget "$namaKategori" $nominal berhasil dibuat untuk bulan ini',
      NotificationDetails(android: androidDetail, iOS: _iosDetail),
    );
  }

  static Future<void> jadwalkanReminderHarian() async {
    await _plugin.cancel(_idReminderHarian);

    final androidDetail = _androidDetail(
      channelId: 'finansisten_reminder',
      channelName: 'Pengingat Harian',
      channelDesc: 'Pengingat setiap hari jika belum mencatat transaksi',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      20,
      0,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _idReminderHarian,
      'Jangan Lupa Catat! 📝',
      'Kamu belum mencatat transaksi hari ini. Yuk catat sekarang sebelum lupa!',
      scheduled,
      NotificationDetails(android: androidDetail, iOS: _iosDetail),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> batalkanReminderHariIni() async {
    await _plugin.cancel(_idReminderHarian);
    await jadwalkanReminderHarian();
  }

  static Future<void> jadwalkanLaporanBulanan() async {
    await _plugin.cancel(_idLaporanBulanan);

    final androidDetail = _androidDetail(
      channelId: 'finansisten_laporan',
      channelName: 'Laporan Bulanan',
      channelDesc: 'Pengingat melihat laporan keuangan setiap tanggal 28',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      28,
      9,
      0,
    );
    if (scheduled.isBefore(now)) {
      scheduled = tz.TZDateTime(
        tz.local,
        now.month == 12 ? now.year + 1 : now.year,
        now.month == 12 ? 1 : now.month + 1,
        28,
        9,
        0,
      );
    }

    await _plugin.zonedSchedule(
      _idLaporanBulanan,
      '📊 Laporan Keuangan Bulan Ini Siap!',
      'Yuk lihat ringkasan pengeluaran & pemasukan bulan ini sebelum bulan berganti!',
      scheduled,
      NotificationDetails(android: androidDetail, iOS: _iosDetail),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }
}