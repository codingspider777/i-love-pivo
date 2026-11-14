import 'package:flutter/material.dart' show TimeOfDay;
import 'package:salamanca/data/models/category.dart';
import 'package:salamanca/data/models/task.dart';

class ParsedTask {
  const ParsedTask({
    required this.title,
    this.date,
    this.time,
    this.priority,
    this.categoryId,
  });

  final String title;
  final DateTime? date;
  final TimeOfDay? time;
  final TaskPriority? priority;
  final int? categoryId;
}

/// Разбор строки вида «Завтра в 10:00 сдать лабу #учёба !высокий».
///
/// Понимает: сегодня / завтра / послезавтра, «через N дней|недель|месяцев»,
/// дни недели («в пятницу»), даты «25.11», «25.11.2026», «25 ноября»,
/// время «10:00», «в 10», «в 7 вечера»; приоритет «!высокий», «срочно»;
/// категорию «#работа».
class QuickAddParser {
  QuickAddParser._();

  // \b не работает с кириллицей, поэтому свои границы слова.
  static const _b = r'(?<![\p{L}\d])';
  static const _e = r'(?![\p{L}\d])';
  static const _prep = r'(?:(?<![\p{L}\d])(?:в|во|на|к|до)\s+)?';

  static const _monthNames = [
    'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
    'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
  ];

  static RegExp _re(String p) =>
      RegExp(p, caseSensitive: false, unicode: true);

  static final _tag = _re(r'#([\p{L}\d_]+)');
  static final _prioWord = _re(r'!(высок|средн|низк)\p{L}*');
  static final _urgent = _re('$_b(срочно|важно)$_e');
  static final _timeColon =
      _re('$_prep(?<![\\d.:])(\\d{1,2}):(\\d{2})(?!\\d)');
  static final _dateNum = _re(
      '$_prep(?<![\\d.:])(\\d{1,2})\\.(\\d{1,2})(?:\\.(\\d{4}|\\d{2}))?(?!\\d|\\.\\d)');
  static final _dateWord = _re(
      '$_prep(?<![\\d.])(\\d{1,2})\\s+(${_monthNames.join('|')})(?:\\s+(\\d{4}))?$_e');
  static final _afterTomorrow = _re('$_b${'послезавтра'}$_e');
  static final _tomorrow = _re('$_b${'завтра'}$_e');
  static final _today = _re('$_b${'сегодня'}$_e');
  static final _inN = _re(
      '$_b${'через'}\\s+(\\d{1,3})\\s+(дн(?:я|ей)|день|недел(?:ю|и|ь)|месяц(?:а|ев)?)$_e');
  static final _inOne = _re('$_b${'через'}\\s+(неделю|месяц)$_e');
  static final _weekday = _re(
      '$_prep$_b(понедельник|вторник|сред[ауы]?|четверг|пятниц[ауы]?|суббот[ауы]?|воскресень[ея])$_e');
  static final _timeWord = _re(
      '$_prep(?<![\\d.:])(\\d{1,2})\\s*(утра|вечера|дня|ночи)$_e');
  static final _timeBare = _re('$_b${'в'}\\s+(\\d{1,2})(?![\\d:]|\\.\\d)');

  static String _norm(String s) => s.toLowerCase().replaceAll('ё', 'е');

  static TaskCategory? _findCategory(List<TaskCategory> list, String tag) {
    final t = _norm(tag);
    if (t.length < 2) return null;
    for (final c in list) {
      final n = _norm(c.name);
      if (n.startsWith(t) || t.startsWith(n)) return c;
    }
    return null;
  }

  static DateTime _day(DateTime base, int plusDays) =>
      DateTime(base.year, base.month, base.day + plusDays);

  static DateTime? _numDate(int d, int mo, String? ys, DateTime today) {
    if (mo < 1 || mo > 12 || d < 1 || d > 31) return null;
    var y = today.year;
    final hasYear = ys != null;
    if (hasYear) {
      y = int.parse(ys);
      if (ys.length == 2) y += 2000;
    }
    var res = DateTime(y, mo, d);
    if (res.month != mo) return null; // 31.02 и т.п.
    if (!hasYear && res.isBefore(today)) res = DateTime(y + 1, mo, d);
    return res;
  }

  static ParsedTask parse(
    String input, {
    required DateTime now,
    List<TaskCategory> categories = const [],
  }) {
    var text = input;
    final today = DateTime(now.year, now.month, now.day);
    DateTime? date;
    TimeOfDay? time;
    TaskPriority? priority;
    int? categoryId;

    RegExpMatch? take(RegExp re, [bool Function(RegExpMatch m)? accept]) {
      for (final m in re.allMatches(text)) {
        if (accept != null && !accept(m)) continue;
        text = text.replaceRange(m.start, m.end, ' ');
        return m;
      }
      return null;
    }

    // Категория: #учёба
    final tagM =
        take(_tag, (m) => _findCategory(categories, m[1]!) != null);
    if (tagM != null) categoryId = _findCategory(categories, tagM[1]!)!.id;

    // Приоритет
    final pm = take(_prioWord);
    if (pm != null) {
      final w = pm[1]!.toLowerCase();
      priority = w.startsWith('высок')
          ? TaskPriority.high
          : w.startsWith('средн')
              ? TaskPriority.medium
              : TaskPriority.low;
    } else if (take(_urgent) != null) {
      priority = TaskPriority.high;
    }

    // Время «10:00»
    final tm = take(_timeColon, (m) {
      final h = int.parse(m[1]!);
      final mi = int.parse(m[2]!);
      return h < 24 && mi < 60;
    });
    if (tm != null) {
      time = TimeOfDay(hour: int.parse(tm[1]!), minute: int.parse(tm[2]!));
    }

    // Дата «25.11[.2026]»
    final dm = take(_dateNum, (m) =>
        _numDate(int.parse(m[1]!), int.parse(m[2]!), m[3], today) != null);
    if (dm != null) {
      date = _numDate(int.parse(dm[1]!), int.parse(dm[2]!), dm[3], today);
    }

    // Дата «25 ноября [2026]»
    if (date == null) {
      final wm = take(_dateWord, (m) {
        final mo = _monthNames.indexOf(m[2]!.toLowerCase()) + 1;
        return _numDate(int.parse(m[1]!), mo, m[3], today) != null;
      });
      if (wm != null) {
        final mo = _monthNames.indexOf(wm[2]!.toLowerCase()) + 1;
        date = _numDate(int.parse(wm[1]!), mo, wm[3], today);
      }
    }

    // Относительные даты
    if (date == null && take(_afterTomorrow) != null) date = _day(today, 2);
    if (date == null && take(_tomorrow) != null) date = _day(today, 1);
    if (date == null && take(_today) != null) date = today;

    if (date == null) {
      final m = take(_inN);
      if (m != null) {
        final n = int.parse(m[1]!);
        final unit = m[2]!.toLowerCase();
        if (unit.startsWith('дн') || unit.startsWith('ден')) {
          date = _day(today, n);
        } else if (unit.startsWith('недел')) {
          date = _day(today, n * 7);
        } else {
          date = DateTime(today.year, today.month + n, today.day);
        }
      }
    }
    if (date == null) {
      final m = take(_inOne);
      if (m != null) {
        date = m[1]!.toLowerCase().startsWith('недел')
            ? _day(today, 7)
            : DateTime(today.year, today.month + 1, today.day);
      }
    }

    // День недели — ближайший будущий (если сегодня — то через неделю)
    if (date == null) {
      final m = take(_weekday);
      if (m != null) {
        final w = m[1]!.toLowerCase();
        final target = w.startsWith('понед')
            ? 1
            : w.startsWith('втор')
                ? 2
                : w.startsWith('сред')
                    ? 3
                    : w.startsWith('четв')
                        ? 4
                        : w.startsWith('пятн')
                            ? 5
                            : w.startsWith('субб')
                                ? 6
                                : 7;
        final delta = (target - today.weekday + 7) % 7;
        date = _day(today, delta == 0 ? 7 : delta);
      }
    }

    // «в 7 вечера»
    if (time == null) {
      final m = take(_timeWord, (m) {
        final h = int.parse(m[1]!);
        return h >= 1 && h <= 12;
      });
      if (m != null) {
        final h = int.parse(m[1]!);
        final part = m[2]!.toLowerCase();
        var hour = h;
        if (part == 'утра') {
          hour = h == 12 ? 0 : h;
        } else if (part == 'дня') {
          hour = h < 12 && h <= 6 ? h + 12 : h;
        } else if (part == 'вечера') {
          hour = h < 12 ? h + 12 : h;
        } else if (part == 'ночи') {
          hour = h == 12 ? 0 : (h >= 6 ? h + 12 : h);
        }
        time = TimeOfDay(hour: hour % 24, minute: 0);
      }
    }

    // «в 10»
    if (time == null) {
      final m = take(_timeBare, (m) => int.parse(m[1]!) <= 23);
      if (m != null) time = TimeOfDay(hour: int.parse(m[1]!), minute: 0);
    }

    // Чистим заголовок
    var title = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    title = title.replaceAll(RegExp(r'^[,;:\-—\s]+|[,;:\-—\s]+$'), '');
    title = title.replaceFirst(
        RegExp(r'\s+(в|во|на|к|до)$', caseSensitive: false), '');
    if (title.isNotEmpty) {
      title = title[0].toUpperCase() + title.substring(1);
    }

    return ParsedTask(
      title: title,
      date: date,
      time: time,
      priority: priority,
      categoryId: categoryId,
    );
  }
}
