/// أصوات أذان مختارة قابلة للتفعيل بإشعارات دخول وقت الصلاة.
class AdhanVoice {
  const AdhanVoice({
    required this.id,
    required this.label,
    this.subLabel,
    this.assetPath,
    this.remoteUrl,
    this.rawResource,
  });

  final String id;
  final String label;
  final String? subLabel;
  final String? assetPath;
  final String? remoteUrl;
  final String? rawResource;

  bool get isSystemDefault => id == 'system';
  String? get notificationSoundResource => rawResource ?? (assetPath != null ? id : null);
}

/// قائمة المؤذنين المعتمدة في هُمَام بأصواتهم الحقيقية والمستقلة (مدمجة محلياً 100%)
const List<AdhanVoice> kAdhanVoices = [
  AdhanVoice(
    id: 'adhan_sunbul',
    label: 'الشيخ عمر بن نبيل سنبل',
    subLabel: 'مؤذن المسجد النبوي الشريف - أداء مدني حجازي عريق',
    assetPath: 'assets/audio/adhan/adhan_sunbul.mp3',
    rawResource: 'adhan_sunbul',
  ),
  AdhanVoice(
    id: 'adhan_makkah',
    label: 'الشيخ علي بن أحمد ملا',
    subLabel: 'شيخ مؤذني المسجد الحرام (صوت مكة المكرمة)',
    assetPath: 'assets/audio/adhan/adhan_makkah.mp3',
    rawResource: 'adhan_makkah',
  ),
  AdhanVoice(
    id: 'adhan_madinah',
    label: 'أذان المسجد النبوي الشريف',
    subLabel: 'المدينة المنورة - أذان مدني خاشع ومهيب',
    assetPath: 'assets/audio/adhan/adhan_madinah.mp3',
    rawResource: 'adhan_madinah',
  ),
  AdhanVoice(
    id: 'adhan_aqsa',
    label: 'أذان المسجد الأقصى المبارك',
    subLabel: 'القدس الشريف - أذان فلسطيني عريق',
    assetPath: 'assets/audio/adhan/adhan_aqsa.mp3',
    rawResource: 'adhan_aqsa',
  ),
  AdhanVoice(
    id: 'adhan_alafasy',
    label: 'الشيخ مشاري راشد العفاسي',
    subLabel: 'أذان دولة الكويت - نبرة شجية عذبة ومميزة',
    assetPath: 'assets/audio/adhan/adhan_alafasy.mp3',
    rawResource: 'adhan_alafasy',
  ),
  AdhanVoice(
    id: 'adhan_abdulbasit',
    label: 'الشيخ عبد الباسط عبد الصمد',
    subLabel: 'أذان مصر التاريخي الخالد من رحاب الأزهر الشريف',
    assetPath: 'assets/audio/adhan/adhan_abdulbasit.mp3',
    rawResource: 'adhan_abdulbasit',
  ),
  AdhanVoice(
    id: 'adhan_qatami',
    label: 'الشيخ ناصر القطامي',
    subLabel: 'أذان نجد بنبرة مؤثرة وخشوع تام',
    assetPath: 'assets/audio/adhan/adhan_qatami.mp3',
    rawResource: 'adhan_qatami',
  ),
  AdhanVoice(
    id: 'adhan_surayhi',
    label: 'الشيخ عبد المجيد السريحي',
    subLabel: 'مؤذن مسجد قباء والمسجد النبوي الشريف',
    assetPath: 'assets/audio/adhan/adhan_surayhi.mp3',
    rawResource: 'adhan_surayhi',
  ),
  AdhanVoice(
    id: 'adhan_qassas',
    label: 'الشيخ محمد بن مروان قصاص',
    subLabel: 'أذان ندي وهادئ ومريح للقلوب',
    assetPath: 'assets/audio/adhan/adhan_qassas.mp3',
    rawResource: 'adhan_qassas',
  ),
  AdhanVoice(
    id: 'adhan_saqqaf',
    label: 'الشيخ هاشم السقاف',
    subLabel: 'أذان حجازي خاشع وروحاني',
    assetPath: 'assets/audio/adhan/adhan_saqqaf.m4a',
    rawResource: 'adhan_saqqaf',
  ),
  AdhanVoice(
    id: 'system',
    label: 'صوت الإشعار الافتراضي للنظام',
    subLabel: 'نغمة الهاتف الأساسية بدون صوت أذان',
  ),
];

AdhanVoice adhanVoiceById(String id) =>
    kAdhanVoices.firstWhere((v) => v.id == id, orElse: () => kAdhanVoices.first);
