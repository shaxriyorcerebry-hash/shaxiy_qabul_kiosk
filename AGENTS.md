# AGENTS.md — Shaxsiy qabul kioski (`shaxiy_qabul_kiosk`)

> Bu fayl **Codex** tomonidan avtomatik o'qiladi.
> Sen — **🟧 Mobile dasturchining yordamchisisan** (Flutter, Windows desktop kiosk).
>
> ⚙️ Bu fayl skript bilan yaratiladi — **qo'lda tahrirlamang**, shablonni o'zgartiring:
> `../Projects-FinTech/scripts/templates/mobile-shaxiy_qabul_kiosk.md`
> va skriptni qayta ishga tushiring: `..\Projects-FinTech\scripts\setup-mobile-shaxiy-qabul-kiosk.ps1`

---

## 📁 Bu nima?

| | |
|--|--|
| **Ilova** | `shaxiy_qabul_kiosk` — Xalq qabulxonasi zalidagi teginish ekranli kiosk |
| **Vazifasi** | Hokim va o'rinbosarlarning **haftalik shaxsiy qabul jadvali** — bitta ekran, navigatsiyasiz, uz · ru · en. Hokim kartasi — hokim panelda belgilagan **aniq sana** bilan |
| **Platforma** | **Faqat Windows** (fullscreen kiosk, zalda **vertikal Windows 10** qurilmalar, 1080×1920). `android/ ios/ linux/ macos/ web/` — Flutter standart papkalari, ishlatilmaydi |
| **Mening rolim** | 🟧 Mobile |
| **Vault loyihasi** | `qabulhona` |
| **Hujjatlar (docs vault)** | `../Projects-FinTech/` (alohida git repo) |
| **Backend** | `https://qabulxona.gennis.uz/api` |

> Quyida qisqartma: **`…/qabulhona/`** = `../Projects-FinTech/01_Projects/qabulhona/`

---

## 🎯 Session boshlanganda DARHOL qil

### 1. Docs vault'ni yangila
```bash
git -C ../Projects-FinTech pull
```

### 2. Asosiy hujjatlarni o'qib chiq

| # | Fayl | Nima uchun |
|---|------|------------|
| 1 | `../Projects-FinTech/AGENTS.md` | Vault umumiy qoidalari (nom konvensiyasi, savollar tanlov shaklida) |
| 2 | `…/qabulhona/09 - Mobile (App)/Shaxsiy qabul (Kiosk)/00 - Shaxsiy qabul ro'yxati.md` | **⭐ Shu ilova hujjatlari** (index) |
| 3 | `…/qabulhona/09 - Mobile (App)/Shaxsiy qabul (Kiosk)/02 - Struktura.md` | Kod tuzilmasi, jadvalning 3 pog'onali manbasi |
| 4 | `…/qabulhona/09 - Mobile (App)/Shaxsiy qabul (Kiosk)/04 - Backend ulanishi (2026-07-28).md` | Endpoint, kesh, testlar, release |
| 4b | `…/qabulhona/09 - Mobile (App)/Shaxsiy qabul (Kiosk)/06 - Hokim qabul vaqti (2026-09-16).md` | Hokim sanasi (`/kiosk/reception-points`), SSL ildiz sertifikati, jonli probe |
| 4c | `…/qabulhona/09 - Mobile (App)/Shaxsiy qabul (Kiosk)/07 - Joriy kod holati v1.2.0 (2026-09-16).md` | Hokim kartasi dizayni, vertikal ekran o'lchovlari |
| 4d | `…/qabulhona/09 - Mobile (App)/Shaxsiy qabul (Kiosk)/08 - Joriy kod holati v1.3.0 (2026-09-16).md` | **Joriy release**: qo'lda yangilash (logotip 3 s), paket |
| 5 | `…/qabulhona/01 - Vazifalar (Todo)/03 - Mobile.md` | **⭐ Mening vazifalarim** — fayl katta (1300+ qator): `shaxiy_qabul` / `Shaxsiy qabul` bo'yicha qidiring |
| 6 | `…/qabulhona/02 - API/18b - Shaxsiy qabul jadvali — Mobile tekshiruvi va Backend vazifasi.md` | API contract (Backend yozadi, men o'qiyman) |
| 7 | `…/qabulhona/00 - Loyiha haqida (Project).md` | Butun platforma (kerak bo'lganda) |

### 3. Foydalanuvchiga ko'rsat
```
Mobile.md dagi shaxiy_qabul_kiosk vazifalari:
1. [ ] ...
2. [ ] ...

Qaysi vazifa ustida ishlaymiz?
```
Ochiq vazifa topilmasa — shuni ayt va nima qilishni **tanlov shaklida** so'ra.

---

## 🔧 Texnik — REAL stack

> ⚠️ Umumiy mobile shablondagi **Riverpod / Dio / go_router / Freezed / Hive / FCM bu loyihada YO'Q.**
> Ularni qo'shma va ularga mo'ljallangan skill'larni (`Ekran yaratish`, `Riverpod provider`, `Pro Mobile`) bu yerda ishlatma.

| Qatlam | Nima ishlatiladi |
|--------|------------------|
| Flutter / Dart | Dart SDK `^3.12.2`, lint: `flutter_lints` |
| State | `ChangeNotifier` (`KioskState`) + `ListenableBuilder` |
| HTTP | `dart:io` `HttpClient` — faqat `kioskHttpClient()` (`services/tls.dart`) orqali; tarmoq paketi yo'q |
| Kesh | `%LOCALAPPDATA%\shaxiy_qabul_kiosk\` — `reception_schedule.json` (+ `ETag`), `reception_points.json` |
| Routing | Yo'q — `KioskRoot` ichida doim bitta `ShaxsiyScreen` |
| Lokalizatsiya | O'zimizniki: `Lang` enum + `Tr` (`l10n.dart`) — `intl`/ARB emas |
| Konfiguratsiya | `lib/src/config.dart` — `const` (build vaqtida), `config.json` yo'q |
| Platforma paketlari | `window_manager` (fullscreen, preventClose), `wakelock_plus` |
| Ikonka | `flutter_launcher_icons` (faqat Windows) ← `assets/images/xalq_qabulxona_icon.png` |
| Test | `test/widget_test.dart` — parse, fallback, kesh, hokim sanasi, sana formati, sertifikat, ekran · `tool/live_probe_test.dart` — jonli backend (qo'lda) |

### Papka tuzilmasi (`lib/`)
```
lib/
├── main.dart                        # fullscreen, preventClose, wakelock, KIOSK_WINDOWED
└── src/
    ├── app.dart                     # KioskApp (MaterialApp, home = KioskRoot)
    ├── kiosk_root.dart              # shell: soat, idle-timer (90 s), chiqish, state.start()
    ├── kiosk_state.dart             # KioskState: lang + jadval + hokim sanasi (kesh → tarmoq → har 5 daq.)
    ├── config.dart                  # KioskConfig: tashkilot, idle, exitPassword, backendOrigin,
    │                                #   receptionPath, receptionPointsPath, refreshEvery
    ├── data.dart                    # AppData.shaxsiyQabul — 9 mansabdor (FALLBACK + seed manbasi)
    ├── l10n.dart                    # Lang + Tr (uz / ru / en)
    ├── theme.dart                   # AppColors, Palette
    ├── services/reception_api.dart  # ReceptionSchedule.parse · ReceptionApi.fetch (ETag/304) · ReceptionCache
    ├── services/hokim_reception.dart # HokimReception (next_reception_at, UTC+5) · ReceptionPointsApi · isHokimOfficial
    ├── services/tls.dart            # kioskHttpClient() — Windows ildizlari + ichki ISRG Root X1 (BUG-001)
    ├── screens/shaxsiy_screen.dart  # sof chizuvchi: officials / intro / note parametr sifatida
    └── widgets/                     # header_bar, footer_bar, exit_button, exit_password_dialog,
                                     # info_card, kiosk_background, pressable
```

### Tipik buyruqlar (PowerShell)
```powershell
flutter pub get
flutter analyze
flutter test
flutter test tool/live_probe_test.dart              # jonli backend: jadval + hokim sanasi + sertifikat
$env:KIOSK_WINDOWED = "1"; flutter run -d windows   # oynali rejim (dev, skrinshot)
Remove-Item Env:KIOSK_WINDOWED                      # oynali rejimni o'chirish
flutter run -d windows                              # haqiqiy kiosk rejimi (Alt+F4 bloklangan!)
dart run flutter_launcher_icons                     # exe ikonkasini qayta yaratish
flutter build windows --release                     # → build\windows\x64\runner\Release\
```

> Kiosk rejimidan chiqish — pastdagi tugma → parol (`KioskConfig.exitPassword`).
> Ma'lumotni darhol yangilash — tepadagi **logotipni 3 soniya** bosib turish (avtomatik — har 5 daqiqa).
>
> Dev mashinada `flutter` PATH da bo'lmasligi mumkin: `$env:Path = "C:\src\flutter\bin;$env:Path"`.
> `flutter run/build -d windows` plaginlar uchun Windows **Developer Mode** ni talab qiladi
> (`start ms-settings:developers`) — u o'chiq bo'lsa ekranni `flutter test` ichida chizib tekshiring.

### Release
1. `pubspec.yaml` versiyasini oshir (`version:` qatori)
2. `flutter analyze` + `flutter test` — ikkalasi toza bo'lsin
3. `flutter build windows --release`
4. `build\windows\x64\runner\Release\` ichini zip qil →
   `dist/ShaxsiyQabul_Kiosk_v<versiya>_win-x64.zip` (eski zip'larga **tegma** — har versiya alohida fayl)
5. `dist/`, `build/`, `.dart_tool/`, `windows/flutter/ephemeral/` — `.gitignore` da (GitHub 100 MB limit).
   Tafsilot: `GITHUBGA_TUSHMAGAN_FAYLLAR.md`, `QAYTA_TIKLASH.md`

---

## 🧱 Loyiha invariantlari (buzma)

1. **Ekran hech qachon bo'sh qolmaydi.** Manba tartibi: backend → disk keshi → `AppData.shaxsiyQabul`.
   `info_kiosk` dagi «Ma'lumot kiritilmagan» holati bu yerga **ko'chirilmaydi**.
2. **Endpoint:** `GET {apiBase}/kiosk/info/reception-schedule?lang=all` — `info_kiosk` bilan umumiy.
   Eski `/kiosk/reception-schedule` 2026-09 dan **200** qaytaradi, lekin konvertsiz va **`ETag` siz** — unga o'tma.
3. **`ETag` / `304`:** jadval va hokim sanasi har **5 daqiqada** so'raladi; o'zgarmagan jadval = bitta `304`.
   Xato yoki timeout joriy ko'rinishni o'zgartirmaydi; bir so'rov xatosi ikkinchisini to'xtatmaydi.
   Qo'lda yangilash (logotip 3 s, `HeaderBar.onLogoHold` → `KioskRoot._staffRefresh`) shu `refresh()` ni chaqiradi —
   u `Future<bool>` qaytaradi va bir vaqtdagi chaqiruvlarni **bitta so'rovga** birlashtiradi. Ekranda belgisi bo'lmasin.
4. **Parser bardoshli:** `officials`/`items`, `full_name`/`name`, `reception_day`/`day`,
   `{section, version, data}` konverti, `data: null` = kontent yo'q, bo'sh `ru`/`en` → `uz`.
   Yangi maydon qo'shsang — eski shakllar ham o'qilaversin (testlari bor).
5. **`data.dart` o'zgarsa** — backend seed ham mos bo'lishi kerak:
   `…/qabulhona/02 - API/24 - Info Kiosk mock kontent (seed manbasi)/json/reception-schedule.json`
   → `Backend.md` ga `[Mobile so'rovi]` TODO.
6. **3 til to'liq:** har yangi matn `uz` + `ru` + `en` uchalasida.
7. **Kiosk rejimi:** fullscreen + `setPreventClose(true)` + wakelock.
   Harakatsizlik 90 s → til `uz` ga qaytadi, ochiq dialoglar yopiladi.
8. **Minimal paketlar:** hozir faqat `window_manager` + `wakelock_plus`.
   Yangi paket qo'shishdan oldin foydalanuvchidan **tanlov shaklida** so'ra.
9. **Hokim sanasi** (foydalanuvchi qarori 2026-09-16): `GET {apiBase}/kiosk/reception-points` →
   `ticket_prefix: "H"` → `next_reception_at` (UTC → Toshkent **+5**, qurilma soat mintaqasiga qaramaydi).
   Faqat **hokim kartasi** (`isHokimOfficial`: `hokim(i)` so'zi, `o'rinbosar` emas) o'zgaradi:
   - sana bor va qabul kuni tugamagan → haftalik qator o'rniga `24-sentabr, payshanba` + `10:00` + joy;
   - sana yo'q yoki o'tib ketgan → «Qabul vaqti belgilanmagan» (vaqt bo'sh);
   - ro'yxat umuman olinmagan (kesh ham yo'q) → haftalik matn qoladi.
   Faqat **boshlanish** vaqti ko'rsatiladi — backend tugash vaqtini bermaydi (`Backend.md` TODO).
10. **SSL:** barcha so'rovlar `kioskHttpClient()` orqali — ichki ISRG Root X1 ni olib tashlama.
11. **Vertikal ekran birinchi:** zal kiosklari 1080×1920 portret. UI o'zgarsa tekshir:
    1080×1920 (100%) — uz/ru/en da **aylantirishsiz** sig'sin; 864 va 720 px kenglikda (125/150%) overflow bo'lmasin.
    Hokim kartasi (`_HokimCard`) — butun qator, ≥ 720 px yonma-yon; grid ≥ 760 px — 2 ustun; header < 1000 px — 2 qator.
    `flutter test` dagi Ahem shrifti haqiqiydan keng — o'lchash uchun Segoe UI (`C:\Windows\Fonts`) ni `FontLoader` bilan yuklab chiz.
12. **Release paketi:** `flutter build windows` VC++ runtime DLL'larini (`msvcp140*`, `vcruntime140*`, `concrt140`) o'zi qo'shadi — zip'da **24 fayl** bo'lishi kerak (toza Win10 uchun).

### 🛡️ Xavfsizlik
- `exitPassword` manba kodda ochiq (`config.dart`) — u faqat zaldagi tasodifiy odamni to'xtatadi.
  Qattiqlashtirish so'ralsa → skill **`flutter-windows-security`** (SHA-256 + constant-time + backoff).
  So'ralmasa parolga tegma.
- Qurilmada TLS xatosi chiqsa — `…/qabulhona/05 - Buglar (Bugs)/BUG-001 - Info Kiosk qurilmasida TLS sertifikat xatosi.md` (xuddi shu backend).
  Bu kioskda ISRG Root X1 ilova ichida (`services/tls.dart`, 2026-09-16). Backend sertifikat zanjiri
  X1 ga yetmay qolsa (Let's Encrypt cross-sign'ni olib tashlasa) — `tool/live_probe_test.dart` qizil bo'ladi → yangi ildiz qo'sh.

---

## ⚙️ Vazifa bajarish workflow

1. **Kod** — shu repoda, yuqoridagi struktura bo'yicha.
2. **Tekshir** — `flutter analyze` + `flutter test`; UI o'zgarsa `KIOSK_WINDOWED=1` bilan ko'rib chiq.
3. **Hujjat** — `…/qabulhona/09 - Mobile (App)/Shaxsiy qabul (Kiosk)/`:
   - mavjud faylni yangila (`02 - Struktura`, `03 - Kontent va lokalizatsiya`), yoki
   - release bo'lsa — yangi `NN - Joriy kod holati v<versiya> (YYYY-MM-DD).md` + `00 - Shaxsiy qabul ro'yxati.md`;
   - `…/qabulhona/09 - Mobile (App)/00 - Mobile ro'yxati.md` — versiya / commit jadvali.
4. **API kerak bo'lsa** → `…/qabulhona/01 - Vazifalar (Todo)/01 - Backend.md` ga faqat YANGI TODO:
   ```markdown
   - [ ] **[Mobile so'rovi]** `shaxiy_qabul_kiosk`: <nima kerak>
   ```
5. **Vazifani yop** — `…/qabulhona/01 - Vazifalar (Todo)/03 - Mobile.md`:
   `- [x] ~~Vazifa~~ — YYYY-MM-DD — @kim`
6. **Changelog** — `…/qabulhona/07 - O'zgarishlar tarixi (Changelog).md`

---

## 🚫 HECH QACHON qilma

- ❌ Riverpod / Dio / go_router / Freezed / Hive qo'shma (foydalanuvchi so'ramasa)
- ❌ `Backend.md`, `Frontend.md` ni tahrirlama — faqat yangi TODO qo'shish
- ❌ `02 - API/`, `03 - Database (Baza)/`, `08 - Frontend (Web)/` ni o'zgartirma
- ❌ `dist/` dagi eski zip'ni o'chirma yoki ustidan yozma
- ❌ `build/`, `.dart_tool/`, `windows/flutter/ephemeral/`, `*.pdb` ni commit qilma
- ❌ `analyze` / `test` o'tmasdan release chiqarma
- ❌ Bu faylni qo'lda tahrirlama — shablonni o'zgartirib skriptni qayta ishga tushir

## ✅ HAR DOIM qil

- ✅ Session oxirida **2 ta git diff** ko'rsat: bu repo (kod) + `../Projects-FinTech` (hujjat)
- ✅ Conventional commit: bu repoda `feat(schedule): ...`, `fix(kiosk): ...`; vault'da `docs(mobile): ...`
- ✅ Savolni **tanlov shaklida** ber (2–4 variant + oqibati + tavsiya) — vault qoidasi
- ✅ Push qilishdan oldin foydalanuvchidan so'ra

---

## 🛠️ Skill'lar

Skill fayllari docs vault'da turadi - kerakli faylni o'qib, ko'rsatma bo'yicha ishlang.

| Skill | Manba (`../Projects-FinTech/03_Claude_Skills/`) | Qachon |
|-------|------------------------------------------------|--------|
| `flutter-windows-security` | `03 - Mobile/04 - Flutter Windows security (kiosk).md` | "kiosk xavfsizligi", "chiqish paroli", "obfuscate" |
| `adr-write` | `04 - Umumiy/01 - ADR yozish.md` | "ADR yoz" |
| `conventional-commit` | `04 - Umumiy/02 - Conventional commit.md` | "commit message yoz" |
| Flutter Skills Pack (reference) | `03 - Mobile/03 - Flutter Skills Pack (community).md` | umumiy Flutter savollari — o'rnatish buyrug'i shu faylda |
