# shaxiy_qabul_kiosk

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Yangilanish va Setup.exe (ADR-037)

Kiosk o'zini internet orqali yangilaydi: ochilgandan 60 s keyin va har 3 soatda
`https://qabulxona.gennis.uz/downloads/kiosk/shaxiy_qabul_kiosk/version.json` ni
tekshiradi, yangi versiyani fonda yuklab SHA-256 ni tekshiradi va kiosk bo'sh
turganda (≥ 2 daqiqa teginish yo'q, xodim oynasi ochiq emas) 15 s ogohlantirish
bilan jim o'rnatadi. Kod: `lib/core/update/` (`_kiosk_update_kit` dan nusxa —
shu yerda o'zgartirmang).

### Reliz yig'ish

1. `pubspec.yaml` da `version:` ni oshiring (masalan `1.4.0+5` → `1.4.1+6`).
2. Yig'ing (Inno Setup 6 kerak: `winget install --id JRSoftware.InnoSetup -e`):

   ```powershell
   powershell -ExecutionPolicy Bypass -File scripts\release-windows.ps1 -Changelog "- nima o'zgardi"
   ```

   Natija: `dist\ShaxsiyQabul_Setup_vX.Y.Z.exe` (+ SHA-256, namuna `dist\version.json`).
   Font subset bloklansa: `-ExtraBuildArgs --no-tree-shake-icons`.
3. Admin panel → **Sozlamalar → Kiosk yangilanishlari** → `shaxiy_qabul_kiosk` →
   **faqat `.exe`** ni yuklang. `version.json` ni server o'zi yozadi.
4. `dist\symbols\<versiya>` ni saqlab qo'ying (obfuscation xaritasi) — serverga emas.

### Kioskda

- **Sozlamalar** — pastki o'ng burchakdagi «Chiqish» (eshik) tugmasini **2 soniya
  bosib turing**. Parol so'ralmaydi: «Yangilanish» bo'limi — versiyalar, holat,
  «Hozir tekshirish», «Hozir o'rnatish», Log.
- **Chiqish** — «Chiqish» ni oddiy bosish (yoki Sozlamalar ichidagi «Chiqish»)
  avvalgidek parol so'raydi.
- Logoni 3 soniya bosib turish — jadvalni serverdan darhol yangilash (o'zgarmagan).

### Birinchi o'rnatish

`ShaxsiyQabul_Setup_vX.Y.Z.exe` ni kiosk kompyuterida bir marta qo'lda ishga
tushiring — ilova `C:\Kiosk\ShaxsiyQabul` ga o'rnatiladi (administrator huquqi
shart emas; `KioskLauncher.exe` ham shu papkada). Keyingi yangilanishlar
avtomatik. Log: `%LOCALAPPDATA%\ShaxsiyQabul\update.log`.
