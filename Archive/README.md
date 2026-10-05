# Dynamic Island لـ macOS — MacBook Pro/Air 2015

## 1. Architecture

- **AppKit** للنافذة العائمة (لأن SwiftUI وحده لا يعطيك تحكمًا كافيًا في:
  borderless panel، مستوى النافذة `.statusBar`، منع سرقة الـ focus، والتموضع الدقيق).
- **SwiftUI** (عبر `NSHostingView`) لبناء واجهة الجزيرة نفسها والإعدادات — أخف
  وأسرع تطويرًا من AppKit البحت، ومتاح بالكامل من macOS 11.
- **MVVM بسيط**: `IslandViewModel` (ObservableObject) هو مصدر الحقيقة الوحيد،
  وكل "مدير" (Battery/Music/Volume/...) مستقل تمامًا ويُبلّغ الـ ViewModel عبر closure.
  هذا يخلي إضافة/حذف أي ميزة لاحقًا سهل جدًا وما يكسرش بقية التطبيق.
- **بدون أي dependency خارجي** (لا SPM ولا CocoaPods) — فقط Frameworks النظام:
  AppKit, SwiftUI, Combine, IOKit, CoreAudio, AudioToolbox, Network, CoreWLAN,
  ServiceManagement, UserNotifications.

## 2. Minimum macOS Version — ولماذا

**اخترت `macOS 11.0 (Big Sur)` كحد أدنى.**

- الـ MacBook Pro (Retina, 13/15-inch, Early/Mid/Late 2015) والـ MacBook Air 2015
  مدعومون رسميًا من Apple حتى **macOS Monterey (12)**، وبعضهم Big Sur فقط حسب الموديل بالضبط.
  يعني عمليًا الجهاز يقدر يشغّل Big Sur أو Monterey براحة.
- SwiftUI متاح من 10.15، لكن أشياء استخدمتها هنا مثل `.interpolatingSpring`
  المتقدم، `ProgressView`، وسلوك الـ animations الأدق بتستقر فعليًا من macOS 11.
- ما استخدمتش أي حاجة تحتاج macOS 12/13 (مثل `SMAppService` الجديد) — استخدمت
  البديل الكلاسيكي المتوافق مع Big Sur (`LoginItemManager.swift`).
- **النتيجة:** التطبيق يشتغل من Big Sur لحد أحدث إصدار، وهو المدى الواقعي
  والمستقر لجهاز 2015.

## 3. هيكل الملفات

```
DynamicIsland/
├── main.swift                     نقطة الدخول (بدون Storyboard)
├── AppDelegate.swift               إعداد التطبيق + Menu Bar + Shortcut
├── Info.plist                      LSUIElement=true (بدون Dock icon)
├── DynamicIsland.entitlements
├── IslandSettings.swift            نموذج الإعدادات + حفظ في UserDefaults
├── IslandViewModel.swift           المصدر الوحيد للحالة (State)
├── IslandWindowController.swift    النافذة العائمة (NSPanel) + التموضع
├── IslandView.swift                واجهة الجزيرة (SwiftUI) لكل الأوضاع
├── SettingsWindowController.swift  نافذة الإعدادات
├── SettingsView.swift              واجهة الإعدادات (SwiftUI)
├── LoginItemManager.swift          Launch at Login (طريقة متوافقة مع Big Sur)
└── Managers/
    ├── BatteryManager.swift        IOKit Power Sources (API عام)
    ├── MusicManager.swift          AppleScript/Apple Events → Music.app
    ├── VolumeManager.swift         CoreAudio property listener
    ├── BrightnessManager.swift     رصد مفاتيح F1/F2 (راجع الملاحظة داخل الملف)
    ├── ClipboardManager.swift      Polling خفيف على NSPasteboard.changeCount
    ├── NetworkManager.swift        NWPathMonitor + CoreWLAN SSID
    └── NotificationsManager.swift  نظام إشعارات داخلي (راجع الملاحظة داخل الملف)
```

## 4. خطوات إنشاء المشروع في Xcode

1. افتح Xcode → **File → New → Project → macOS → App**.
2. الاسم: `DynamicIsland`، Interface: **SwiftUI** (لن نستخدمها كنقطة دخول لكن
   Xcode يطلب اختيارًا)، Language: **Swift**.
3. بعد إنشاء المشروع، **احذف** الملفات الافتراضية: `DynamicIslandApp.swift`
   و`ContentView.swift` (لأننا هنستخدم `main.swift` كنقطة دخول يدوية).
4. اسحب كل الملفات المرفقة هنا (كلها، بما فيها مجلد `Managers`) داخل الـ
   Xcode Navigator، وتأكد إن **Target Membership** لكل ملف = `DynamicIsland`.
5. من **Project Navigator → DynamicIsland (المشروع) → TARGETS → DynamicIsland
   → Build Settings**:
   - ابحث عن `Info.plist File` وحدد المسار لملف `Info.plist` المرفق.
   - ابحث عن `macOS Deployment Target` واضبطه على `11.0`.
6. من تبويب **Signing & Capabilities**:
   - أضف ملف `DynamicIsland.entitlements` (اسحبه للمشروع لو مش موجود، ثم من
     Build Settings ابحث عن `Code Signing Entitlements` وحدد مساره).
   - اختر Team الخاص بك للـ Signing (حتى لو Personal Team للتجربة المحلية).
7. من **Build Phases → Link Binary With Libraries** أضف يدويًا:
   `IOKit.framework`, `CoreAudio.framework`, `AudioToolbox.framework`,
   `Network.framework`, `CoreWLAN.framework`, `ServiceManagement.framework`.
8. تأكد إن `main.swift` موجود ومفيهوش أي `@main` أو `@NSApplicationMain` في أي
   ملف تاني (AppDelegate.swift عادي بدون أي attribute).

## 5. التشغيل من Xcode

- اختر الـ scheme `DynamicIsland` → Run (⌘R).
- أول مرة هتشغّل الموسيقى، macOS هيطلب إذن **Automation** للتحكم في
  Music.app — اضغط "Allow" (لو رفضته بالغلط: System Settings → Privacy &
  Security → Automation → فعّل DynamicIsland مقابل Music).
- لو استخدمت ميزة اسم شبكة Wi-Fi، macOS ممكن يطلب **Location Services**
  (راجع القسم 7 بالأسفل — ده قيد نظام حقيقي مش عيب في الكود).

## 6. Build كـ `.app` نهائي

1. من الـ Xcode menu: **Product → Scheme → Edit Scheme → Run → Build
   Configuration** غيّرها لـ `Release`.
2. **Product → Archive**.
3. في نافذة Organizer التي تفتح تلقائيًا: **Distribute App → Copy App →
   Export**.
4. هتحصل على `DynamicIsland.app` جاهز — انسخه لمجلد Applications وشغّله
   بالضغط المزدوج مباشرة (مش محتاج Xcode بعد كده).

> ملاحظة توقيع: لو مش هتوزّع التطبيق خارج جهازك، وقّعه بـ **Sign to Run
> Locally** أو بـ Personal Team كافي تمامًا لتشغيله على جهازك.

## 7. الصلاحيات (Permissions) المطلوبة من macOS

| الميزة | الصلاحية | ملاحظة |
|---|---|---|
| Music | Automation (التحكم في Music.app) | تظهر تلقائيًا أول استخدام |
| Clipboard | لا يوجد إذن نظام مطلوب | Polling عام لا يحتاج إذن |
| Battery | لا يوجد | IOKit API عام |
| Volume | لا يوجد | CoreAudio API عام |
| Network status (متصل/غير متصل) | لا يوجد | `NWPathMonitor` عام |
| **اسم شبكة Wi-Fi (SSID)** | **Location Services** | ابتداءً من macOS الحديث، Apple تربط قراءة اسم الشبكة بصلاحية الموقع كحماية للخصوصية. لو رفض المستخدم الإذن، التطبيق هيعرض "شبكة متصلة" بدل الاسم الفعلي بدل ما يكرش |
| Launch at Login | لا يوجد إذن خاص، لكن أول مرة System Events قد تطلب إذن "Automation" برضه | طبيعي جدًا |
| Brightness | لا يوجد (لأننا ما استخدمناش API خاص أصلًا) | راجع القسم 8 |

## 8. ملاحظتان مهمتان بخصوص الصدق التقني (تمت مراجعتهما بعناية)

1. **السطوع (Brightness):** macOS لا يوفر API عامًا لقراءة "القيمة الفعلية"
   لسطوع شاشة MacBook المدمجة بدون Private Frameworks. تم تعمّد **عدم**
   استخدام أي API خاص (حفاظًا على الاستقرار طويل المدى المطلوب في طلبك)،
   والبديل المطبَّق هو رصد ضغط مفاتيح F1/F2 وعرض نسبة تقريبية. هذا حل شائع
   ومستقر، لكنه تقريبي وليس القيمة الحقيقية 100%.
2. **الإشعارات (Notifications):** لا توجد طريقة عامة/مستقرة لاعتراض إشعارات
   تطبيقات أخرى (واتساب، ميل...) بدون الدخول لقاعدة بيانات خاصة غير موثقة
   تتغيّر بنيتها بين إصدارات macOS بلا سابق إنذار. تم تعمّد عدم تنفيذ هذا،
   والملف `NotificationsManager.swift` بدل كده بيوفر قناة داخلية يقدر أي جزء
   من تطبيقك (أو تطبيق تاني تملكه) يبعت من خلالها إشعار يظهر داخل الجزيرة.

هذا الاختيار امتثالًا مباشرًا لتعليمتك: **"لو احتجت تختار بين Feature معقدة
وبين استقرار التطبيق، اختار الاستقرار."**

## 9. مراجعة الكود (Self-Review) — أهم النقاط اللي اتراجعت

- كل الملفات تستخدم فقط Frameworks عامة موثقة (لا Private API إطلاقًا).
- `IslandMode` مطابق لـ `Equatable` (كل الـ associated values هي
  Int/Bool/String/Double وكلها Equatable) — ضروري لعمل `.animation(value:)`
  في SwiftUI ولمقارنة الحالة قبل الإخفاء التلقائي.
- النافذة (`IslandPanel`) بتلغي `canBecomeKey`/`canBecomeMain` عشان أبدًا ما
  تسرقش الـ focus من التطبيق الشغال، وحجمها الفعلي بيتصغّر تلقائيًا في
  الوضع العادي (`170×40`) عشان ما تحجبش الضغط على أي حاجة تحت الشاشة.
- تم تفادي أي retain cycles عبر `[weak self]` في كل الـ closures التي قد
  تعيش لفترة طويلة (Timers, Property Listeners, Global Monitors).
- تم إزالة كل استدعاء غير ضروري (مثل force-unwrap لـ `contentView` في
  النافذة) لتفادي أي احتمال Crash عند الإطلاق على أجهزة مختلفة.
