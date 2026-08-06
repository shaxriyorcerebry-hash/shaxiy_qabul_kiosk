# AGENTS.md — Mobile Loyihasi

> Bu fayl **Codex** tomonidan avtomatik o'qiladi.  
> Sen — **Mobile dasturchining yordamchisisan** (Flutter loyihasi).

---

## 📁 Bu nima?

- **Bu papka:** Mobile kod (Flutter + Riverpod + Dio)
- **Mening rolim:** 🟧 Mobile
- **Hujjatlar (docs vault):** `../Projects-FinTech/` (alohida git repo)

---

## 🎯 Session boshlanganda DARHOL qil

### 1. Docs vault'ni yangila
```bash
cd ../Projects-FinTech && git pull && cd -
```

### 2. Asosiy hujjatlarni o'qib chiq

| #   | Fayl                                                                             | Nima uchun                                  |
| --- | -------------------------------------------------------------------------------- | ------------------------------------------- |
| 1   | `../Projects-FinTech/AGENTS.md`                                                  | Vault umumiy qoidalari                      |
| 2   | `../Projects-FinTech/01_Projects/ToDo/00 - Loyiha haqida (Project).md`           | Loyiha overview                             |
| 3   | `../Projects-FinTech/01_Projects/ToDo/01 - Vazifalar (Todo)/03 - Mobile.md`      | **⭐ Mening vazifalarim**                    |
| 4   | `../Projects-FinTech/01_Projects/ToDo/02 - API/00 - API ro'yxati.md`             | API contract (Backend yozadi, men o'qiyman) |
| 5   | `../Projects-FinTech/01_Projects/ToDo/09 - Mobile (App)/00 - Mobile ro'yxati.md` | Mobile hujjatlar                            |

### 3. Foydalanuvchiga ko'rsat
```
"Sizning vazifalaringiz (Mobile.md dan):
1. [ ] ...
2. [ ] ...

Qaysi vazifa ustida ishlaymiz?"
```

---

## ⚙️ Vazifa bajarish workflow

### Yangi ekran
**Skill:** `.Codex/skills/01 - Ekran yaratish.md` (avto-yuklangan)

1. **Bu loyihada** kod yozish:
   - `lib/models/<name>.dart` — Freezed model (`dart run build_runner build`)
   - `lib/providers/<name>_provider.dart` — Riverpod
   - `lib/screens/<feature>/<name>_screen.dart` — Widget
   - `lib/router/app_router.dart` — go_router route qo'shish

2. **Docs vault'da** hujjat yangilash:
   - `../Projects-FinTech/01_Projects/ToDo/09 - Mobile (App)/03 - Ekranlar.md`

3. Agar **API kerak** bo'lsa va backend hali yaratmagan bo'lsa:
   - `../Projects-FinTech/01_Projects/ToDo/01 - Vazifalar (Todo)/01 - Backend.md` ga TODO:
     ```markdown
     - [ ] **[Mobile so'rovi]** Endpoint: `GET /tasks/share-link/:id`
     ```

4. Vazifani tugatilgan deb belgilash:
   - `../Projects-FinTech/01_Projects/ToDo/01 - Vazifalar (Todo)/03 - Mobile.md`

### Yangi Riverpod provider
**Skill:** `.Codex/skills/02 - Riverpod provider.md`

- `@riverpod` annotation bilan codegen
- `dart run build_runner build --delete-conflicting-outputs`
- Docs: `../Projects-FinTech/.../09 - Mobile (App)/05 - State management.md`

### Push notification feature
1. FCM token registrationni `lib/services/notifications/` ga
2. **Cross-role:** Backend FCM event yuborishi kerak
   - `../Projects-FinTech/01_Projects/ToDo/01 - Vazifalar (Todo)/01 - Backend.md` ga TODO:
     ```markdown
     - [ ] **[Mobile so'rovi]** FCM event yuborish: task assigned bo'lganda
     ```
3. Docs: `09 - Mobile (App)/10 - Push notifications.md`

### Platform-specific masala (iOS vs Android)
- Faqat bir platforma'da xato → `09 - Platform-specific.md` ga yoz
- Permissions: `ios/Runner/Info.plist` + `android/app/src/main/AndroidManifest.xml`

---

## 🚫 HECH QACHON qilma

- ❌ **Backend.md** yoki **Frontend.md** ni edit qilma — faqat TODO qo'shish
- ❌ `02 - API/` ichidagi fayllarni o'zgartirma — Backend yozadi
- ❌ `03 - Database/` ga tegma
- ❌ `08 - Frontend (Web)/` ichidagi fayllarni o'zgartirma
- ❌ `build_runner` natijalarini (`.g.dart`, `.freezed.dart`) qo'lda edit qilma — regenerate
- ❌ Production'ga test qilmasdan APK/IPA chiqarma

## ✅ HAR DOIM qil

- ✅ Session oxirida **2 ta git diff** ko'rsat:
  1. Bu loyiha (`todo-mobile`) — kod
  2. Docs vault (`../Projects-FinTech`) — hujjat
- ✅ Conventional commit:
  - Bu loyihada: `feat(screens): add tasks list screen`
  - Docs vault'da: `docs(mobile): add tasks list screen documentation`
- ✅ Codegen run qil: `dart run build_runner build --delete-conflicting-outputs`
- ✅ Tests yoz (widget tests minimum)
- ✅ Hive cache + offline mode considerations
- ✅ iOS va Android **ikkalasini** ham test qil (yoki eslatib o'tib)

---

## 🛠️ O'rnatilgan skill'lar (`.Codex/skills/`)

| Skill | Trigger |
|-------|---------|
| `01 - Ekran yaratish.md` | "yangi ekran", "screen qo'sh" |
| `02 - Riverpod provider.md` | "yangi provider" |
| `01 - ADR yozish.md` | "ADR yoz" |
| `02 - Conventional commit.md` | "commit message yoz" |

> Ko'proq skill: `../Projects-FinTech/03_Claude_Skills/03 - Mobile/`  
> Tavsiya: **Flutter Skills Pack** (rasmiy, 55 ta skill)  
> `npx skills add https://github.com/flutter/skills --skill flutter-managing-state`

---

## 🔧 Bu loyiha — texnik

- **Flutter:** 3.19+
- **Dart:** 3.3+
- **State:** Riverpod 2 (codegen)
- **HTTP:** Dio + JWT interceptor
- **Cache:** Hive (offline)
- **Models:** Freezed (immutable + JSON serialization)
- **Routing:** go_router 13
- **Forms:** flutter_form_builder
- **Push:** firebase_messaging (FCM)

### Tipik buyruqlar
```bash
flutter pub get                                              # Dependencies
dart run build_runner build --delete-conflicting-outputs    # Codegen (Freezed, Riverpod)
flutter run                                                  # Run app (qurilma tanlasin)
flutter run -d chrome                                        # Web preview (debug)
flutter test                                                 # Tests
flutter build apk                                            # Android APK
flutter build ios                                            # iOS (Mac kerak)
flutter analyze                                              # Lint
flutter format lib/                                          # Format
```

### Folder tuzilmasi (`lib/`)
```
lib/
├── api/         # Dio clients
├── models/      # Freezed models
├── providers/   # Riverpod providers
├── screens/     # Ekran widgets
│   └── tasks/
│       ├── tasks_screen.dart
│       └── widgets/
├── widgets/     # Umumiy reusable widgets
├── router/      # go_router config
├── services/    # FCM, secure storage
├── theme/       # ThemeData, Material 3
├── utils/       # Helper functions
└── main.dart    # Entry point
```

### Platform-specific
- **iOS:** `ios/Runner/Info.plist`, `ios/Runner.xcworkspace`
- **Android:** `android/app/src/main/AndroidManifest.xml`, `android/app/build.gradle`
- **Permissions** har platformada alohida so'raladi
