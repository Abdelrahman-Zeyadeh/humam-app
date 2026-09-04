/// أنواع ومحتويات البطاقات التي يمكن تصميمها ومشاركتها
enum StoryContentType {
  ayah,
  hadith,
  dhikr,
  nameOfAllah,
  custom,
}

abstract class StoryContent {
  const StoryContent();

  StoryContentType get type;
  String get mainText;
  String get subText;
  String get sourceReference;
}

class AyahContent extends StoryContent {
  final int ayahId;
  final String text;
  final String surahName;
  final int ayahNumber;
  final String? tafsirText;
  final String? tafsirEditionName;

  const AyahContent({
    required this.ayahId,
    required this.text,
    required this.surahName,
    required this.ayahNumber,
    this.tafsirText,
    this.tafsirEditionName,
  });

  @override
  StoryContentType get type => StoryContentType.ayah;

  @override
  String get mainText => text;

  @override
  String get subText => tafsirText ?? '';

  @override
  String get sourceReference => 'سورة $surahName · آية $ayahNumber';
}

class HadithContent extends StoryContent {
  final String hadithText;
  final String narrator;
  final String sourceBook;
  final String? explanation;

  const HadithContent({
    required this.hadithText,
    required this.narrator,
    required this.sourceBook,
    this.explanation,
  });

  @override
  StoryContentType get type => StoryContentType.hadith;

  @override
  String get mainText => hadithText;

  @override
  String get subText => explanation ?? '';

  @override
  String get sourceReference => '$sourceBook · $narrator';
}

class DhikrContent extends StoryContent {
  final String dhikrText;
  final String category;
  final String virtue;
  final int count;

  const DhikrContent({
    required this.dhikrText,
    required this.category,
    required this.virtue,
    this.count = 1,
  });

  @override
  StoryContentType get type => StoryContentType.dhikr;

  @override
  String get mainText => dhikrText;

  @override
  String get subText => virtue;

  @override
  String get sourceReference => '$category · تكرار $count';
}

class NameOfAllahContent extends StoryContent {
  final String name;
  final String meaning;
  final String tadabbur;
  final String dua;

  const NameOfAllahContent({
    required this.name,
    required this.meaning,
    required this.tadabbur,
    required this.dua,
  });

  @override
  StoryContentType get type => StoryContentType.nameOfAllah;

  @override
  String get mainText => '﴿ $name ﴾';

  @override
  String get subText => meaning;

  @override
  String get sourceReference => 'أسماء الله الحسنى · دعاؤه: $dua';
}

class CustomTextContent extends StoryContent {
  final String text;
  final String title;
  final String author;

  const CustomTextContent({
    required this.text,
    required this.title,
    this.author = '',
  });

  @override
  StoryContentType get type => StoryContentType.custom;

  @override
  String get mainText => text;

  @override
  String get subText => title;

  @override
  String get sourceReference => author.isEmpty ? 'فائدة إيمانية' : author;
}
