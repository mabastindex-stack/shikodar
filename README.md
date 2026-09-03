# شکۆدار (Şikodar) — Flutter UI Scaffold

پڕۆژەی Flutter بۆ ئەپی خانووبەرەی کەرکوک. ئەمە **وێنەی گشتی (UI scaffold)** ـە — بەکارهێنانی mock data بۆ پیشاندان، پێش پەیوەستکردنی Laravel API ی ڕاستەقینە.

## چۆنیەتی ڕاکردن

```bash
flutter pub get
flutter run
```

پێویستە Flutter SDK دامەزرابێت (`flutter doctor` بۆ پشکنین). بۆ iOS، پێویستت بە Mac + Xcode هەیە.

## کۆدی سنووری سێرڤەر

ئەپەکە بە شێوەی خۆکار دەگەڕێت بۆ `http://127.0.0.1:8000/api`. لە پرۆفایل ← ڕێکخستنی سێرڤەر (یان لای login ـدا ئایکۆنی ⚙️)، دەتوانیت بیگۆڕیت بۆ:
- Local AppServ/XAMPP: `http://127.0.0.1/shikodar/public/api`
- Hostinger: `https://shikodar.com/api` (نموونە — بیگۆڕە بۆ دۆمەینی ڕاستەقینەت)

## پێکهاتەی فۆڵدەرەکان

```
lib/
  core/
    theme/          → ڕەنگ و ThemeData (تاریکی+زێڕی پشتڕاستکراو)
    models/          → Listing, Agency, Reel, PackageTier
    network/         → ApiClient (Dio + configurable base URL)
    mock/            → داتای نموونەیی بۆ پیشاندان
  features/
    auth/            → Splash, Login, Register, OTP, Server Settings
    home/            → Home feed, Search/Map, Favorites, bottom-nav shell
    reels/           → Reels feed (فلتەر، overlay، دوگمەی پەیوەندی)
    listing/         → Listing detail
    profile/         → Profile (زمان، dark mode، dashboard entries)
assets/
  translations/      → ku.json, ar.json, en.json (easy_localization)
```

## پێویستە دواتر بکرێت (بۆ تۆ، دوای ئامادەبوونی هەموو کۆدەکە)

1. **پەیوەستکردنی Laravel API ـی ڕاستەقینە** — لە `MockData` بگۆڕە بۆ بانگکردنی `ApiClient` لە هەر screenـێکدا
2. **Firebase project** دروست بکە بۆ push notifications (FCM)، `google-services.json` / `GoogleService-Info.plist` زیاد بکە
3. **Google Maps API key** زیاد بکە لە `android/app/src/main/AndroidManifest.xml` و `ios/Runner/AppDelegate.swift`
4. **App icon و splash native** ـی ڕاستەقینە دابنێ (ئێستا تەنها ئایکۆنی Material placeholder ـە)
5. **پەیوەندیکردنی ژمارەی واتسئەپ/تەلەفۆنی ڕاستەقینە** لە شوێنی placeholder ـی `+9647700000000`
6. **App Store / Play Store accounts** — دروستکردنی هەژمار و پڕکردنەوەی metadata

## تایبەتمەندیە جێبەجێکراوەکان لەم scaffold ـە

- Splash + Login (client/agency toggle) + Register + OTP
- Home feed بە فلتەری progressive (٥ چیپ سەرەکی + "فلتەری زیاتر" bottom sheet)
- Reels — پشتڕاستکراو بەپێی دیزاینی پەسەندکراو: بێ لایک/کۆمێنت، pill toggle کرێ/فرۆشتن، چیپی جۆر، دوو دوگمەی پەیوەندی (واتسئەپ + تەلەفۆن)
- Search/Map (Google Maps) + List view toggle
- Favorites بە global sync (ValueNotifier، هەمان پاتەرنی شلون اخدمک)
- Listing detail — نرخی ئاسایی یان سیستەمی سێ‌نرخی (کەمترین/ناوەڕاست/کۆتایی) کاتێک negotiable ـە
- Profile — گۆڕینی زمان (کوردی/عەرەبی/ئینگلیزی)، Dark/Light mode، ڕێکخستنی سێرڤەر
- سێ زمان بە تەواوی وەرگێڕدراو (ku/ar/en)، RTL خۆکار بۆ کوردی/عەرەبی

## هێشتا placeholder ـە (پێویستی بە کارە زیاترە)

- Dashboard ـی ورد بە ئامار (چارت)
- Review/Rating سیستەم
- سیستەمی سپۆنسەرشیپ (Bronze/Silver/Gold)
- ڕاپۆرتکردنی ورد (فۆرمی سکاڵا)
- ڤیدیۆی 360°
- پۆرتۆفیۆلی تایبەتی عقارات (پەیجی تەواو بە ئەنیمەیشنی Rive)
