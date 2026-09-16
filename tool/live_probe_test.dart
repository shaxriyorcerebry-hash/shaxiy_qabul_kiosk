// Live check against the real backend — not part of `flutter test`'s default
// run (it lives outside test/). Run it by hand:
//
//   flutter test tool/live_probe_test.dart
//
// It asks the backend exactly as the kiosk does and prints what the
// governor's card would show, then repeats the request with the Windows
// certificate store switched off to prove the bundled root is enough
// (BUG-001).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:shaxiy_qabul_kiosk/src/config.dart';
import 'package:shaxiy_qabul_kiosk/src/kiosk_state.dart';
import 'package:shaxiy_qabul_kiosk/src/l10n.dart';
import 'package:shaxiy_qabul_kiosk/src/services/reception_api.dart';
import 'package:shaxiy_qabul_kiosk/src/services/tls.dart';

void main() {
  test('the kiosk reads the schedule and the governor date', () async {
    final dir = await Directory.systemTemp.createTemp('kiosk_live_probe');
    addTearDown(() => dir.delete(recursive: true));

    final state = KioskState(cache: ReceptionCache(dir: dir));
    await state.refresh();

    final hokim = state.officials.first;
    // ignore: avoid_print
    print('source: ${state.fromBackend ? 'backend' : 'built-in'}, '
        'officials: ${state.officials.length}\n'
        'governor: ${hokim.name[Lang.uz]}\n'
        '  uz: ${hokim.day[Lang.uz]}  ${hokim.time}\n'
        '  ru: ${hokim.day[Lang.ru]}\n'
        '  en: ${hokim.day[Lang.en]}\n'
        '  place: ${hokim.location}');

    expect(state.fromBackend, isTrue);
    expect(await ReceptionCache(dir: dir).readPoints(), isNotNull);
    state.dispose();
  });

  test('the bundled root alone reaches the backend', () async {
    final context = SecurityContext(withTrustedRoots: false)
      ..setTrustedCertificatesBytes(isrgRootX1Pem.codeUnits);
    final client = HttpClient(context: context);
    addTearDown(() => client.close(force: true));

    final req = await client.getUrl(
      Uri.parse('${KioskConfig.apiBase}${KioskConfig.receptionPointsPath}'),
    );
    final res = await req.close();
    await res.drain<void>();
    expect(res.statusCode, 200);
  });

  test('the kiosk context (Windows store + bundled root) works too', () async {
    final client = kioskHttpClient(const Duration(seconds: 20));
    addTearDown(() => client.close(force: true));

    final req = await client.getUrl(
      Uri.parse('${KioskConfig.apiBase}${KioskConfig.receptionPath}?lang=all'),
    );
    final res = await req.close();
    await res.drain<void>();
    expect(res.statusCode, 200);
  });
}
