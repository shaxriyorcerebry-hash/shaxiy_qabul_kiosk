// The kiosk draws the reception schedule the backend serves, and falls back to
// its built-in list whenever the backend has nothing to say.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shaxiy_qabul_kiosk/src/data.dart';
import 'package:shaxiy_qabul_kiosk/src/kiosk_root.dart';
import 'package:shaxiy_qabul_kiosk/src/kiosk_state.dart';
import 'package:shaxiy_qabul_kiosk/src/l10n.dart';
import 'package:shaxiy_qabul_kiosk/src/screens/shaxsiy_screen.dart';
import 'package:shaxiy_qabul_kiosk/src/services/hokim_reception.dart';
import 'package:shaxiy_qabul_kiosk/src/services/reception_api.dart';
import 'package:shaxiy_qabul_kiosk/src/services/tls.dart';

/// A payload in the shape the backend actually serves.
Map<String, dynamic> _payload() => {
  'intro': {'uz': 'Server intro', 'ru': 'Серверный интро', 'en': 'Server intro'},
  'note': {'uz': 'Server izohi', 'ru': '', 'en': ''},
  'officials': [
    {
      'id': 2,
      'sort_order': 2,
      'full_name': {'uz': 'Ikkinchi Mansabdor', 'ru': 'Второй', 'en': 'Second'},
      'position': {'uz': "O'rinbosar", 'ru': 'Заместитель', 'en': 'Deputy'},
      'reception_day': {'uz': 'Har haftaning juma kuni', 'ru': '', 'en': ''},
      'day_of_week': 5,
      'time': '15:00 – 17:00',
      'phone': '71-232-80-44',
      'is_active': true,
    },
    {
      'id': 1,
      'sort_order': 1,
      'full_name': {'uz': 'Birinchi Mansabdor', 'ru': 'Первый', 'en': 'First'},
      'position': {'uz': 'Hokim', 'ru': 'Хоким', 'en': 'Governor'},
      'reception_day': {'uz': 'Har haftaning chorshanba kuni', 'ru': '', 'en': ''},
      'day_of_week': 3,
      'time': '10:00 – 14:00',
      'phone': '71-232-80-73',
      'is_active': true,
    },
    {
      'id': 3,
      'sort_order': 3,
      'full_name': {'uz': 'Nofaol Mansabdor', 'ru': '', 'en': ''},
      'position': {'uz': '...', 'ru': '', 'en': ''},
      'reception_day': {'uz': '...', 'ru': '', 'en': ''},
      'time': '',
      'phone': '',
      'is_active': false,
    },
  ],
};

/// `GET /kiosk/reception-points` as the backend served it on 2026-09-16.
List<dynamic> _points({Object? at = '2026-09-24T05:00:00Z'}) => [
  {
    'id': 1,
    'name_uz': 'Prezident Xalq qabulxonasi',
    'name_ru': 'Народная приёмная Президента',
    'room_number': '101',
    'ticket_prefix': 'P',
    'sort_order': 1,
    'next_reception_at': '2026-09-20T05:00:00Z',
    'reception_location': null,
  },
  {
    'id': 2,
    'name_uz': 'Hokim qabuli',
    'name_ru': 'Приём хокима',
    'room_number': '102',
    'ticket_prefix': 'H',
    'sort_order': 2,
    'next_reception_at': at,
    'reception_location': 'Toshkent viloyati Xalq qabulxonasi',
  },
];

/// 2026-09-16 15:00 in Tashkent.
DateTime _wed() => DateTime.utc(2026, 9, 16, 10);

/// A backend that answers from memory and counts the calls.
class _FakeScheduleApi extends ReceptionApi {
  _FakeScheduleApi(this.answer) : super(apiBase: 'http://fake');
  final Future<ReceptionResult> Function() answer;
  int calls = 0;

  @override
  Future<ReceptionResult> fetch({String? etag}) {
    calls++;
    return answer();
  }
}

class _FakePointsApi extends ReceptionPointsApi {
  _FakePointsApi(this.answer) : super(apiBase: 'http://fake');
  final Future<List<dynamic>> Function() answer;
  int calls = 0;

  @override
  Future<List<dynamic>> fetch() {
    calls++;
    return answer();
  }
}

/// A cache with nothing in it that never touches the disk.
class _NoCache extends ReceptionCache {
  @override
  Future<({ReceptionSchedule? schedule, String? etag})> read() async =>
      (schedule: null, etag: null);
  @override
  Future<List<dynamic>?> readPoints() async => null;
  @override
  Future<void> write(Map<String, dynamic>? data, String? etag) async {}
  @override
  Future<void> writePoints(List<dynamic> points) async {}
}

KioskState _online({
  required Future<ReceptionResult> Function() schedule,
  required Future<List<dynamic>> Function() points,
}) => KioskState(
  api: _FakeScheduleApi(schedule),
  pointsApi: _FakePointsApi(points),
  cache: _NoCache(),
  clock: _wed,
);

Future<ReceptionResult> _served() async => ReceptionResult(
  schedule: ReceptionSchedule.parse(_payload()),
  raw: _payload(),
  etag: 'W/"reception-schedule.2"',
);

Widget _screen(KioskState state, Lang lang) => MaterialApp(
  home: Scaffold(
    body: ShaxsiyScreen(
      lang: lang,
      officials: state.officials,
      intro: state.intro(lang),
      note: state.note(lang),
    ),
  ),
);

void main() {
  group('ReceptionSchedule.parse', () {
    test('orders by sort_order and drops inactive officials', () {
      final s = ReceptionSchedule.parse(_payload());

      expect(s.officials.length, 2);
      expect(s.officials.first.name[Lang.uz], 'Birinchi Mansabdor');
      expect(s.officials.last.name[Lang.uz], 'Ikkinchi Mansabdor');
      expect(s.officials.first.time, '10:00 – 14:00');
      expect(s.officials.first.phone, '71-232-80-73');
    });

    test('an empty ru/en falls back to uz, never to a blank card', () {
      final s = ReceptionSchedule.parse(_payload());

      expect(s.officials.first.day[Lang.ru], 'Har haftaning chorshanba kuni');
      expect(s.note[Lang.en], 'Server izohi');
      expect(s.intro[Lang.ru], 'Серверный интро');
    });

    test('accepts the first draft field names (items / name / day)', () {
      final s = ReceptionSchedule.parse({
        'items': [
          {
            'name': {'uz': 'Eski Nom', 'ru': 'Старое', 'en': 'Old'},
            'position': {'uz': 'Lavozim'},
            'day': {'uz': 'Har haftaning dushanba kuni'},
            'time': '09:00 – 11:00',
            'phone': '71-000-00-00',
          },
        ],
      });

      expect(s.officials.single.name[Lang.uz], 'Eski Nom');
      expect(s.officials.single.day[Lang.uz], 'Har haftaning dushanba kuni');
    });

    test('an official with no name is skipped rather than drawn empty', () {
      final s = ReceptionSchedule.parse({
        'officials': [
          {'position': {'uz': 'Lavozim'}, 'time': '', 'phone': ''},
        ],
      });

      expect(s.isEmpty, isTrue);
    });
  });

  group('ReceptionApi.payloadOf', () {
    test('unwraps the {section, version, data} envelope', () {
      final body = jsonDecode(
        '{"section":"reception-schedule","version":1,"data":{"officials":[]}}',
      );
      expect(
        ReceptionApi.payloadOf((body as Map).cast<String, dynamic>()),
        {'officials': []},
      );
    });

    test('an unseeded section (data:null) reads as no content', () {
      expect(
        ReceptionApi.payloadOf({
          'section': 'reception-schedule',
          'version': 0,
          'updated_at': null,
          'data': null,
        }),
        isNull,
      );
    });

    test('accepts the top-level shape the first draft specified', () {
      expect(
        ReceptionApi.payloadOf({
          'section': 'reception-schedule',
          'version': 5,
          'updated_at': 'x',
          'items': [],
        }),
        {'items': []},
      );
    });
  });

  group('KioskState', () {
    test('shows the built-in list until the backend has content', () {
      final state = KioskState(api: ReceptionApi(apiBase: ''));

      expect(state.fromBackend, isFalse);
      expect(state.officials, same(AppData.shaxsiyQabul));
      expect(state.intro(Lang.uz), Tr(Lang.uz).shaxsiyIntro);

      // An unseeded section is the same case: the hall screen is never blank.
      state.applySchedule(ReceptionSchedule.parse({'officials': []}));
      expect(state.officials, same(AppData.shaxsiyQabul));
      expect(state.note(Lang.uz), Tr(Lang.uz).shaxsiyNote);
    });

    test('a seeded section replaces the built-in list and its banners', () {
      final state = KioskState(api: ReceptionApi(apiBase: ''))
        ..applySchedule(ReceptionSchedule.parse(_payload()));

      expect(state.fromBackend, isTrue);
      expect(state.officials.length, 2);
      expect(state.intro(Lang.ru), 'Серверный интро');
    });

    test('a cached payload is on screen before the network is touched',
        () async {
      final dir = await Directory.systemTemp.createTemp('kiosk_cache_test');
      addTearDown(() => dir.delete(recursive: true));

      final cache = ReceptionCache(dir: dir);
      await cache.write(_payload(), 'W/"reception-schedule.1"');

      // apiBase empty => refresh() is a no-op, so only the cache can fill this.
      final state = KioskState(api: ReceptionApi(apiBase: ''), cache: cache);
      await state.start();

      expect(state.fromBackend, isTrue);
      expect(state.officials.first.name[Lang.uz], 'Birinchi Mansabdor');
      state.dispose();
    });
  });

  group('HokimReception', () {
    test("reads the governor's point, on the Tashkent clock", () {
      final h = HokimReception.fromPoints(_points())!;

      // 05:00Z is 10:00 in Tashkent — not the President's point's date.
      expect(h.at, DateTime.utc(2026, 9, 24, 10));
      expect(h.location, 'Toshkent viloyati Xalq qabulxonasi');
    });

    test('an offset or a bare time is read as Tashkent time too', () {
      for (final at in ['2026-09-24T10:00:00+05:00', '2026-09-24T10:00:00']) {
        final h = HokimReception.fromPoints(_points(at: at))!;
        expect((h.at!.day, h.at!.hour), (24, 10), reason: at);
      }
    });

    test('no time set is "not set"; no governor at all is "unknown"', () {
      expect(HokimReception.fromPoints(_points(at: null))!.at, isNull);
      expect(HokimReception.fromPoints(_points(at: ''))!.at, isNull);

      expect(HokimReception.fromPoints([_points().first]), isNull);
      expect(HokimReception.fromPoints({'detail': 'x'}), isNull);
      expect(HokimReception.fromPoints(null), isNull);
    });

    test('without a ticket prefix the name decides', () {
      final h = HokimReception.fromPoints([
        {'name_uz': 'Hokim qabuli', 'next_reception_at': '2026-09-24T05:00:00Z'},
      ]);
      expect(h?.at?.day, 24);
    });

    test('stays upcoming to the end of its day in Tashkent', () {
      final h = HokimReception.fromPoints(_points())!;

      expect(h.isUpcoming(_wed()), isTrue);
      // 24th, 23:59 Tashkent = 18:59Z — past the start hour, same day.
      expect(h.isUpcoming(DateTime.utc(2026, 9, 24, 18, 59)), isTrue);
      // 25th, 00:00 Tashkent = 19:00Z on the 24th.
      expect(h.isUpcoming(DateTime.utc(2026, 9, 24, 19)), isFalse);
    });

    test('finds the governor, not a deputy "hokimining o\'rinbosari"', () {
      final hits = [
        for (var i = 0; i < AppData.shaxsiyQabul.length; i++)
          if (isHokimOfficial(AppData.shaxsiyQabul[i])) i,
      ];
      expect(hits, [0]);
    });
  });

  group('AppData.receptionDate', () {
    final d = DateTime.utc(2026, 9, 24, 10);

    test('reads naturally in all three languages', () {
      expect(AppData.receptionDate(d, Lang.uz), '24-sentabr, payshanba');
      expect(AppData.receptionDate(d, Lang.ru), '24 сентября, четверг');
      expect(AppData.receptionDate(d, Lang.en), 'Thursday, 24 September');
    });

    test('names the year only when asked', () {
      final jan = DateTime.utc(2027, 1, 4);
      expect(AppData.receptionDate(jan, Lang.uz, withYear: true),
          '2027-yil 4-yanvar, dushanba');
      expect(AppData.receptionDate(jan, Lang.ru, withYear: true),
          '4 января 2027 г., понедельник');
      expect(AppData.receptionDate(jan, Lang.en, withYear: true),
          'Monday, 4 January 2027');
    });
  });

  group("KioskState — the governor's date", () {
    KioskState state(DateTime now) =>
        KioskState(api: ReceptionApi(apiBase: ''), clock: () => now);

    test('replaces the weekly slot on the governor card only', () {
      final s = state(_wed())..applyPoints(_points());
      final hokim = s.officials.first;

      expect(hokim.day[Lang.uz], '24-sentabr, payshanba');
      expect(hokim.day[Lang.ru], '24 сентября, четверг');
      expect(hokim.time, '10:00');
      expect(hokim.location, 'Toshkent viloyati Xalq qabulxonasi');
      expect(hokim.scheduled?.at, DateTime.utc(2026, 9, 24, 10));
      expect(hokim.scheduled?.withYear, isFalse);
      expect(hokim.name, AppData.shaxsiyQabul.first.name);
      expect(hokim.phone, AppData.shaxsiyQabul.first.phone);

      // Deputies keep the weekly wording, untouched.
      for (var i = 1; i < AppData.shaxsiyQabul.length; i++) {
        expect(s.officials[i], same(AppData.shaxsiyQabul[i]));
      }
    });

    test('applies to the server list as well as the built-in one', () {
      final s = state(_wed())
        ..applySchedule(ReceptionSchedule.parse(_payload()))
        ..applyPoints(_points());

      expect(s.officials.first.name[Lang.uz], 'Birinchi Mansabdor');
      expect(s.officials.first.time, '10:00');
      expect(s.officials.last.time, '15:00 – 17:00');
    });

    test('a passed or cleared date says it is not set', () {
      for (final s in [
        state(DateTime.utc(2026, 9, 25, 6))..applyPoints(_points()),
        state(_wed())..applyPoints(_points(at: null)),
      ]) {
        final hokim = s.officials.first;
        expect(hokim.day[Lang.uz], 'Qabul vaqti belgilanmagan');
        expect(hokim.day[Lang.en], 'Reception time not set');
        expect(hokim.time, isEmpty);
        expect(hokim.location, isEmpty);
        expect(hokim.scheduled, isNull);
      }
    });

    test('an unknown date leaves the weekly wording up', () {
      final s = state(_wed())..applyPoints([_points().first]);
      expect(s.officials, same(AppData.shaxsiyQabul));
    });

    test('a cached date is on screen before the network is touched',
        () async {
      final dir = await Directory.systemTemp.createTemp('kiosk_points_test');
      addTearDown(() => dir.delete(recursive: true));

      final cache = ReceptionCache(dir: dir);
      await cache.writePoints(_points());
      expect(await cache.readPoints(), _points());

      final s = KioskState(
        api: ReceptionApi(apiBase: ''),
        cache: cache,
        clock: _wed,
      );
      await s.start();

      expect(s.officials.first.time, '10:00');
      s.dispose();
    });
  });

  group('KioskState.refresh', () {
    test('true when both answers arrive, and the screen follows them',
        () async {
      final s = _online(schedule: _served, points: () async => _points());

      expect(await s.refresh(), isTrue);
      expect(s.fromBackend, isTrue);
      expect(s.officials.first.name[Lang.uz], 'Birinchi Mansabdor');
      expect(s.officials.first.time, '10:00');
    });

    test('false when either fails, and nothing on screen changes', () async {
      final s = _online(
        schedule: _served,
        points: () async => throw const SocketException('down'),
      );

      expect(await s.refresh(), isFalse);
      // The schedule that did arrive is still applied.
      expect(s.fromBackend, isTrue);
      expect(s.officials.first.time, '10:00 – 14:00');
    });

    test('an offline build reports failure rather than success', () async {
      final s = KioskState(api: ReceptionApi(apiBase: ''), cache: _NoCache());
      expect(await s.refresh(), isFalse);
    });

    test('a second call while one is running joins it', () async {
      final api = _FakeScheduleApi(() async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return const ReceptionResult.notModified();
      });
      final points = _FakePointsApi(() async => _points());
      final s = KioskState(api: api, pointsApi: points, cache: _NoCache());

      final both = await Future.wait([s.refresh(), s.refresh()]);
      expect(both, [true, true]);
      expect((api.calls, points.calls), (1, 1));

      // …and a later one goes out again.
      await s.refresh();
      expect((api.calls, points.calls), (2, 2));
    });
  });

  group('staff refresh — holding the logo', () {
    Future<void> pumpKiosk(WidgetTester tester, KioskState state) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(home: KioskRoot(state: state)));
      await tester.pump(const Duration(milliseconds: 600));
    }

    Future<void> hold(WidgetTester tester, Duration howLong) async {
      final g = await tester.startGesture(
        tester.getCenter(find.byType(Image).first),
      );
      await tester.pump(howLong);
      await g.up();
      await tester.pump(const Duration(milliseconds: 100));
    }

    // The shell's clock and refresh timers must stop before the test ends.
    Future<void> unmount(WidgetTester tester) =>
        tester.pumpWidget(const SizedBox());

    testWidgets('a short press does nothing', (tester) async {
      final api = _FakeScheduleApi(_served);
      final s = KioskState(
        api: api,
        pointsApi: _FakePointsApi(() async => _points()),
        cache: _NoCache(),
        clock: _wed,
      );
      await pumpKiosk(tester, s);
      final before = api.calls; // the start-up fetch

      await hold(tester, const Duration(seconds: 1));
      expect(api.calls, before);
      expect(find.text("Ma'lumot yangilanmoqda…"), findsNothing);
      await unmount(tester);
    });

    testWidgets('three seconds fetches now and says it worked',
        (tester) async {
      final api = _FakeScheduleApi(_served);
      final s = KioskState(
        api: api,
        pointsApi: _FakePointsApi(() async => _points()),
        cache: _NoCache(),
        clock: _wed,
      );
      await pumpKiosk(tester, s);
      final before = api.calls;

      await hold(tester, const Duration(milliseconds: 3100));
      await tester.pump(const Duration(milliseconds: 500));
      expect(api.calls, before + 1);
      expect(find.textContaining("Ma'lumot yangilandi"), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('an unreachable server is reported, in the visitor language',
        (tester) async {
      final s = _online(
        schedule: () async => throw const SocketException('down'),
        points: () async => throw const SocketException('down'),
      )..setLang(Lang.ru);
      await pumpKiosk(tester, s);

      await hold(tester, const Duration(milliseconds: 3100));
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        find.text('Нет связи с сервером — показаны прежние данные'),
        findsOneWidget,
      );
      await unmount(tester);
    });
  });

  test('the bundled root certificate loads', () {
    expect(
      () => SecurityContext(withTrustedRoots: false)
        ..setTrustedCertificatesBytes(utf8.encode(isrgRootX1Pem)),
      returnsNormally,
    );
  });

  testWidgets("the governor's card shows the date and the place",
      (tester) async {
    final state = KioskState(api: ReceptionApi(apiBase: ''), clock: _wed)
      ..applyPoints(_points());

    await tester.pumpWidget(_screen(state, Lang.uz));
    await tester.pumpAndSettle();
    expect(find.text('24-sentabr'), findsOneWidget);
    expect(find.text('Payshanba'), findsOneWidget);
    expect(find.text('10:00'), findsOneWidget);
    expect(find.text('NAVBATDAGI QABUL'), findsOneWidget);
    expect(find.text('Toshkent viloyati Xalq qabulxonasi'), findsOneWidget);
    expect(find.byIcon(Icons.place_outlined), findsOneWidget);
    // The weekly Wednesday line is gone from the governor's card only.
    expect(find.text('10:00 – 14:00'), findsNothing);
  });

  testWidgets("portrait kiosk: the governor's card spans the row",
      (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final state = KioskState(api: ReceptionApi(apiBase: ''), clock: _wed)
      ..applyPoints(_points());
    await tester.pumpWidget(_screen(state, Lang.ru));
    await tester.pumpAndSettle();

    final hokim = tester.getRect(find.text('Мирзаев Зоир Тоирович'));
    final date = tester.getRect(find.text('24 сентября'));
    // Side by side: the date sits to the right of the name, on its line band.
    expect(date.left, greaterThan(hokim.right));
    expect(date.top, lessThan(hokim.bottom + 120));

    // The deputies below run two to a row.
    final second = tester.getRect(find.text('Турсунов Отабек Равшанбек ўғли'));
    final third = tester.getRect(find.text('Қорабоев Хуршид Абдивахобович'));
    expect(third.top, closeTo(second.top, 1));
    expect(third.left, greaterThan(second.left + 300));
    expect(tester.takeException(), isNull);
  });

  testWidgets('portrait at 125 % and 150 % scaling lays out without overflow',
      (tester) async {
    addTearDown(tester.view.reset);
    final state = KioskState(api: ReceptionApi(apiBase: ''), clock: _wed)
      ..applyPoints(_points());

    // 125 %: 864 px wide — still side by side, two columns.
    // 150 %: 720 px wide — the governor's card stacks, one column.
    for (final (ratio, sideBySide) in [(1.25, true), (1.5, false)]) {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = ratio;
      for (final lang in Lang.values) {
        await tester.pumpWidget(_screen(state, lang));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$ratio ${lang.name}');
      }
      final name = tester.getRect(find.text('Mirzayev Zoyir Toirovich'));
      final date = tester.getRect(find.text('24 September'));
      expect(date.left > name.right, sideBySide, reason: '$ratio');
      expect(date.top > name.bottom, !sideBySide, reason: '$ratio');
    }
  });

  testWidgets('the screen draws whichever officials it is handed',
      (tester) async {
    final state = KioskState(api: ReceptionApi(apiBase: ''));

    await tester.pumpWidget(_screen(state, Lang.uz));
    await tester.pumpAndSettle();
    expect(find.text(AppData.shaxsiyQabul.first.name[Lang.uz]!), findsOneWidget);

    state.applySchedule(ReceptionSchedule.parse(_payload()));
    await tester.pumpWidget(_screen(state, Lang.uz));
    await tester.pumpAndSettle();
    expect(find.text('Birinchi Mansabdor'), findsOneWidget);
    expect(find.text('Server intro'), findsOneWidget);
    expect(find.text('71-232-80-44'), findsOneWidget);
  });
}
