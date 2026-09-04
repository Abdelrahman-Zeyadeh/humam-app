import 'package:flutter/material.dart';

/// فئات ألوان التجويد المعتمدة اصطلاحياً في المصاحف الملونة
class TajweedColors {
  TajweedColors._();

  /// المد اللازم (٦ حركات) - أحمر داكن
  static const Color maddLazim = Color(0xFFB71C1C);

  /// المد الواجب المتصل (٤-٥ حركات) - أحمر قاني
  static const Color maddWajib = Color(0xFFE53935);

  /// المد الجائز المنفصل والصلة الكبرى (٢-٤ حركات) - وردي / أحمر فاتح
  static const Color maddJaiz = Color(0xFFF06292);

  /// القلقلة (قطب جد عند السكون) - أزرق سماوي
  static const Color qalqalah = Color(0xFF1E88E5);

  /// الغنة المشددة (النون والميم المشددتان) - برتقالي ذهبي
  static const Color ghunnah = Color(0xFFFB8C00);

  /// الإخفاء الحقيقي والشفوي - أخضر زمردي
  static const Color ikhfa = Color(0xFF43A047);

  /// الإدغام بغنة - برتقالي فاتح
  static const Color idghamGhunnah = Color(0xFFFF9800);

  /// الإدغام بغير غنة (اللام والراء) - رمادي خفيف للإدغام الكامل
  static const Color idghamNoGhunnah = Color(0xFF9E9E9E);

  /// الإقلاب - بنفسجي
  static const Color iqlab = Color(0xFF8E24AA);

  /// الإظهار الحلقي والشفوي - أخضر وقار
  static const Color izhhar = Color(0xFF2E7D32);
}

/// نموذج مقطع تجويدي ملون
class TajweedSpanSegment {
  final String text;
  final Color? color;
  final String? ruleName;

  const TajweedSpanSegment({
    required this.text,
    this.color,
    this.ruleName,
  });
}

/// محرك تحليل وتلوين التجويد في النص القرآني
class TajweedTextParser {
  TajweedTextParser._();

  // أحرف القلقلة
  static const _qalqalahChars = {'ق', 'ط', 'ب', 'ج', 'د'};

  // أحرف الإظهار الحلقي
  static const _izhharChars = {'ء', 'أ', 'إ', 'ه', 'هـ', 'ع', 'ح', 'غ', 'خ'};

  // أحرف الإدغام بغنة
  static const _idghamGhunnahChars = {'ي', 'ن', 'م', 'و', 'ى'};

  // أحرف الإدغام بغير غنة
  static const _idghamNoGhunnahChars = {'ل', 'ر'};

  // أحرف الإخفاء الحقيقي
  static const _ikhfaChars = {
    'ص', 'ذ', 'ث', 'ك', 'ج', 'ش', 'ق', 'س', 'د', 'ط', 'ز', 'ف', 'ت', 'ض', 'ظ'
  };

  // علامات التشكيل والضبط
  static const String _sukun = 'ْ';
  static const String _shaddah = 'ّ';
  static const String _maddah = 'ٓ';
  static const String _smallMeem = 'ۢ';
  static const String _smallHighMeem = '٘';

  /// تحليل نص قرآني إلى مقاطع ملونة بأحكام التجويد
  static List<TajweedSpanSegment> parse(String text) {
    if (text.isEmpty) return const [];

    final segments = <TajweedSpanSegment>[];
    final runes = text.runes.toList();
    final len = runes.length;

    var i = 0;
    while (i < len) {
      final char = String.fromCharCode(runes[i]);

      // 1. فحص المد (علامة المد ۤ)
      if (char == _maddah || (i + 1 < len && String.fromCharCode(runes[i + 1]) == _maddah)) {
        var end = i + 1;
        while (end < len && _isDiacriticOrMark(String.fromCharCode(runes[end]))) {
          end++;
        }

        // التحقق من نوع المد: متصل، منفصل، أم لازم
        final afterMadd = _getNextLetter(runes, end);
        Color maddColor = TajweedColors.maddJaiz;
        String maddName = 'مد جائز منفصل';

        if (afterMadd != null) {
          if (afterMadd.letter == 'ء' || afterMadd.letter == 'أ' || afterMadd.letter == 'إ') {
            maddColor = TajweedColors.maddWajib;
            maddName = 'مد واجب متصل';
          } else if (afterMadd.hasShaddah || afterMadd.hasSukun) {
            maddColor = TajweedColors.maddLazim;
            maddName = 'مد لازم';
          }
        }

        final slice = _sliceRunes(runes, i, end);
        segments.add(TajweedSpanSegment(text: slice, color: maddColor, ruleName: maddName));
        i = end;
        continue;
      }

      // 2. النون والميم المشددتان (غنة مشددة أكمل ما تكون)
      if ((char == 'ن' || char == 'م') && _hasShaddahAfter(runes, i)) {
        var end = i + 1;
        while (end < len && _isDiacriticOrMark(String.fromCharCode(runes[end]))) {
          end++;
        }
        final slice = _sliceRunes(runes, i, end);
        segments.add(TajweedSpanSegment(text: slice, color: TajweedColors.ghunnah, ruleName: 'غنة مشددة'));
        i = end;
        continue;
      }

      // 3. القلقلة (قطب جد عند السكون الصريح أو الوقوف)
      if (_qalqalahChars.contains(char) && _hasSukunAfter(runes, i)) {
        var end = i + 1;
        while (end < len && _isDiacriticOrMark(String.fromCharCode(runes[end]))) {
          end++;
        }
        final slice = _sliceRunes(runes, i, end);
        segments.add(TajweedSpanSegment(text: slice, color: TajweedColors.qalqalah, ruleName: 'قلقلة'));
        i = end;
        continue;
      }

      // 4. الإقلاب (ميم الإقلاب ۢ الصغيرة أو نون تليها باء)
      if (char == _smallMeem || char == _smallHighMeem || (char == 'ن' && _isNextLetterBaa(runes, i))) {
        var end = i + 1;
        while (end < len && _isDiacriticOrMark(String.fromCharCode(runes[end]))) {
          end++;
        }
        final slice = _sliceRunes(runes, i, end);
        segments.add(TajweedSpanSegment(text: slice, color: TajweedColors.iqlab, ruleName: 'إقلاب'));
        i = end;
        continue;
      }

      // 5. أحكام النون الساكنة والتنوين (إدغام، إخفاء، إظهار)
      if (char == 'ن' || _isTanween(char)) {
        final nextLet = _getNextLetter(runes, i + 1);
        if (nextLet != null) {
          if (_idghamGhunnahChars.contains(nextLet.letter)) {
            var end = i + 1;
            while (end < len && _isDiacriticOrMark(String.fromCharCode(runes[end]))) {
              end++;
            }
            final slice = _sliceRunes(runes, i, end);
            segments.add(TajweedSpanSegment(text: slice, color: TajweedColors.idghamGhunnah, ruleName: 'إدغام بغنة'));
            i = end;
            continue;
          } else if (_idghamNoGhunnahChars.contains(nextLet.letter)) {
            var end = i + 1;
            while (end < len && _isDiacriticOrMark(String.fromCharCode(runes[end]))) {
              end++;
            }
            final slice = _sliceRunes(runes, i, end);
            segments.add(TajweedSpanSegment(text: slice, color: TajweedColors.idghamNoGhunnah, ruleName: 'إدغام بغير غنة'));
            i = end;
            continue;
          } else if (_ikhfaChars.contains(nextLet.letter)) {
            var end = i + 1;
            while (end < len && _isDiacriticOrMark(String.fromCharCode(runes[end]))) {
              end++;
            }
            final slice = _sliceRunes(runes, i, end);
            segments.add(TajweedSpanSegment(text: slice, color: TajweedColors.ikhfa, ruleName: 'إخفاء'));
            i = end;
            continue;
          } else if (_izhharChars.contains(nextLet.letter)) {
            var end = i + 1;
            while (end < len && _isDiacriticOrMark(String.fromCharCode(runes[end]))) {
              end++;
            }
            final slice = _sliceRunes(runes, i, end);
            segments.add(TajweedSpanSegment(text: slice, color: TajweedColors.izhhar, ruleName: 'إظهار'));
            i = end;
            continue;
          }
        }
      }

      // حرف عادي بدون حكم تجويدي مخصص
      // تجميع الحروف المتتالية العادية لتقليل عدد الـ Spans
      var end = i + 1;
      while (end < len) {
        if (_isSpecialRuleTrigger(runes, end)) break;
        end++;
      }

      final plainSlice = _sliceRunes(runes, i, end);
      segments.add(TajweedSpanSegment(text: plainSlice));
      i = end;
    }

    return segments;
  }

  /// تحويل النص القرآني مباشرة إلى TextSpans ملونة
  static List<InlineSpan> buildSpans(
    String text, {
    required Color defaultColor,
    double? fontSize,
    double? height,
    String? fontFamily,
    FontWeight? fontWeight,
    bool enableTajweed = true,
  }) {
    if (!enableTajweed) {
      return [
        TextSpan(
          text: text,
          style: TextStyle(
            color: defaultColor,
            fontSize: fontSize,
            height: height,
            fontFamily: fontFamily,
            fontWeight: fontWeight,
          ),
        ),
      ];
    }

    final segments = parse(text);
    return segments.map((seg) {
      return TextSpan(
        text: seg.text,
        style: TextStyle(
          color: seg.color ?? defaultColor,
          fontSize: fontSize,
          height: height,
          fontFamily: fontFamily,
          fontWeight: seg.color != null ? FontWeight.w600 : fontWeight,
        ),
      );
    }).toList();
  }

  /// تحويل كلمة واحدة إلى TextSpans مع وصل الحروف العربية المشتركة بواسطة (Zero-Width Joiner)
  /// لمنع تقطّع الحروف عند تجزئتها إلى مقاطع ملونة مختلفة داخل نفس الكلمة
  static List<InlineSpan> buildConnectedWordSpans(
    String wordText, {
    required Color defaultColor,
    required TextStyle baseStyle,
  }) {
    final rawSegments = parse(wordText);
    if (rawSegments.isEmpty) return const [];
    if (rawSegments.length == 1) {
      final seg = rawSegments.first;
      return [
        TextSpan(
          text: seg.text,
          style: baseStyle.copyWith(
            color: seg.color ?? defaultColor,
            fontWeight: seg.color != null ? FontWeight.w700 : baseStyle.fontWeight,
          ),
        ),
      ];
    }

    const nonConnecting = {'ا', 'أ', 'إ', 'آ', 'ٱ', 'د', 'ذ', 'ر', 'ز', 'و', 'ؤ', 'ء', 'ة'};

    final spans = <InlineSpan>[];
    for (var i = 0; i < rawSegments.length; i++) {
      final seg = rawSegments[i];
      var text = seg.text;

      final shouldConnectBefore = i > 0 && !_lastBaseLetterIsNonConnecting(rawSegments[i - 1].text, nonConnecting);
      final shouldConnectAfter = i < rawSegments.length - 1 && !_lastBaseLetterIsNonConnecting(text, nonConnecting);

      if (shouldConnectBefore) {
        text = '\u200D$text';
      }
      if (shouldConnectAfter) {
        text = '$text\u200D';
      }

      spans.add(TextSpan(
        text: text,
        style: baseStyle.copyWith(
          color: seg.color ?? defaultColor,
          fontWeight: seg.color != null ? FontWeight.w700 : baseStyle.fontWeight,
        ),
      ));
    }

    return spans;
  }

  static bool _lastBaseLetterIsNonConnecting(String s, Set<String> nonConnecting) {
    final runes = s.runes.toList();
    for (var i = runes.length - 1; i >= 0; i--) {
      final c = String.fromCharCode(runes[i]);
      if (!_isDiacriticOrMark(c) && c.trim().isNotEmpty) {
        return nonConnecting.contains(c);
      }
    }
    return false;
  }

  // --- Helper Methods ---

  static bool _isSpecialRuleTrigger(List<int> runes, int index) {
    if (index >= runes.length) return false;
    final c = String.fromCharCode(runes[index]);
    if (c == _maddah) return true;
    if ((c == 'ن' || c == 'م') && _hasShaddahAfter(runes, index)) return true;
    if (_qalqalahChars.contains(c) && _hasSukunAfter(runes, index)) return true;
    if (c == _smallMeem || c == _smallHighMeem) return true;
    if (c == 'ن' || _isTanween(c)) return true;
    return false;
  }

  static bool _hasShaddahAfter(List<int> runes, int index) {
    var j = index + 1;
    while (j < runes.length && _isDiacriticOrMark(String.fromCharCode(runes[j]))) {
      if (String.fromCharCode(runes[j]) == _shaddah) return true;
      j++;
    }
    return false;
  }

  static bool _hasSukunAfter(List<int> runes, int index) {
    var j = index + 1;
    while (j < runes.length && _isDiacriticOrMark(String.fromCharCode(runes[j]))) {
      final mark = String.fromCharCode(runes[j]);
      if (mark == _sukun || mark == '۟' || mark == 'ۡ') return true;
      j++;
    }
    return false;
  }

  static bool _isNextLetterBaa(List<int> runes, int index) {
    final next = _getNextLetter(runes, index + 1);
    return next != null && next.letter == 'ب';
  }

  static ({String letter, bool hasShaddah, bool hasSukun})? _getNextLetter(List<int> runes, int startIndex) {
    var j = startIndex;
    var foundLetter = false;
    String letter = '';
    var hasShaddah = false;
    var hasSukun = false;

    while (j < runes.length) {
      final c = String.fromCharCode(runes[j]);
      if (!_isDiacriticOrMark(c) && c.trim().isNotEmpty) {
        if (!foundLetter) {
          foundLetter = true;
          letter = c;
        } else {
          break;
        }
      } else if (foundLetter) {
        if (c == _shaddah) hasShaddah = true;
        if (c == _sukun) hasSukun = true;
      }
      j++;
    }

    if (foundLetter) {
      return (letter: letter, hasShaddah: hasShaddah, hasSukun: hasSukun);
    }
    return null;
  }

  static bool _isDiacriticOrMark(String c) {
    if (c.isEmpty) return false;
    final code = c.codeUnitAt(0);
    // نطاق التشكيل والرموز القرآنية
    return (code >= 0x064B && code <= 0x065F) ||
           (code >= 0x0670 && code <= 0x0670) ||
           (code >= 0x06D6 && code <= 0x06ED);
  }

  static bool _isTanween(String c) {
    if (c.isEmpty) return false;
    final code = c.codeUnitAt(0);
    return code == 0x064B || code == 0x064C || code == 0x064D; // فتحتان، ضمتان، كسرتان
  }

  static String _sliceRunes(List<int> runes, int start, int end) {
    return String.fromCharCodes(runes.sublist(start, end));
  }
}
