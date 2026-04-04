# Texnik topshiriq — Kuryer auksion platformasi

Hujjat keyingi dasturchi yoki texnik topshiruv uchun. Holat: loyiha kod bazasi bo‘yicha 2026.

---

## 1. Loyiha identifikatsiyasi

| Maydon | Qiymat |
|--------|--------|
| **Paket nomi** | `courier_auction` |
| **Tavsif** | Pastga tushuvchi narx auksioni bilan kuryer bozori (Flutter ilova) |
| **Versiya** | `1.0.0+1` |
| **SDK** | Dart `>=3.5.0 <4.0.0` |

---

## 2. Texnologik stack

| Komponent | Texnologiya |
|-----------|-------------|
| UI | Flutter (Material 3), `flutter_localizations` |
| Holat | `flutter_riverpod` ^2.6 (AsyncNotifier, FutureProvider, family) |
| Marshrutlash | `go_router` ^14.6 — `routerProvider`, `redirect` |
| Mahalliy DB | `sqflite` — foydalanuvchilar, buyurtmalar, feedback, murojaatlar |
| Kalit-qiymat | `shared_preferences` — sessiya, profil, bildirishnomalar, snapshotlar |
| Xarita | `flutter_map` ^7, `latlong2` |
| Tarmoq | `http` (Nominatim, OSRM) |
| Joylashuv | `geolocator` |
| Grafik | `fl_chart` |
| Shrift | `google_fonts` |

---

## 3. Katalog tuzilishi

```
lib/
├── main.dart              # SQLite bootstrap, ProviderScope, CourierApp
├── app.dart               # MaterialApp.router + routerProvider
├── core/
│   ├── routing/           # app_router.dart, app_routes.dart
│   ├── database/          # app_database.dart
│   ├── providers/       # core_providers.dart
│   ├── theme/             # app_theme.dart, tokens
│   ├── geo/, constants/, utils/
├── models/                # AppUser, JobEntity, JobStatus, …
├── repositories/          # Auth, Job, User, Feedback, SupportRequest, …
├── features/
│   ├── auth/              # splash, telefon, SMS, oferta, rol
│   ├── sender/            # bosh sahifa, wizard, profil, bildirishnomalar
│   ├── courier/           # buyurtmalar, xarita, profil
│   ├── admin/             # panel, statistika, foydalanuvchilar, xarita
│   ├── auction/           # auksion ekrani
│   ├── jobs/              # batafsil, xarita, feedback sheetlar
│   ├── map/               # manzil tanlash
│   └── settings/
├── services/              # locale, theme, nominatim, osrm, tarjima (mock)
├── shared/                # umumiy vidjetlar, map stillari, dialoglar
└── l10n/                  # app_*.arb, generated AppLocalizations
```

---

## 4. Foydalanuvchi rollari

| Rol | Bosh marshrut | Mazmuni |
|-----|---------------|---------|
| **Yuboruvchi** | `/sender` | Buyurtmalar (aktiv / jarayon / tugagan), yaratish, batafsil, auksion, profil, ilova ichidagi bildirishnomalar |
| **Kuryer** | `/courier` | Auksion ro‘yxati/xarita, jarayon, bajarilgan, profil (yorug‘ `Theme` bilan `SenderProfileTabContent`), rol almashtirish |
| **Admin** | `/admin` | Buyurtmalar, auksionlar, dashboard, foydalanuvchilar, xarita, murojaatlar (`canAccessAdminPanel`) |

Autentifikatsiya: telefon → SMS → oferta qabul → rol. Sessiya: `SharedPreferences` dagi `currentUserId` + SQLite dan foydalanuvchi.

---

## 5. Marshrutlar

| Yo‘l | Ma’nosi |
|------|---------|
| `/splash` | Splash, tarmoq / sessiya kutish |
| `/auth/phone`, `/auth/sms`, `/auth/offer`, `/auth/role` | Ro‘yxatdan o‘tish zanjiri |
| `/sender`, `/sender/create-job` | Yuboruvchi |
| `/map-picker` | Xarita orqali manzil |
| `/courier` | Kuryer paneli |
| `/admin`, `/admin/statistics`, `/admin/users`, `/admin/map`, `/admin/contact-requests` | Admin |
| `/job/:id`, `/job/:id/auction` | Buyurtma va auksion |
| `/settings` | Sozlamalar |

Router `authSessionProvider`, `splashHoldProvider`, `startupReachabilityProvider` o‘zgarishlarida qayta hisoblanadi.

---

## 6. Buyurtma statuslari

`JobStatus`: `posted` → `auctionLive` → `assigned` → `pickedUp` → `delivered` → `completed`; shuningdek `cancelled`.

Saqlash: SQLite `jobs` jadvali; repository orqali yangilanadi.

---

## 7. SharedPreferences kalitlari (muhim)

| Kalit / namuna | Vazifasi |
|----------------|----------|
| `current_user_id` (StorageKeys) | Sessiya; **logout** da olib tashlanadi |
| `profile_image_path_<userId>` | Profil rasmi fayl yo‘li |
| `profile_secondary_phone_<userId>` | Qo‘shimcha telefon |
| `sender_in_app_notifications_v1_<userId>` | Yuboruvchi bildirishnomalari (chiqishda saqlanadi) |
| `sender_job_status_snap_v1_<userId>` | Oxirgi statuslar — o‘tishdan bildirishnoma chiqarish |
| Locale / theme | `LocalePreferences`, `ThemePreferences` |

---

## 8. Tashqi servislar

- **Nominatim** — geokodlash (`services/geocoding/`)
- **OSRM** — marshrut chizig‘i (`services/routing/`)
- **OpenStreetMap** — xarita plitalari (`flutter_map`)

URL va foydalanish shartlari muhitga bog‘liq.

---

## 9. Yig‘ish va ishga tushirish

```bash
cd <loyiha_ildizi>
flutter pub get
flutter run
```

Lokalizatsiya: `flutter gen-l10n` (odatda `flutter run` bilan ishlaydi).

**Desktop:** `lib/core/bootstrap/sqlite_platform.dart` — `sqflite_common_ffi` sozlashi `main.dart` da chaqiriladi.

---

## 10. Cheklovlar va xavfsizlik eslatmalari

- Asosiy ma’lumotlar **mahalliy SQLite** da; qurilmalar o‘rtasida server sinxroni yo‘q.
- Push-notification va real backend API loyihada alohida qatlam sifatida ko‘rilishi kerak.
- Admin va maxsus sozlamalar telefon/email filtr bilan cheklangan bo‘lishi mumkin (`sender_home_settings_menu.dart` va hokazo).

---

## 11. Tekshiruv

```bash
flutter analyze
flutter test
```

Eslatma: ba’zi muhitlarda `flutter` ichki skriptlari `git` talab qiladi — PATH da `git` bo‘lishi kerak.

---

## 12. Bog‘liq fayllar

| Mavzu | Fayl |
|-------|------|
| Router | `lib/core/routing/app_router.dart`, `app_routes.dart` |
| Sessiya | `lib/core/providers/core_providers.dart` (`AuthSessionNotifier`) |
| Logout | `lib/repositories/auth_repository.dart` |
| Yuboruvchi bildirishnomalar | `lib/features/sender/data/sender_notifications_storage.dart`, `sender_job_status_snapshot_storage.dart` |
| Kuryer profil temasi | `lib/features/courier/presentation/courier_home_page.dart` (`AppTheme.light()` + `SenderProfileTabContent`) |

---

*Hujjat loyiha strukturasi va kod tahlili asosida tuzilgan; yangi modul qo‘shilganda yangilanishi tavsiya etiladi.*
