/// Lightweight three-language localisation (Uzbek / Russian / English).
///
/// Strings are stored as `[uz, ru, en]` triples and resolved by [Lang.index],
/// mirroring the original kiosk content one-to-one.
library;

enum Lang { uz, ru, en }

extension LangLabel on Lang {
  /// Short label shown on the language switch.
  String get label => switch (this) {
        Lang.uz => "O'Z",
        Lang.ru => 'РУ',
        Lang.en => 'EN',
      };
}

/// Translated UI strings for a single language.
class Tr {
  const Tr(this.lang);
  final Lang lang;

  String _p(List<String> v) => v[lang.index];

  /// Full official name of the office, shown as the main header title.
  String get orgFullName => _p(const [
        "O'zbekiston Respublikasi Prezidentining Toshkent viloyatidagi Xalq qabulxonasi",
        'Народная приёмная Президента Республики Узбекистан в Ташкентской области',
        "People's Reception of the President of the Republic of Uzbekistan in the Tashkent region",
      ]);

  String get footerHint => _p(const [
        'Ekranga tegib boshqaring',
        'Управляйте касанием экрана',
        'Touch the screen to navigate',
      ]);

  /// Section title shown in the sub-header of this single-purpose kiosk.
  String get shaxsiyTitle => _p(const [
        'Shaxsiy qabul',
        'Личный приём граждан',
        'In-person reception',
      ]);

  String get shaxsiyIntro => _p(const [
        "Toshkent viloyati hokimi va viloyat hokimi o'rinbosarlari tomonidan Toshkent viloyati Xalq qabulxonasi binosida jismoniy va yuridik shaxslarni qabul qilish jadvali",
        'График приёма физических и юридических лиц хокимом Ташкентской области и заместителями хокима в здании Народной приёмной Ташкентской области',
        "Schedule of reception of individuals and legal entities by the governor of Tashkent region and deputy governors at the People's Reception building",
      ]);

  String get shaxsiyNote => _p(const [
        "Qabullar har haftaning belgilangan kuni va vaqtida o'tkaziladi. Murojaat uchun telefonlar: (71) 230-24-30, (71) 230-24-31.",
        'Приёмы проводятся каждую неделю в установленные день и время. Телефоны для обращений: (71) 230-24-30, (71) 230-24-31.',
        'Receptions are held weekly on the designated day and time. Phones for appeals: (71) 230-24-30, (71) 230-24-31.',
      ]);
}
