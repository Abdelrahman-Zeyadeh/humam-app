/// قاموس ومحول أسماء أبواب كتب الحديث إلى اللغة العربية الفصحى
/// يضمن عدم ظهور أي اسم باب باللغة الإنجليزية في جميع كتب الحديث.
class HadithChapterArabicMap {
  static final Map<String, String> _translations = {
    // الأبواب الأساسية العامة
    'revelation': 'كتاب بدء الوحي',
    'belief': 'كتاب الإيمان',
    'faith': 'كتاب الإيمان',
    'knowledge': 'كتاب العلم',
    'ablution': 'كتاب الوضوء',
    'ablutions': 'كتاب الوضوء',
    'purification': 'كتاب الطهارة',
    'bathing': 'كتاب الغسل',
    'menstrual periods': 'كتاب الحيض',
    'menses': 'كتاب الحيض',
    'rubbing hands and feet with dust': 'كتاب التيمم',
    'tayammum': 'كتاب التيمم',
    'prayers': 'كتاب الصلاة',
    'prayer': 'كتاب الصلاة',
    'call to prayer': 'كتاب الأذان',
    'adhan': 'كتاب الأذان',
    'times of the prayers': 'كتاب مواقيت الصلاة',
    'friday prayer': 'كتاب الجمعة',
    'fear prayer': 'كتاب صلاة الخوف',
    'the two festivals': 'كتاب العيدين',
    'eid': 'كتاب العيدين',
    'eclipses': 'كتاب الكسوف',
    'eclipse': 'كتاب الكسوف',
    'prostration during quran recitation': 'كتاب سجود القرآن',
    'shortening the prayers': 'كتاب تقصير الصلاة والسفر',
    'prayer in congregation': 'كتاب صلاة الجماعة والإمامة',
    'night prayer': 'كتاب قيام الليل والتهجد',
    'tahajjud': 'كتاب التهجد وقيام الليل',
    'witr': 'كتاب الوتر',
    'supplication for rain': 'كتاب الاستسقاء',
    'istisqa': 'كتاب الاستسقاء',
    'funerals': 'كتاب الجنائز',
    'funeral': 'كتاب الجنائز',
    'zakat': 'كتاب الزكاة',
    'obligatory charity tax': 'كتاب الزكاة',
    'fasting': 'كتاب الصوم',
    'fasts': 'كتاب الصيام',
    'pilgrimage': 'كتاب الحج',
    'hajj': 'كتاب الحج',
    'umrah': 'كتاب العمرة',
    'retiring to a mosque for remembrance of allah': 'كتاب الاعتكاف',
    'itikaf': 'كتاب الاعتكاف',
    'sales and trade': 'كتاب البيوع',
    'sales': 'كتاب البيوع',
    'trade': 'كتاب التجارة والبيوع',
    'partnership': 'كتاب الشركة',
    'mortgaging': 'كتاب الرهن',
    'representation': 'كتاب الوكالة',
    'agriculture': 'كتاب المزارعة والمساقاة',
    'distribution of water': 'كتاب الشرب والمساقاة',
    'loans': 'كتاب الاستقراض والديون',
    'debts': 'كتاب الديون وأداء الحقوق',
    'lost things found by someone': 'كتاب اللقطة',
    'oppressions': 'كتاب المظالم والغصب',
    'gifts': 'كتاب الهبة وفضلها',
    'witnesses': 'كتاب الشهادات',
    'peacemaking': 'كتاب الصلح',
    'conditions': 'كتاب الشروط',
    'wills and testaments': 'كتاب الوصايا',
    'jihad': 'كتاب الجهاد والسير',
    'military expeditions': 'كتاب المغازي والسير',
    'virtues': 'كتاب المناقب والفضائل',
    'virtues of the companions': 'كتاب فضائل الصحابة رضي الله عنهم',
    'merits of the helpers in madinah': 'كتاب مناقب الأنصار',
    'prophetic commentary on the quran': 'كتاب تفسير القرآن',
    'tafsir': 'كتاب تفسير القرآن الكريم',
    'virtues of the quran': 'كتاب فضائل القرآن',
    'marriage': 'كتاب النكاح',
    'wedlock': 'كتاب النكاح',
    'divorce': 'كتاب الطلاق',
    'supporting the family': 'كتاب النفقات',
    'food': 'كتاب الأطعمة',
    'foods': 'كتاب الأطعمة',
    'meals': 'كتاب الأطعمة والضيافة',
    'sacrifice on occasion of birth': 'كتاب العقيقة',
    'hunting': 'كتاب الصيد والذبائح',
    'slaughtering': 'كتاب الذبائح',
    'al-adha festival sacrifice': 'كتاب الأضاحي',
    'drinks': 'كتاب الأشربة',
    'patients': 'كتاب المرضى والطب',
    'medicine': 'كتاب الطب والرقى',
    'dress': 'كتاب اللباس والزينة',
    'clothing': 'كتاب اللباس',
    'good manners': 'كتاب الأدب',
    'manners': 'كتاب الأدب والأخلاق',
    'asking permission': 'كتاب الاستئذان والسلام',
    'invocations': 'كتاب الدعوات والأذكار',
    'supplications': 'كتاب الدعاء والذكر',
    'to make the heart tender': 'كتاب الرقاق والزهد',
    'riqaq': 'كتاب الرقاق',
    'divine will': 'كتاب القدر',
    'destiny': 'كتاب القدر',
    'oaths and vows': 'كتاب الأيمان والنذور',
    'expiation for unfulfilled oaths': 'كتاب الكفارات',
    'laws of inheritance': 'كتاب الفرائض والمواريث',
    'punishments': 'كتاب الحدود',
    'blood money': 'كتاب الديات',
    'apostates': 'كتاب استتابة المرتدين والمعاندين',
    'coercion': 'كتاب الإكراه',
    'tricks': 'كتاب الحيل',
    'interpretation of dreams': 'كتاب تعبير الرؤيا',
    'dreams': 'كتاب الرؤيا',
    'afflictions and the end of the world': 'كتاب الفتن وأشراط الساعة',
    'tribulations': 'كتاب الفتن',
    'judgments': 'كتاب الأحكام والقضاء',
    'wishes': 'كتاب التمني',
    'holding fast to the quran and sunnah': 'كتاب الاعتصام بالكتاب والسنة',
    'monotheism': 'كتاب التوحيد والرد على الجهمية',
    'tawheed': 'كتاب التوحيد',
    'repentance': 'كتاب التوبة والاستغفار',
    'righteousness': 'كتاب البر والصلة والآداب',
    'descriptions of day of judgment': 'كتاب صفة القيامة والجنة والنار',
    'paradise and hell': 'كتاب صفة الجنة والنار',
    'the book of the virtues of the prophet': 'كتاب الشمائل النبوية الشريفة',
  };

  /// ترجمة اسم الباب إلى العربية إذا كان مسجلاً بالإنجليزية أو فارغاً
  static String resolveChapterName(String? nameAr, String? nameEn, int chapterNumber) {
    if (nameAr != null && nameAr.trim().isNotEmpty && !RegExp(r'^[a-zA-Z\s0-9.,_\-]+$').hasMatch(nameAr.trim())) {
      return nameAr.trim();
    }

    if (nameEn != null && nameEn.trim().isNotEmpty) {
      final cleanEn = nameEn
          .toLowerCase()
          .replaceAll('the book of ', '')
          .replaceAll('the book on ', '')
          .replaceAll('book of ', '')
          .replaceAll('book on ', '')
          .replaceAll('book ', '')
          .trim();

      if (_translations.containsKey(cleanEn)) {
        return _translations[cleanEn]!;
      }

      for (final entry in _translations.entries) {
        if (cleanEn.contains(entry.key) || entry.key.contains(cleanEn)) {
          return entry.value;
        }
      }
    }

    return 'الباب $chapterNumber';
  }
}
