import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../notifications/adhan_notification_service.dart';

class DailyHadithItem {
  const DailyHadithItem({
    required this.id,
    required this.matn,
    required this.narrator,
    required this.source,
    required this.grade,
    required this.fawaid,
    required this.category,
  });

  final int id;
  final String matn;
  final String narrator;
  final String source;
  final String grade;
  final List<String> fawaid;
  final String category;
}

final List<DailyHadithItem> kCuratedDailyHadiths = [
  // 1. الإخلاص والنية
  const DailyHadithItem(
    id: 1,
    matn: 'إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ، وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى، فَمَنْ كَانَتْ هِجْرَتُهُ إِلَى دُنْيَا يُصِيبُهَا، أَوْ إِلَى امْرَأَةٍ يَنْكِحُهَا، فَهِجْرَتُهُ إِلَى مَا هَاجَرَ إِلَيْهِ.',
    narrator: 'عمر بن الخطاب رضي الله عنه',
    source: 'صحيح البخاري (١)، صحيح مسلم (١٩٠٧)',
    grade: 'متفق عليه',
    category: 'الإخلاص والنية',
    fawaid: [
      'النية هي ميزان صحة وقبول الأعمال الظاهرة والباطنة.',
      'تفاضل الأعمال ومضاعفة أجورها يكون بحسب صدق النية في القلب.',
      'تحويل العادات اليومية المباحة إلى عبادات وقربات بحسن القصد.',
    ],
  ),
  const DailyHadithItem(
    id: 2,
    matn: 'إِنَّ اللَّهَ لَا يَنْظُرُ إِلَى صُوَرِكُمْ وَأَمْوَالِكُمْ، وَلَكِنْ يَنْظُرُ إِلَى قُلُوبِكُمْ وَأَعْمَالِكُمْ.',
    narrator: 'أبو هريرة رضي الله عنه',
    source: 'صحيح مسلم (٢٥٦٤)',
    grade: 'صحيح',
    category: 'الإخلاص والنية',
    fawaid: [
      'القلب هو موضع نظر الرب ومحل التقوى والإخلاص.',
      'العبرة عند الله بسلامة السرائر وصلاح الأعمال لا بالمظاهر والأموال.',
    ],
  ),
  const DailyHadithItem(
    id: 3,
    matn: 'مَنْ تَوَضَّأَ فَأَحْسَنَ الْوُضُوءَ خَرَجَتْ خَطَايَاهُ مِنْ جَسَدِهِ، حَتَّى تَخْرُجَ مِنْ تَحْتِ أَظْفَارِهِ.',
    narrator: 'عثمان بن عفان رضي الله عنه',
    source: 'صحيح مسلم (٢٤٥)',
    grade: 'صحيح',
    category: 'الصلاة والطهور',
    fawaid: [
      'إسباغ الوضوء وإتقانه سبب لمغفرة الذنوب وتكفير الخطايا.',
      'الطهور شطر الإيمان ونور لصاحبه يوم القيامة.',
    ],
  ),
  const DailyHadithItem(
    id: 4,
    matn: 'الصَّلَوَاتُ الْخَمْسُ، وَالْجُمْعَةُ إِلَى الْجُمْعَةِ، وَرَمَضَانُ إِلَى رَمَضَانَ، مُكَفِّرَاتٌ مَا بَيْنَهُنَّ إِذَا اجْتَنَبَ الْكَبَائِرَ.',
    narrator: 'أبو هريرة رضي الله عنه',
    source: 'صحيح مسلم (٢٣٣)',
    grade: 'صحيح',
    category: 'الصلاة والطهور',
    fawaid: [
      'المحافظة على الفرائض أعظم أسباب تكفير صغائر الذنوب والآثام.',
      'رحمة الله الواسعة بفتح أبواب المغفرة المتتالية لعباده.',
    ],
  ),
  const DailyHadithItem(
    id: 5,
    matn: 'مَنْ صَلَّى الْبَرْدَيْنِ دَخَلَ الْجَنَّةَ.',
    narrator: 'أبو موسى الأشعري رضي الله عنه',
    source: 'صحيح البخاري (٥٧٤)، صحيح مسلم (٦٣٥)',
    grade: 'متفق عليه',
    category: 'الصلاة والطهور',
    fawaid: [
      'البردان هما صلاتا الفجر والعصر.',
      'المحافظة عليهما دليل على صدق الإيمان وسبب لدخول الجنة والنجاة من النار.',
    ],
  ),
  const DailyHadithItem(
    id: 6,
    matn: 'مَنْ سَلَكَ طَرِيقًا يَلْتَمِسُ فِيهِ عِلْمًا، سَهَّلَ اللَّهُ لَهُ بِهِ طَرِيقًا إِلَى الْجَنَّةِ، وَمَا اجْتَمَعَ قَوْمٌ فِي بَيْتٍ مِنْ بُيُوتِ اللَّهِ يَتْلُونَ كِتَابَ اللَّهِ وَيَتَدَارَسُونَهُ بَيْنَهُمْ، إِلَّا نَزَلَتْ عَلَيْهِمُ السَّكِينَةُ...',
    narrator: 'أبو هريرة رضي الله عنه',
    source: 'صحيح مسلم (٢٦٩٩)',
    grade: 'صحيح',
    category: 'فضل القرآن والعلم',
    fawaid: [
      'طلب العلم الشرعي من أشرف العبادات وأقصر الطرق إلى الجنة.',
      'مجالس القرآن وتدارسه تنزل فيها السكينة وتغشاها الرحمة وتحفها الملائكة.',
    ],
  ),
  const DailyHadithItem(
    id: 7,
    matn: 'خَيْرُكُمْ مَنْ تَعَلَّمَ القُرْآنَ وَعَلَّمَهُ.',
    narrator: 'عثمان بن عفان رضي الله عنه',
    source: 'صحيح البخاري (٥٠٢٧)',
    grade: 'صحيح',
    category: 'فضل القرآن والعلم',
    fawaid: [
      'أفضل مراتب الأمة وأعلاها درجة هم أهل القرآن تعلماً وتعليماً وعملاً.',
      'الجمع بين نفع النفس بتعلم القرآن ونفع الغير بتعليمه.',
    ],
  ),
  const DailyHadithItem(
    id: 8,
    matn: 'اقْرَؤُوا القُرْآنَ فَإِنَّهُ يَأْتِي يَوْمَ القِيَامَةِ شَفِيعًا لِأَصْحَابِهِ.',
    narrator: 'أبو أمامة الباهلي رضي الله عنه',
    source: 'صحيح مسلم (٨٠٤)',
    grade: 'صحيح',
    category: 'فضل القرآن والعلم',
    fawaid: [
      'القرآن يشفع لأصحابه الملازمين لتلاوته وتدبره والعمل بأحكامه.',
      'الحث على مداومة قراءة الورد القرآني وعدم هجر المصحف.',
    ],
  ),
  const DailyHadithItem(
    id: 9,
    matn: 'الْمَاهِرُ بِالْقُرْآنِ مَعَ السَّفَرَةِ الْكِرَامِ الْبَرَرَةِ، وَالَّذِي يَقْرَأُ الْقُرْآنَ وَيَتَتَعْتَعُ فِيهِ، وَهُوَ عَلَيْهِ شَاقٌّ، لَهُ أَجْرَانِ.',
    narrator: 'عائشة رضي الله عنها',
    source: 'صحيح البخاري (٤٩٣٧)، صحيح مسلم (٧٩٨)',
    grade: 'متفق عليه',
    category: 'فضل القرآن والعلم',
    fawaid: [
      'منزلة الماهر بالقرآن مع الملائكة المقربين.',
      'بشارة عظيمة لمن يجد مشقة في القراءة بأن له أجرين: أجر التلاوة وأجر المشقة.',
    ],
  ),
  const DailyHadithItem(
    id: 10,
    matn: 'عَجَبًا لِأَمْرِ الْمُؤْمِنِ، إِنَّ أَمْرَهُ كُلَّهُ خَيْرٌ، وَلَيْسَ ذَاكَ لِأَحَدٍ إِلَّا لِلْمُؤْمِنِ، إِنْ أَصَابَتْهُ سَرَّاءُ شَكَرَ فَكَانَ خَيْرًا لَهُ، وَإِنْ أَصَابَتْهُ ضَرَّاءُ صَبَرَ فَكَانَ خَيْرًا لَهُ.',
    narrator: 'صهيب بن سنان رضي الله عنه',
    source: 'صحيح مسلم (٢٩٩٩)',
    grade: 'صحيح',
    category: 'الصبر واليقين',
    fawaid: [
      'المؤمن يتقلب دائماً بين مقامي الشكر والصبر، فكل أقداره خير له.',
      'طمأنينة القلب وراحة النفس باليقين في حكمة الله ورحمته.',
    ],
  ),
  const DailyHadithItem(
    id: 11,
    matn: 'احْفَظِ اللَّهَ يَحْفَظْكَ، احْفَظِ اللَّهَ تَجِدْهُ تُجَاهَكَ، إِذَا سَأَلْتَ فَاسْأَلِ اللَّهَ، وَإِذَا اسْتَعَنْتَ فَاسْتَعِنْ بِاللَّهِ...',
    narrator: 'عبد الله بن عباس رضي الله عنهما',
    source: 'جامع الترمذي (٢٥١٦)',
    grade: 'حسن صحيح',
    category: 'الصبر واليقين',
    fawaid: [
      'حفظ حدود الله وأوامره سبب لمعية الله وتوفيقه وحفظه للعبد.',
      'إخلاص التوكل والدعاء والاستعانة بالله وحده في جميع الشؤون.',
    ],
  ),
  const DailyHadithItem(
    id: 12,
    matn: 'مَا يُصِيبُ المُسْلِمَ، مِنْ نَصَبٍ وَلاَ وَصَبٍ، وَلاَ هَمٍّ وَلاَ حُزْنٍ وَلاَ أَذًى وَلاَ غَمٍّ، حَتَّى الشَّوْكَةِ يُشَاكُهَا، إِلَّا كَفَّرَ اللَّهُ بِهَا مِنْ خَطَايَاهُ.',
    narrator: 'أبو سعيد وأبو هريرة رضي الله عنهما',
    source: 'صحيح البخاري (٥٦٤١)، صحيح مسلم (٢٥٧٣)',
    grade: 'متفق عليه',
    category: 'الصبر واليقين',
    fawaid: [
      'كل ألم أو غم أو تعب يمر به المسلم كفارة لذنوبه ورفعة لدرجاته.',
      'استشعار الأجر يخفف وطأة المصائب والمحن.',
    ],
  ),
  const DailyHadithItem(
    id: 13,
    matn: 'اتَّقِ اللَّهَ حَيْثُمَا كُنْتَ، وَأَتْبِعِ السَّيِّئَةَ الْحَسَنَةَ تَمْحُهَا، وَخَالِقِ النَّاسَ بِخُلُقٍ حَسَنٍ.',
    narrator: 'أبو ذر ومعاذ بن جبل رضي الله عنهما',
    source: 'جامع الترمذي (١٩٨٧)',
    grade: 'حسن',
    category: 'حسن الخلق والرفق',
    fawaid: [
      'التقوى ومراقبة الله في السر والعلن في كل مكان وزمان.',
      'الحسنات والاستغفار يمحوان السيئات والخطايا.',
      'حسن الخلق مع الخلق من أعظم أسباب نيل محبة الله والقرب من النبي ﷺ.',
    ],
  ),
  const DailyHadithItem(
    id: 14,
    matn: 'إِنَّ مِنْ أَحَبِّكُمْ إِلَيَّ وَأَقْرَبِكُمْ مِنِّي مَجْلِسًا يَوْمَ القِيَامَةِ أَحَاسِنَكُمْ أَخْلَاقًا.',
    narrator: 'جابر بن عبد الله رضي الله عنهما',
    source: 'جامع الترمذي (٢٠١٨)',
    grade: 'حسن',
    category: 'حسن الخلق والرفق',
    fawaid: [
      'حسن الخلق يرفع صاحبه إلى أعلى المنازل في الجنة بجوار رسول الله ﷺ.',
      'بشاشة الوجه وطيب الكلام وسعة الصدر أثقل ما يوضع في الميزان.',
    ],
  ),
  const DailyHadithItem(
    id: 15,
    matn: 'إِنَّ الرِّفْقَ لَا يَكُونُ فِي شَيْءٍ إِلَّا زَانَهُ، وَلَا يُنْزَعُ مِنْ شَيْءٍ إِلَّا شَانَهُ.',
    narrator: 'عائشة رضي الله عنها',
    source: 'صحيح مسلم (٢٥٩٤)',
    grade: 'صحيح',
    category: 'حسن الخلق والرفق',
    fawaid: [
      'الرفق واللين يزينان الأقوال والأفعال والمعاملات كلها.',
      'العنف والشدة يفسدان الأمور ويفقدانها بركتها وجمالها.',
    ],
  ),
  const DailyHadithItem(
    id: 16,
    matn: 'لَيْسَ الشَّدِيدُ بِالصُّرَعَةِ، إِنَّمَا الشَّدِيدُ الَّذِي يَمْلِكُ نَفْسَهُ عِنْدَ الغَضَبِ.',
    narrator: 'أبو هريرة رضي الله عنه',
    source: 'صحيح البخاري (٦١١٤)، صحيح مسلم (٢٦٠٩)',
    grade: 'متفق عليه',
    category: 'حسن الخلق والرفق',
    fawaid: [
      'القوة الحقيقية تكمن في ضبط النفس والتحكم في المشاعر عند الغضب.',
      'مجاهدة النفس وكظم الغيظ من صفات المتقين المحسنين.',
    ],
  ),
  const DailyHadithItem(
    id: 17,
    matn: 'رَغِمَ أَنْفُهُ، ثُمَّ رَغِمَ أَنْفُهُ، ثُمَّ رَغِمَ أَنْفُهُ، قِيلَ: مَنْ يَا رَسُولَ اللهِ؟ قَالَ: مَنْ أَدْرَكَ وَالِدَيْهِ عِنْدَ الْكِبَرِ، أَحَدَهُمَا أَوْ كِلَيْهِمَا، ثُمَّ لَمْ يَدْخُلِ الْجَنَّةَ.',
    narrator: 'أبو هريرة رضي الله عنه',
    source: 'صحيح مسلم (٢٥٥١)',
    grade: 'صحيح',
    category: 'بر الوالدين وصلة الرحم',
    fawaid: [
      'بر الوالدين عند الكبر من أوسع وأعظم أبواب الجنة.',
      'التحذير الشديد من التقصير في حق الوالدين أو إهمال رعايتهما.',
    ],
  ),
  const DailyHadithItem(
    id: 18,
    matn: 'مَنْ أَحَبَّ أَنْ يُبْسَطَ لَهُ فِي رِزْقِهِ، وَيُنْسَأَ لَهُ فِي أَثَرِهِ، فَلْيَصِلْ رَحِمَهُ.',
    narrator: 'أنس بن مالك رضي الله عنه',
    source: 'صحيح البخاري (٥٩٨٦)، صحيح مسلم (٢٥٥٧)',
    grade: 'متفق عليه',
    category: 'بر الوالدين وصلة الرحم',
    fawaid: [
      'صلة الرحم سبب مباشر للبركة في الرزق وطول العمر وحسن الذكر.',
      'الصلة تكون بالزيارة والاتصال والإحسان والقول الطيب وتفقد الأحوال.',
    ],
  ),
  const DailyHadithItem(
    id: 19,
    matn: 'لَيْسَ الوَاصِلُ بِالمُكَافِئِ، وَلَكِنِ الوَاصِلُ الَّذِي إِذَا قُطِعَتْ رَحِمُهُ وَصَلَهَا.',
    narrator: 'عبد الله بن عمرو رضي الله عنهما',
    source: 'صحيح البخاري (٥٩٩١)',
    grade: 'صحيح',
    category: 'بر الوالدين وصلة الرحم',
    fawaid: [
      'الواصل الحقيقي هو من يصل من قطعه ويحسن إلى من أساء إليه ابتغاء وجه الله.',
      'تطهير القلب من الضغائن ومقابلة القطيعة بالإحسان.',
    ],
  ),
  const DailyHadithItem(
    id: 20,
    matn: 'مَنْ كَانَ يُؤْمِنُ بِاللَّهِ وَاليَوْمِ الآخِرِ فَلْيَقُلْ خَيْرًا أَوْ لِيَصْمُتْ، وَمَنْ كَانَ يُؤْمِنُ بِاللَّهِ وَاليَوْمِ الآخِرِ فَلْيُكْرِمْ جَارَهُ، وَمَنْ كَانَ يُؤْمِنُ بِاللَّهِ وَاليَوْمِ الآخِرِ فَلْيُكْرِمْ ضَيْفَهُ.',
    narrator: 'أبو هريرة رضي الله عنه',
    source: 'صحيح البخاري (٦٠١٨)، صحيح مسلم (٤٧)',
    grade: 'متفق عليه',
    category: 'حفظ اللسان والآداب',
    fawaid: [
      'حفظ اللسان والتثبت قبل الكلام من كمال الإيمان وثمار التقوى.',
      'إكرام الجار وحسن معاملته ورعاية حقوق الضيف.',
    ],
  ),
  const DailyHadithItem(
    id: 21,
    matn: 'الْمُسْلِمُ مَنْ سَلِمَ الْمُسْلِمُونَ مِنْ لِسَانِهِ وَيَدِهِ، وَالْمُهَاجِرُ مَنْ هَجَرَ مَا نَهَى اللَّهُ عَنْهُ.',
    narrator: 'عبد الله بن عمرو رضي الله عنهما',
    source: 'صحيح البخاري (١٠)، صحيح مسلم (٤٠)',
    grade: 'متفق عليه',
    category: 'حفظ اللسان والآداب',
    fawaid: [
      'حقيقة الإسلام تتجلى في كف الأذى عن الناس قولاً وفعلاً.',
      'الهجرة المعنوية بترك المحرمات والذنوب واجبة على كل مسلم.',
    ],
  ),
  const DailyHadithItem(
    id: 22,
    matn: 'كَلِمَتَانِ خَفِيفَتَانِ عَلَى اللِّسَانِ، ثَقِيلَتَانِ فِي المِيزَانِ، حَبِيبَتَانِ إِلَى الرَّحْمَنِ: سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، سُبْحَانَ اللَّهِ العَظِيمِ.',
    narrator: 'أبو هريرة رضي الله عنه',
    source: 'صحيح البخاري (٦٤٠٦)، صحيح مسلم (٢٦٩٤)',
    grade: 'متفق عليه',
    category: 'فضل الذكر والدعاء',
    fawaid: [
      'مضاعفة الأجور على كلمات يسيرة وسهلة الترديد في كل وقت.',
      'إثبات محبة الرحمن لأهل الذكر والتسبيح.',
    ],
  ),
  const DailyHadithItem(
    id: 23,
    matn: 'مَثَلُ الَّذِي يَذْكُرُ رَبَّهُ وَالَّذِي لاَ يَذْكُرُ رَبَّهُ، مَثَلُ الحَيِّ وَالمَيِّتِ.',
    narrator: 'أبو موسى الأشعري رضي الله عنه',
    source: 'صحيح البخاري (٦٤٠٧)، صحيح مسلم (٧٧٩)',
    grade: 'متفق عليه',
    category: 'فضل الذكر والدعاء',
    fawaid: [
      'الذكر حياة للقلوب والروح، والغفلة موت وجفاف وبؤس.',
      'عمارة الأوقات بالتسبيح والاستغفار يورث القلب نضارة ونوراً.',
    ],
  ),
  const DailyHadithItem(
    id: 24,
    matn: 'أَحَبُّ الكَلاَمِ إِلَى اللهِ أَرْبَعٌ: سُبْحَانَ اللهِ، وَالحَمْدُ لِلَّهِ، وَلاَ إِلَهَ إِلاَّ اللهُ، وَاللهُ أَكْبَرُ، لاَ يَضُرُّكَ بِأَيِّهِنَّ بَدَأْتَ.',
    narrator: 'سمرة بن جندب رضي الله عنه',
    source: 'صحيح مسلم (٢١٣٧)',
    grade: 'صحيح',
    category: 'فضل الذكر والدعاء',
    fawaid: [
      'هذه الكلمات الأربع هي الباقيات الصالحات وأحب الكلام إلى الله تعالى.',
      'غرس الجنة وكنوز من كنوز العرش.',
    ],
  ),
  const DailyHadithItem(
    id: 25,
    matn: 'الدُّعَاءُ هُوَ العِبَادَةُ.',
    narrator: 'النعمان بن بشير رضي الله عنهما',
    source: 'جامع الترمذي (٢٩٦٩)، سنن أبي داود (١٤٧٩)',
    grade: 'صحيح',
    category: 'فضل الذكر والدعاء',
    fawaid: [
      'الدعاء هو مخ العبادة وأصل التذلل والافتقار إلى الله.',
      'اليقين في الإجابة وعدم استعجال النتائج.',
    ],
  ),
  const DailyHadithItem(
    id: 26,
    matn: 'مَا نَقَصَتْ صَدَقَةٌ مِنْ مَالٍ، وَمَا زَادَ اللَّهُ عَبْدًا بِعَفْوٍ إِلَّا عِزًّا، وَمَا تَوَاضَعَ أَحَدٌ لِلَّهِ إِلَّا رَفَعَهُ اللَّهُ.',
    narrator: 'أبو هريرة رضي الله عنه',
    source: 'صحيح مسلم (٢٥٨٨)',
    grade: 'صحيح',
    category: 'الصدقة والإنفاق',
    fawaid: [
      'الصدقة تبارك المال وتنميه وتدفع البلاء عن صاحبه.',
      'العفو والصفح يورثان العز والكرامة، والتواضع لله رفعة في الدنيا والآخرة.',
    ],
  ),
  const DailyHadithItem(
    id: 27,
    matn: 'كُلُّ سُلاَمَى مِنَ النَّاسِ عَلَيْهِ صَدَقَةٌ، كُلَّ يَوْمٍ تَطْلُعُ فِيهِ الشَّمْسُ: تَعْدِلُ بَيْنَ الاِثْنَيْنِ صَدَقَةٌ، وَتُعِينُ الرَّجُلَ فِي دَابَّتِهِ فَتَحْمِلُهُ عَلَيْهَا أَوْ تَرْفَعُ لَهُ عَلَيْهَا مَتَاعَهُ صَدَقَةٌ، وَالكَلِمَةُ الطَّيِّبَةُ صَدَقَةٌ...',
    narrator: 'أبو هريرة رضي الله عنه',
    source: 'صحيح البخاري (٢٩٨٩)، صحيح مسلم (١٠٠٩)',
    grade: 'متفق عليه',
    category: 'الصدقة والإنفاق',
    fawaid: [
      'أبواب الصدقة والمعروف واسعة تشمل كل نفع وإعانة وإصلاح بين الناس.',
      'ركعتا الضحى تجزئان عن شكر جميع مفاصل الجسد (٣٦٠ مفصلاً).',
    ],
  ),
  const DailyHadithItem(
    id: 28,
    matn: 'السَّاعِي عَلَى الأَرْمَلَةِ وَالمِسْكِينِ، كَالْمُجَاهِدِ فِي سَبِيلِ اللَّهِ، أَوِ القَائِمِ اللَّيْلَ الصَّائِمِ النَّهَارَ.',
    narrator: 'أبو هريرة رضي الله عنه',
    source: 'صحيح البخاري (٥٣٥٣)، صحيح مسلم (٢٩٨٢)',
    grade: 'متفق عليه',
    category: 'الصدقة والإنفاق',
    fawaid: [
      'عظم أجر كفالة الأرامل والمساكين وقضاء حوائج الضعفاء.',
      'كسب أجر قيام الليل وصيام النهار بالعمل الخيري ونفع المحتاجين.',
    ],
  ),
  const DailyHadithItem(
    id: 29,
    matn: 'التَّائِبُ مِنَ الذَّنْبِ، كَمَنْ لَا ذَنْبَ لَهُ.',
    narrator: 'عبد الله بن مسعود رضي الله عنه',
    source: 'سنن ابن ماجه (٤٢٥٠)',
    grade: 'حسن',
    category: 'التوبة والاستغفار',
    fawaid: [
      'فضل التوبة الصادقة وأنها تجب ما قبلها وتمحو آثار الذنب بالكلية.',
      'عدم القنوط من رحمة الله وفتح باب الرجاء دائماً.',
    ],
  ),
  const DailyHadithItem(
    id: 30,
    matn: 'وَاللَّهِ إِنِّي لَأَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ فِي اليَوْمِ أَكْثَرَ مِنْ سَبْعِينَ مَرَّةً.',
    narrator: 'أبو هريرة رضي الله عنه',
    source: 'صحيح البخاري (٦٣٠٧)',
    grade: 'صحيح',
    category: 'التوبة والاستغفار',
    fawaid: [
      'ملازمة النبي ﷺ للاستغفار وهو المغفور له ما تقدم من ذنبه وما تأخر.',
      'الاستغفار مفتاح الفرج وسعة الرزق وراحة البال وصلاح الأحوال.',
    ],
  ),
  const DailyHadithItem(
    id: 31,
    matn: 'عَلَيْكُمْ بِالصِّدْقِ، فَإِنَّ الصِّدْقَ يَهْدِي إِلَى البِرِّ، وَإِنَّ البِرَّ يَهْدِي إِلَى الجَنَّةِ...',
    narrator: 'عبد الله بن مسعود رضي الله عنه',
    source: 'صحيح البخاري (٦٠٩٤)، صحيح مسلم (٢٦٠٧)',
    grade: 'متفق عليه',
    category: 'الأمانة والصدق',
    fawaid: [
      'الصدق طريق موصل إلى كل خير وبر وسبب لدخول الجنة.',
      'التحذير من الكذب وعواقبه الوخيمة على القلب والمجتمع.',
    ],
  ),
  const DailyHadithItem(
    id: 32,
    matn: 'آيَةُ المُنَافِقِ ثَلاَثٌ: إِذَا حَدَّثَ كَذَبَ، وَإِذَا وَعَدَ أَخْلَفَ، وَإِذَا اؤْتُمِنَ خَانَ.',
    narrator: 'أبو هريرة رضي الله عنه',
    source: 'صحيح البخاري (٣٣)، صحيح مسلم (٥٩)',
    grade: 'متفق عليه',
    category: 'الأمانة والصدق',
    fawaid: [
      'التحذير من خصال النفاق العملية ووجوب حفظ الأمانة والوفاء بالعهود.',
      'الصدق في الحديث وإنجاز الوعد من أركان المروءة والإيمان.',
    ],
  ),
  const DailyHadithItem(
    id: 33,
    matn: 'لاَ يُؤْمِنُ أَحَدُكُمْ، حَتَّى يُحِبَّ لِأَخِيهِ مَا يُحِبُّ لِنَفْسِهِ.',
    narrator: 'أنس بن مالك رضي الله عنه',
    source: 'صحيح البخاري (١٣)، صحيح مسلم (٤٥)',
    grade: 'متفق عليه',
    category: 'محبة المسلمين والأخوة',
    fawaid: [
      'سلامة الصدر ومحبة الخير للآخرين من أمارات كمال الإيمان.',
      'طرد الحسد والبغضاء والحرص على نفع إخوانك المسلمين.',
    ],
  ),
  const DailyHadithItem(
    id: 34,
    matn: 'مَثَلُ المُؤْمِنِينَ فِي تَوَادِّهِمْ، وَتَرَاحُمِهِمْ، وَتَعَاطُفِهِمْ مَثَلُ الجَسَدِ إِذَا اشْتَكَى مِنْهُ عُضْوٌ تَدَاعَى لَهُ سَائِرُ الجَسَدِ بِالسَّهَرِ وَالحُمَّى.',
    narrator: 'النعمان بن بشير رضي الله عنهما',
    source: 'صحيح البخاري (٦٠١١)، صحيح مسلم (٢٥٨٦)',
    grade: 'متفق عليه',
    category: 'محبة المسلمين والأخوة',
    fawaid: [
      'وحدة الأمة الإسلامية وتلاحم أفرادها في السراء والضراء.',
      'الشعور بآلام المسلمين وإغاثتهم والدعاء لهم في كل مكان.',
    ],
  ),
  const DailyHadithItem(
    id: 35,
    matn: 'مَنْ نَفَّسَ عَنْ مُؤْمِنٍ كُرْبَةً مِنْ كُرَبِ الدُّنْيَا، نَفَّسَ اللهُ عَنْهُ كُرْبَةً مِنْ كُرَبِ يَوْمِ الْقِيَامَةِ، وَمَنْ يَسَّرَ عَلَى مُعْسِرٍ، يَسَّرَ اللهُ عَلَيْهِ فِي الدُّنْيَا وَالْآخِرَةِ...',
    narrator: 'أبو هريرة رضي الله عنه',
    source: 'صحيح مسلم (٢٦٩٩)',
    grade: 'صحيح',
    category: 'محبة المسلمين والأخوة',
    fawaid: [
      'الجزاء من جنس العمل، فمن فرج عن عباد الله فرج الله عنه كربات القيامة.',
      'الله في عون العبد ما كان العبد في عون أخيه.',
    ],
  ),
  const DailyHadithItem(
    id: 36,
    matn: 'ثَلَاثٌ مَنْ كُنَّ فِيهِ وَجَدَ حَلَاوَةَ الإِيمَانِ: أَنْ يَكُونَ اللَّهُ وَرَسُولُهُ أَحَبَّ إِلَيْهِ مِمَّا سِوَاهُمَا، وَأَنْ يُحِبَّ المَرْءَ لاَ يُحِبُّهُ إِلَّا لِلَّهِ، وَأَنْ يَكْرَهَ أَنْ يَعُودَ فِي الكُفْرِ كَمَا يَكْرَهُ أَنْ يُقْذَفَ فِي النَّارِ.',
    narrator: 'أنس بن مالك رضي الله عنه',
    source: 'صحيح البخاري (١٦)، صحيح مسلم (٤٣)',
    grade: 'متفق عليه',
    category: 'الإخلاص والنية',
    fawaid: [
      'للإيمان حلاوة ولذة تفوق كل اللذات يجدها من امتلأ قلبه بمحبة الله ورسوله.',
      'الحب في الله والبغض في الله من أوثق عرى الإيمان.',
    ],
  ),
];

class DailyHadithScreen extends ConsumerStatefulWidget {
  const DailyHadithScreen({super.key});

  @override
  ConsumerState<DailyHadithScreen> createState() => _DailyHadithScreenState();
}

class _DailyHadithScreenState extends ConsumerState<DailyHadithScreen> {
  int _selectedIndex = 0;
  String _selectedCategory = 'الكل';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // تدوير يومي موثوق حسب أيام السنة
    final dayKey = (now.year * 366) + (now.month * 31) + now.day;
    _selectedIndex = dayKey % kCuratedDailyHadiths.length;
  }

  List<DailyHadithItem> get _filteredHadiths {
    return kCuratedDailyHadiths.where((h) {
      final matchesCat =
          _selectedCategory == 'الكل' || h.category == _selectedCategory;
      final matchesQuery = _searchQuery.isEmpty ||
          h.matn.contains(_searchQuery) ||
          h.narrator.contains(_searchQuery) ||
          h.source.contains(_searchQuery) ||
          h.fawaid.any((f) => f.contains(_searchQuery));
      return matchesCat && matchesQuery;
    }).toList();
  }

  void _pickRandomHadith() {
    HapticFeedback.mediumImpact();
    final list = _filteredHadiths;
    if (list.isEmpty) return;
    final r = math.Random().nextInt(list.length);
    final target = list[r];
    setState(() {
      _selectedIndex = kCuratedDailyHadiths.indexOf(target);
    });
  }

  void _shareHadith(DailyHadithItem hadith) {
    final text = '📜 حديث اليوم:\n\n'
        '«${hadith.matn}»\n\n'
        '🎙️ الراوي: ${hadith.narrator}\n'
        '📚 المصدر: ${hadith.source} (${hadith.grade})\n\n'
        '💡 من فوائد الحديث:\n'
        '${hadith.fawaid.map((f) => '• $f').join('\n')}\n\n'
        'تطبيق هُمَام 🕌';
    SharePlus.instance.share(ShareParams(text: text));
  }

  void _copyHadith(DailyHadithItem hadith) {
    final text = '«${hadith.matn}»\n[${hadith.source}]';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ الحديث الشريف إلى الحافظة ✨'),
        backgroundColor: Color(0xFF1B8A72),
      ),
    );
  }

  void _showAllHadithsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (_, scrollCtrl) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1B232E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: StatefulBuilder(
                      builder: (ctx, setSheetState) {
                        return Container(
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            onChanged: (v) {
                              setSheetState(() {});
                              setState(() => _searchQuery = v);
                            },
                            decoration: const InputDecoration(
                              hintText: 'ابحث في المتن أو الراوي أو المصدر...',
                              hintStyle: TextStyle(fontSize: 12),
                              prefixIcon: Icon(Icons.search, size: 18),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollCtrl,
                      itemCount: _filteredHadiths.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                      itemBuilder: (ctx, i) {
                        final item = _filteredHadiths[i];
                        final origIndex = kCuratedDailyHadiths.indexOf(item);
                        final isSel = origIndex == _selectedIndex;
                        return ListTile(
                          selected: isSel,
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor: isSel
                                ? themeAccent(context)
                                : (isDark ? Colors.white12 : Colors.black12),
                            child: Text(
                              '${item.id}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSel ? Colors.white : null,
                              ),
                            ),
                          ),
                          title: Text(
                            item.matn,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${item.category} · ${item.source}',
                            style: const TextStyle(fontSize: 10.5),
                          ),
                          onTap: () {
                            setState(() => _selectedIndex = origIndex);
                            Navigator.of(ctx).pop();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final hadith = kCuratedDailyHadiths[_selectedIndex];

    final categories = [
      'الكل',
      'الإخلاص والنية',
      'الصلاة والطهور',
      'فضل القرآن والعلم',
      'الصبر واليقين',
      'حسن الخلق والرفق',
      'بر الوالدين وصلة الرحم',
      'حفظ اللسان والآداب',
      'فضل الذكر والدعاء',
      'الصدقة والإنفاق',
      'التوبة والاستغفار',
      'الأمانة والصدق',
      'محبة المسلمين والأخوة',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('حديث اليوم والفوائد النبوية'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt_rounded),
            tooltip: 'فهرس الأحاديث',
            onPressed: _showAllHadithsSheet,
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'مشاركة',
            onPressed: () => _shareHadith(hadith),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // شريط الفئات السريعة
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, idx) {
                final cat = categories[idx];
                final isSelected = cat == _selectedCategory;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                  selectedColor: themeAccent(context),
                  showCheckmark: false,
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _selectedCategory = cat;
                        final filtered = _filteredHadiths;
                        if (filtered.isNotEmpty && !filtered.contains(hadith)) {
                          _selectedIndex = kCuratedDailyHadiths.indexOf(filtered.first);
                        }
                      });
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // شريط التنقل بين الأحاديث وزر الحديث العشوائي
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton.filledTonal(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'الحديث السابق',
                onPressed: _selectedIndex > 0
                    ? () => setState(() => _selectedIndex--)
                    : null,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickRandomHadith,
                    icon: const Icon(Icons.shuffle_rounded, size: 16),
                    label: const Text('حديث آخر', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: themeAccent(context).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: themeAccent(context).withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '${hadith.id} / ${kCuratedDailyHadiths.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: themeAccent(context),
                      ),
                    ),
                  ),
                ],
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'الحديث التالي',
                onPressed: _selectedIndex < kCuratedDailyHadiths.length - 1
                    ? () => setState(() => _selectedIndex++)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // كرت متن الحديث الرئيسي
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2836) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark ? AppColors.lineDark : AppColors.line,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: themeAccent(context).withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.menu_book_rounded, color: themeAccent(context), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'عن ${hadith.narrator}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: onSurface.withValues(alpha: 0.8),
                            ),
                          ),
                          Text(
                            'قال رسول الله ﷺ:',
                            style: TextStyle(
                              fontSize: 12,
                              color: onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '« ${hadith.matn} »',
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    fontSize: 16.5,
                    height: 1.8,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Cairo',
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '📚 ${hadith.source} · [${hadith.grade}]',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_outlined, size: 18),
                      tooltip: 'نسخ الحديث',
                      onPressed: () => _copyHadith(hadith),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // الفوائد والدروس المستنبطة
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B232E) : const Color(0xFFFAF7EE),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFD4AF37).withValues(alpha: isDark ? 0.25 : 0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.lightbulb_outline, color: Color(0xFFC89218), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'فوائد وتأملات نبوية',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFC89218),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (final (i, item) in hadith.fawaid.indexed) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${i + 1}. ',
                          style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFC89218)),
                        ),
                        Expanded(
                          child: Text(
                            item,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.55,
                              color: onSurface.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // كرت ضبط إشعار حديث اليوم
          Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.notifications_active_outlined, color: themeAccent(context)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'إشعار حديث اليوم',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                            ),
                            Text(
                              'يصلك يومياً حديث شريف مع شرحه في موعده المحدد',
                              style: TextStyle(fontSize: 11, color: onSurface.withValues(alpha: 0.6)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            await AdhanNotificationService.instance.requestPermissions();
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('تم تفعيل التذكير اليومي بحديث اليوم بنجاح 🔔'),
                                backgroundColor: Color(0xFF1B8A72),
                              ),
                            );
                          },
                          icon: const Icon(Icons.alarm_on, size: 16),
                          label: const Text('تفعيل التنبيه اليومي (١:٠٠ م)', style: TextStyle(fontSize: 11.5)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
