# Qayta tiklash / yuklab olish yo'riqnomasi

> Yangilangan sana: 2026-07-25

Loyihani yangi kompyuterda (yoki repozitoriyani klon qilgandan keyin) to'liq ishga
tushirish uchun GitHub'ga yuklanmagan fayllarni quyidagicha tiklang.
Yuklanmagan fayllar ro'yxati: [GITHUBGA_TUSHMAGAN_FAYLLAR.md](GITHUBGA_TUSHMAGAN_FAYLLAR.md)

## 0. Talablar

```bash
flutter --version   # Flutter SDK o'rnatilgan bo'lishi kerak
```

## 1. Paketlar va avtomatik fayllar (`.dart_tool/`, `ephemeral/`)

`.dart_tool/`, `windows/flutter/ephemeral/` (jumladan `flutter_windows.dll.pdb`) va
`.flutter-plugins-*` fayllari quyidagi buyruq bilan avtomatik qayta hosil bo'ladi:

```bash
flutter clean
flutter pub get
```

## 2. Build natijasi (`dist/`)

`dist/` — bu tayyor build/paketlash natijasi. Uni koddan qayta yaratish uchun:

```bash
flutter build windows --release
```

---
_Ushbu hujjat avtomatik yaratildi._
