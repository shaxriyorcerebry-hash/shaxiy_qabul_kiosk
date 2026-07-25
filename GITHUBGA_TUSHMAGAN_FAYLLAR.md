# GitHub'ga yuklanmagan (ignore qilingan) fayllar

> Yangilangan sana: 2026-07-25
>
> Quyidagi fayllar hajmi katta (GitHub bitta faylga **100 MB** limit qo'yadi) yoki
> build paytida qayta hosil bo'ladi, shuning uchun `.gitignore` orqali repozitoriyaga
> **yuklanmagan**. Loyihani boshqa kompyuterda ishga tushirish uchun ularni qayta
> tiklash yoki alohida ko'chirib olish kerak. Batafsil: [QAYTA_TIKLASH.md](QAYTA_TIKLASH.md)

## Umumiy ro'yxat

| Yo'l | Hajm | Turi | Tiklash |
|------|------|------|---------|
| `windows/flutter/ephemeral/flutter_windows.dll.pdb` | 240M | Flutter Windows debug simvollari | `flutter pub get` / build |
| `dist/` | 13M | Build/paketlash natijasi | Qayta build qilinadi |
| `build/` | 320M | Flutter build natijasi | `flutter build` |
| `.dart_tool/` | 100M | Dart/pub cache | `flutter pub get` |

---
_Ushbu ro'yxat avtomatik yaratildi. `.gitignore` dagi `KATTA-BINAR-BLOK-v2` bo'limiga qarang._
