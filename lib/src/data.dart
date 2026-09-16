import 'l10n.dart';

/// An official receiving citizens in person at the People's Reception:
/// full name (Latin, with a Cyrillic variant shown for Russian), localised
/// position, weekly reception slot and contact phone.
class QabulOfficial {
  const QabulOfficial(
    this.name,
    this.position,
    this.day,
    this.time,
    this.phone, {
    this.location = '',
    this.scheduled,
  });
  final Map<Lang, String> name;
  final Map<Lang, String> position;
  final Map<Lang, String> day;
  final String time;
  final String phone;

  /// Where the reception is held, when it is not the usual hall — set only
  /// for the governor's dated reception. Empty hides the line.
  final String location;

  /// The date of the reception when it is set rather than weekly — only the
  /// governor's. [day] still carries the same date as one line of text.
  final ScheduledReception? scheduled;
}

/// A reception on a set date (the governor's), for the card that draws the
/// date large rather than as a line of text.
class ScheduledReception {
  const ScheduledReception(this.at, {this.withYear = false});

  /// Start, on the Tashkent wall clock.
  final DateTime at;

  /// The date is not in the current year, so the year is written out.
  final bool withYear;
}

/// Whether [official] is the governor rather than a deputy.
///
/// Read from the Uzbek position: `hokimi` / `hokim` as a whole word. A
/// deputy's "viloyat hokim**ining** … o'rinbosari" contains `hokimi` too, so
/// the word boundary and the `o'rinbosar` check are both needed.
bool isHokimOfficial(QabulOfficial official) {
  final p = (official.position[Lang.uz] ?? '')
      .toLowerCase()
      .replaceAll(RegExp("['`‘’ʻʼ]"), '');
  return RegExp(r'\bhokimi?\b').hasMatch(p) && !p.contains('orinbosar');
}

/// All localised content shown by this single-purpose reception kiosk.
class AppData {
  const AppData._();

  /// In-person reception schedule: the governor of Tashkent region and the
  /// deputy governors, received weekly at the People's Reception building.
  static const List<QabulOfficial> shaxsiyQabul = [
    QabulOfficial(
      {
        Lang.uz: 'Mirzayev Zoyir Toirovich',
        Lang.ru: 'Мирзаев Зоир Тоирович',
        Lang.en: 'Mirzayev Zoyir Toirovich',
      },
      {
        Lang.uz: 'Toshkent viloyati hokimi',
        Lang.ru: 'Хоким Ташкентской области',
        Lang.en: 'Governor of Tashkent region',
      },
      _wednesday,
      '10:00 – 14:00',
      '71-232-80-73',
    ),
    QabulOfficial(
      {
        Lang.uz: "Tursunov Otabek Ravshanbek o'g'li",
        Lang.ru: 'Турсунов Отабек Равшанбек ўғли',
        Lang.en: "Tursunov Otabek Ravshanbek o'g'li",
      },
      {
        Lang.uz: "Viloyat hokimining moliya-iqtisod va kambag'allikni "
            "qisqartirish masalalari bo'yicha birinchi o'rinbosari",
        Lang.ru: 'Первый заместитель хокима области по финансово-'
            'экономическим вопросам и сокращению бедности',
        Lang.en: 'First deputy governor for finance, economy and poverty '
            'reduction',
      },
      _tuesday,
      '14:00 – 16:00',
      '71-232-80-71',
    ),
    QabulOfficial(
      {
        Lang.uz: 'Qoraboyev Xurshid Abdivahobovich',
        Lang.ru: 'Қорабоев Хуршид Абдивахобович',
        Lang.en: 'Qoraboyev Xurshid Abdivahobovich',
      },
      {
        Lang.uz: "Viloyat hokimining qishloq va suv xo'jaligi masalalari "
            "bo'yicha o'rinbosari",
        Lang.ru: 'Заместитель хокима области по вопросам сельского и '
            'водного хозяйства',
        Lang.en: 'Deputy governor for agriculture and water management',
      },
      _friday,
      '15:00 – 17:00',
      '71-232-80-44',
    ),
    QabulOfficial(
      {
        Lang.uz: 'Mahmudov Shukurulla Nasimxonovich',
        Lang.ru: 'Махмудов Шукурулла Насимхонович',
        Lang.en: 'Mahmudov Shukurulla Nasimxonovich',
      },
      {
        Lang.uz: "Viloyat hokimining qurilish, kommunikatsiyalar, kommunal "
            "xo'jalik, ekologiya va ko'kalamzorlashtirish masalalari "
            "bo'yicha o'rinbosari",
        Lang.ru: 'Заместитель хокима области по вопросам строительства, '
            'коммуникаций, коммунального хозяйства, экологии и озеленения',
        Lang.en: 'Deputy governor for construction, communications, '
            'utilities, ecology and landscaping',
      },
      _tuesday,
      '10:00 – 12:00',
      '71-232-80-42',
    ),
    QabulOfficial(
      {
        Lang.uz: 'Mamajonov Jahongir Anvarjonovich',
        Lang.ru: 'Мамажонов Жаҳонгир Анваржонович',
        Lang.en: 'Mamajonov Jahongir Anvarjonovich',
      },
      {
        Lang.uz: "Viloyat hokimining investitsiyalar, sanoat va savdo "
            "masalalari bo'yicha o'rinbosari",
        Lang.ru: 'Заместитель хокима области по вопросам инвестиций, '
            'промышленности и торговли',
        Lang.en: 'Deputy governor for investment, industry and trade',
      },
      _monday,
      '14:00 – 16:00',
      '99-301-19-90',
    ),
    QabulOfficial(
      {
        Lang.uz: 'Sultanbekov Otabek Sabirovich',
        Lang.ru: 'Султанбеков Отабек Сабирович',
        Lang.en: 'Sultanbekov Otabek Sabirovich',
      },
      {
        Lang.uz: "Viloyat hokimining yoshlar siyosati, ijtimoiy "
            "rivojlantirish va ma'naviy-ma'rifiy ishlar bo'yicha o'rinbosari",
        Lang.ru: 'Заместитель хокима области по молодёжной политике, '
            'социальному развитию и духовно-просветительской работе',
        Lang.en: 'Deputy governor for youth policy, social development and '
            'spiritual-educational affairs',
      },
      _friday,
      '9:00 – 11:00',
      '71-232-80-87',
    ),
    QabulOfficial(
      {
        Lang.uz: 'Babajanov Djamshid Xakimovich',
        Lang.ru: 'Бабажанов Джамшид Хакимович',
        Lang.en: 'Babajanov Djamshid Xakimovich',
      },
      {
        Lang.uz: "Viloyat hokimining turizm, madaniyat, madaniy meros va "
            "ommaviy kommunikatsiyalar masalalari bo'yicha o'rinbosari",
        Lang.ru: 'Заместитель хокима области по вопросам туризма, культуры, '
            'культурного наследия и массовых коммуникаций',
        Lang.en: 'Deputy governor for tourism, culture, cultural heritage '
            'and mass communications',
      },
      _thursday,
      '15:00 – 17:00',
      '99-313-43-99',
    ),
    QabulOfficial(
      {
        Lang.uz: 'Arzikulov Ilxomjon Nizomiddinovich',
        Lang.ru: 'Арзикулов Илхомжон Низомиддинович',
        Lang.en: 'Arzikulov Ilxomjon Nizomiddinovich',
      },
      {
        Lang.uz: "Viloyat hokimining jamoat va diniy tashkilotlar bilan "
            "aloqalar bo'yicha o'rinbosari",
        Lang.ru: 'Заместитель хокима области по связям с общественными и '
            'религиозными организациями',
        Lang.en: 'Deputy governor for relations with public and religious '
            'organisations',
      },
      _monday,
      '11:00 – 13:00',
      '71-232-80-30',
    ),
    QabulOfficial(
      {
        Lang.uz: 'Normirzayeva Nilufar Anvarjanovna',
        Lang.ru: 'Нормирзаева Нилуфар Анваржановна',
        Lang.en: 'Normirzayeva Nilufar Anvarjanovna',
      },
      {
        Lang.uz: "Viloyat hokimining o'rinbosari — oila va xotin-qizlar "
            "boshqarmasi boshlig'i",
        Lang.ru: 'Заместитель хокима области — начальник управления по '
            'делам семьи и женщин',
        Lang.en: 'Deputy governor — head of the family and women’s affairs '
            'department',
      },
      _thursday,
      '10:00 – 12:00',
      '71-232-80-71',
    ),
  ];

  // Weekly reception day labels shared by the officials above.
  static const Map<Lang, String> _monday = {
    Lang.uz: 'Har haftaning dushanba kuni',
    Lang.ru: 'Каждый понедельник',
    Lang.en: 'Every Monday',
  };
  static const Map<Lang, String> _tuesday = {
    Lang.uz: 'Har haftaning seshanba kuni',
    Lang.ru: 'Каждый вторник',
    Lang.en: 'Every Tuesday',
  };
  static const Map<Lang, String> _wednesday = {
    Lang.uz: 'Har haftaning chorshanba kuni',
    Lang.ru: 'Каждую среду',
    Lang.en: 'Every Wednesday',
  };
  static const Map<Lang, String> _thursday = {
    Lang.uz: 'Har haftaning payshanba kuni',
    Lang.ru: 'Каждый четверг',
    Lang.en: 'Every Thursday',
  };
  static const Map<Lang, String> _friday = {
    Lang.uz: 'Har haftaning juma kuni',
    Lang.ru: 'Каждую пятницу',
    Lang.en: 'Every Friday',
  };

  static const Map<Lang, List<String>> months = {
    Lang.uz: ['yanvar', 'fevral', 'mart', 'aprel', 'may', 'iyun', 'iyul', 'avgust', 'sentabr', 'oktabr', 'noyabr', 'dekabr'],
    Lang.ru: ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'],
    Lang.en: ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
  };

  static const Map<Lang, List<String>> weekdays = {
    Lang.uz: ['Yakshanba', 'Dushanba', 'Seshanba', 'Chorshanba', 'Payshanba', 'Juma', 'Shanba'],
    Lang.ru: ['Воскресенье', 'Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота'],
    Lang.en: ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'],
  };

  /// Localised date string, mirroring the source formatting per language.
  static String formatDate(DateTime d, Lang lang) {
    final wd = weekdays[lang]![d.weekday % 7];
    final mo = months[lang]![d.month - 1];
    return switch (lang) {
      Lang.en => '$wd, $mo ${d.day}, ${d.year}',
      Lang.ru => '$wd, ${d.day} $mo ${d.year}',
      Lang.uz => '$wd, ${d.day}-$mo ${d.year}',
    };
  }

  /// A reception date: `24-sentabr` · `24 сентября` · `24 September`, with
  /// the year only when asked.
  static String receptionDay(DateTime d, Lang lang, {bool withYear = false}) {
    final mo = months[lang]![d.month - 1];
    return switch (lang) {
      Lang.uz => withYear ? '${d.year}-yil ${d.day}-$mo' : '${d.day}-$mo',
      Lang.ru => withYear ? '${d.day} $mo ${d.year} г.' : '${d.day} $mo',
      Lang.en => withYear ? '${d.day} $mo ${d.year}' : '${d.day} $mo',
    };
  }

  /// `payshanba` · `четверг` · `Thursday` — lower-case where the language
  /// writes a weekday so after a date.
  static String weekdayName(DateTime d, Lang lang) {
    final wd = weekdays[lang]![d.weekday % 7];
    return lang == Lang.en ? wd : wd.toLowerCase();
  }

  /// The two above as one line: `24-sentabr, payshanba` ·
  /// `24 сентября, четверг` · `Thursday, 24 September`.
  static String receptionDate(DateTime d, Lang lang, {bool withYear = false}) {
    final day = receptionDay(d, lang, withYear: withYear);
    final wd = weekdayName(d, lang);
    return lang == Lang.en ? '$wd, $day' : '$day, $wd';
  }

  static String formatTime(DateTime d) {
    String p(int n) => n < 10 ? '0$n' : '$n';
    return '${p(d.hour)}:${p(d.minute)}:${p(d.second)}';
  }
}
