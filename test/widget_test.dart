// The kiosk draws the reception schedule the backend serves, and falls back to
// its built-in list whenever the backend has nothing to say.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shaxiy_qabul_kiosk/src/data.dart';
import 'package:shaxiy_qabul_kiosk/src/kiosk_state.dart';
import 'package:shaxiy_qabul_kiosk/src/l10n.dart';
import 'package:shaxiy_qabul_kiosk/src/screens/shaxsiy_screen.dart';
import 'package:shaxiy_qabul_kiosk/src/services/reception_api.dart';

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
