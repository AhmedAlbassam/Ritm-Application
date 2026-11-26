import Foundation

/// A motivational quote in both English and Arabic.
struct DailyQuote: Hashable {
    let english: String
    let englishSource: String
    let arabic: String
    let arabicSource: String

    /// True when the app is running in Arabic.
    static var isArabic: Bool {
        (Bundle.main.preferredLocalizations.first ?? "en").hasPrefix("ar")
    }

    var text: String { Self.isArabic ? arabic : english }
    var source: String { Self.isArabic ? arabicSource : englishSource }

    /// The same quote for everyone on a given calendar day, a new one each day.
    static func forDay(_ date: Date = .now) -> DailyQuote {
        let reference = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 1)) ?? .distantPast
        let dayNumber = max(0, Calendar.current.numberOfDays(from: reference, to: date))
        return all[dayNumber % all.count]
    }

    /// Index used to pick the card's color theme for the day.
    static func themeIndex(for date: Date = .now) -> Int {
        Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 0
    }

    static let all: [DailyQuote] = [
        DailyQuote(
            english: "The most beloved of deeds to God are those done consistently, even if they are small.",
            englishSource: "Prophet Muhammad ﷺ (Bukhari & Muslim)",
            arabic: "أحبُّ الأعمال إلى الله أدومُها وإن قلّ.",
            arabicSource: "حديث شريف — متفق عليه"
        ),
        DailyQuote(
            english: "A journey of a thousand miles begins with a single step.",
            englishSource: "Lao Tzu",
            arabic: "رحلة الألف ميل تبدأ بخطوة واحدة.",
            arabicSource: "لاو تسو"
        ),
        DailyQuote(
            english: "Whoever strives shall find, and whoever sows shall reap.",
            englishSource: "Arabic proverb",
            arabic: "من جدّ وجد، ومن زرع حصد.",
            arabicSource: "مثل عربي"
        ),
        DailyQuote(
            english: "We are what we repeatedly do. Excellence, then, is not an act, but a habit.",
            englishSource: "Will Durant",
            arabic: "نحن ما نفعله مرارًا وتكرارًا، فالتميّز ليس فعلًا بل عادة.",
            arabicSource: "ويل ديورانت"
        ),
        DailyQuote(
            english: "Resolve comes in the measure of the resolute.",
            englishSource: "Al-Mutanabbi",
            arabic: "على قدر أهل العزم تأتي العزائمُ.",
            arabicSource: "المتنبي"
        ),
        DailyQuote(
            english: "Motivation is what gets you started. Habit is what keeps you going.",
            englishSource: "Jim Ryun",
            arabic: "الحماس هو ما يجعلك تبدأ، والعادة هي ما يجعلك تستمر.",
            arabicSource: "جيم ريون"
        ),
        DailyQuote(
            english: "Patience is the key to relief.",
            englishSource: "Arabic proverb",
            arabic: "الصبرُ مفتاحُ الفرج.",
            arabicSource: "مثل عربي"
        ),
        DailyQuote(
            english: "Success is the sum of small efforts, repeated day in and day out.",
            englishSource: "Robert Collier",
            arabic: "النجاح هو مجموع جهود صغيرة تتكرر يومًا بعد يوم.",
            arabicSource: "روبرت كولير"
        ),
        DailyQuote(
            english: "Whoever fears climbing the mountains lives forever among the pits.",
            englishSource: "Abu al-Qasim al-Shabbi",
            arabic: "ومن يتهيّب صعودَ الجبالِ يعشْ أبدَ الدهرِ بين الحُفَرْ.",
            arabicSource: "أبو القاسم الشابي"
        ),
        DailyQuote(
            english: "The best time to plant a tree was 20 years ago. The second best time is now.",
            englishSource: "Chinese proverb",
            arabic: "أفضل وقت لزراعة شجرة كان قبل عشرين عامًا، وثاني أفضل وقت هو الآن.",
            arabicSource: "مثل صيني"
        ),
        DailyQuote(
            english: "Goals are not won by wishing; the world is taken by striving.",
            englishSource: "Ahmed Shawqi",
            arabic: "وما نيلُ المطالبِ بالتمنّي، ولكن تُؤخذُ الدنيا غِلابا.",
            arabicSource: "أحمد شوقي"
        ),
        DailyQuote(
            english: "Start where you are. Use what you have. Do what you can.",
            englishSource: "Arthur Ashe",
            arabic: "ابدأ من حيث أنت، استخدم ما لديك، وافعل ما تستطيع.",
            arabicSource: "آرثر آش"
        ),
        DailyQuote(
            english: "Every hard worker gets their share.",
            englishSource: "Arabic proverb",
            arabic: "لكلِّ مجتهدٍ نصيب.",
            arabicSource: "مثل عربي"
        ),
        DailyQuote(
            english: "Fall seven times, stand up eight.",
            englishSource: "Japanese proverb",
            arabic: "اسقط سبع مرات، وانهض ثماني.",
            arabicSource: "مثل ياباني"
        ),
        DailyQuote(
            english: "Learning in youth is like engraving on stone.",
            englishSource: "Arabic proverb",
            arabic: "العلمُ في الصغرِ كالنقشِ على الحجر.",
            arabicSource: "مثل عربي"
        ),
        DailyQuote(
            english: "What you do every day matters more than what you do once in a while.",
            englishSource: "Gretchen Rubin",
            arabic: "ما تفعله كل يوم أهم مما تفعله بين حين وآخر.",
            arabicSource: "غريتشن روبن"
        ),
        DailyQuote(
            english: "Well done is better than well said.",
            englishSource: "Benjamin Franklin",
            arabic: "العمل المتقن خيرٌ من القول المتقن.",
            arabicSource: "بنجامين فرانكلين"
        ),
        DailyQuote(
            english: "Habits are first cobwebs, then cables.",
            englishSource: "Spanish proverb",
            arabic: "العادات في البداية خيوط عنكبوت، ثم تصبح حبالًا متينة.",
            arabicSource: "مثل إسباني"
        ),
        DailyQuote(
            english: "Small deeds done are better than great deeds planned.",
            englishSource: "Peter Marshall",
            arabic: "الأعمال الصغيرة المنجزة خيرٌ من الأعمال العظيمة المؤجلة.",
            arabicSource: "بيتر مارشال"
        ),
        DailyQuote(
            english: "Energy and persistence conquer all things.",
            englishSource: "Benjamin Franklin",
            arabic: "الهمّة والمثابرة تتغلبان على كل شيء.",
            arabicSource: "بنجامين فرانكلين"
        ),
        DailyQuote(
            english: "The man who moves a mountain begins by carrying away small stones.",
            englishSource: "Chinese proverb",
            arabic: "من يحرّك جبلًا يبدأ بحمل الحجارة الصغيرة.",
            arabicSource: "مثل صيني"
        ),
    ]
}
