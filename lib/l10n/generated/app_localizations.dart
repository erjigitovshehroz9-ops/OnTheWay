import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uz.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
    Locale('uz')
  ];

  /// Ilova nomi
  ///
  /// In uz, this message translates to:
  /// **'Kuryer Auksion'**
  String get appTitle;

  /// No description provided for @splashTagline.
  ///
  /// In uz, this message translates to:
  /// **'Tez. Zamonaviy. Qulay yetkazib berish.'**
  String get splashTagline;

  /// No description provided for @getStarted.
  ///
  /// In uz, this message translates to:
  /// **'Boshlash'**
  String get getStarted;

  /// No description provided for @language.
  ///
  /// In uz, this message translates to:
  /// **'Til'**
  String get language;

  /// No description provided for @languageUzbek.
  ///
  /// In uz, this message translates to:
  /// **'Oʻzbekcha'**
  String get languageUzbek;

  /// No description provided for @languageRussian.
  ///
  /// In uz, this message translates to:
  /// **'Ruscha'**
  String get languageRussian;

  /// No description provided for @languageEnglish.
  ///
  /// In uz, this message translates to:
  /// **'Inglizcha'**
  String get languageEnglish;

  /// No description provided for @back.
  ///
  /// In uz, this message translates to:
  /// **'Orqaga'**
  String get back;

  /// No description provided for @continueWord.
  ///
  /// In uz, this message translates to:
  /// **'Davom etish'**
  String get continueWord;

  /// No description provided for @save.
  ///
  /// In uz, this message translates to:
  /// **'Saqlash'**
  String get save;

  /// No description provided for @retry.
  ///
  /// In uz, this message translates to:
  /// **'Qayta urinish'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In uz, this message translates to:
  /// **'Yuklanmoqda…'**
  String get loading;

  /// No description provided for @errorGeneric.
  ///
  /// In uz, this message translates to:
  /// **'Nomaʼlum xatolik'**
  String get errorGeneric;

  /// No description provided for @phoneLoginTitle.
  ///
  /// In uz, this message translates to:
  /// **'Telefon raqamingiz'**
  String get phoneLoginTitle;

  /// No description provided for @phoneHint.
  ///
  /// In uz, this message translates to:
  /// **'+998 __ ___ __ __'**
  String get phoneHint;

  /// No description provided for @sendCode.
  ///
  /// In uz, this message translates to:
  /// **'Kod yuborish'**
  String get sendCode;

  /// No description provided for @errorInvalidPhone.
  ///
  /// In uz, this message translates to:
  /// **'Toʻgʻri telefon raqamini kiriting'**
  String get errorInvalidPhone;

  /// No description provided for @smsTitle.
  ///
  /// In uz, this message translates to:
  /// **'SMS tasdiqlash'**
  String get smsTitle;

  /// No description provided for @smsSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Raqamingizga yuborilgan kodni kiriting'**
  String get smsSubtitle;

  /// No description provided for @verify.
  ///
  /// In uz, this message translates to:
  /// **'Tasdiqlash'**
  String get verify;

  /// No description provided for @resendCode.
  ///
  /// In uz, this message translates to:
  /// **'Kodni qayta yuborish'**
  String get resendCode;

  /// No description provided for @errorInvalidCode.
  ///
  /// In uz, this message translates to:
  /// **'Kod notoʻgʻri yoki muddati oʻtgan'**
  String get errorInvalidCode;

  /// No description provided for @offerTitle.
  ///
  /// In uz, this message translates to:
  /// **'Ommaviy oferta'**
  String get offerTitle;

  /// No description provided for @offerWelcome.
  ///
  /// In uz, this message translates to:
  /// **'Xush kelibsiz'**
  String get offerWelcome;

  /// No description provided for @offerBody.
  ///
  /// In uz, this message translates to:
  /// **'Ushbu oferta shartnomada xizmat koʻrsatish, toʻlovlar, javobgarlik va maʼlumotlarni qayta ishlash qoidalari bayon etilgan. Ofertaga rozilik bildirmasangiz, roʻyxatdan oʻtishni davom ettira olmaysiz.'**
  String get offerBody;

  /// No description provided for @offerAcceptCheckbox.
  ///
  /// In uz, this message translates to:
  /// **'Oferta shartlariga roziman'**
  String get offerAcceptCheckbox;

  /// No description provided for @acceptAndContinue.
  ///
  /// In uz, this message translates to:
  /// **'Qabul qilish va davom etish'**
  String get acceptAndContinue;

  /// No description provided for @errorMustAcceptOffer.
  ///
  /// In uz, this message translates to:
  /// **'Davom etish uchun ofertaga rozilik bildiring'**
  String get errorMustAcceptOffer;

  /// No description provided for @chooseRoleTitle.
  ///
  /// In uz, this message translates to:
  /// **'Rolingizni tanlang'**
  String get chooseRoleTitle;

  /// No description provided for @roleSender.
  ///
  /// In uz, this message translates to:
  /// **'Yuboruvchi'**
  String get roleSender;

  /// No description provided for @roleSenderDesc.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma yaratish va kuryer tanlash'**
  String get roleSenderDesc;

  /// No description provided for @roleCourier.
  ///
  /// In uz, this message translates to:
  /// **'Kuryer'**
  String get roleCourier;

  /// No description provided for @roleCourierDesc.
  ///
  /// In uz, this message translates to:
  /// **'Auksionda ishtirok etish'**
  String get roleCourierDesc;

  /// No description provided for @roleAdmin.
  ///
  /// In uz, this message translates to:
  /// **'Administrator'**
  String get roleAdmin;

  /// No description provided for @roleAdminDesc.
  ///
  /// In uz, this message translates to:
  /// **'Platformani boshqarish'**
  String get roleAdminDesc;

  /// No description provided for @confirmRole.
  ///
  /// In uz, this message translates to:
  /// **'Tanlash'**
  String get confirmRole;

  /// No description provided for @senderHomeTitle.
  ///
  /// In uz, this message translates to:
  /// **'Bosh sahifa'**
  String get senderHomeTitle;

  /// No description provided for @courierHomeTitle.
  ///
  /// In uz, this message translates to:
  /// **'Kuryer paneli'**
  String get courierHomeTitle;

  /// No description provided for @adminHomeTitle.
  ///
  /// In uz, this message translates to:
  /// **'Admin paneli'**
  String get adminHomeTitle;

  /// No description provided for @whereToHint.
  ///
  /// In uz, this message translates to:
  /// **'Qayerga yetkazish kerak?'**
  String get whereToHint;

  /// No description provided for @createJob.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma yaratish'**
  String get createJob;

  /// No description provided for @nearbyCouriers.
  ///
  /// In uz, this message translates to:
  /// **'Yaqin atrofdagi kuryerlar'**
  String get nearbyCouriers;

  /// No description provided for @activeJobs.
  ///
  /// In uz, this message translates to:
  /// **'Faol buyurtmalar'**
  String get activeJobs;

  /// No description provided for @demoJobCardTitle.
  ///
  /// In uz, this message translates to:
  /// **'Namuna buyurtma'**
  String get demoJobCardTitle;

  /// No description provided for @contactsHiddenUntilAuction.
  ///
  /// In uz, this message translates to:
  /// **'Auksion tugaguncha aloqa maʼlumotlari yashirin'**
  String get contactsHiddenUntilAuction;

  /// No description provided for @contactsVisibleAfterWinner.
  ///
  /// In uz, this message translates to:
  /// **'Gʻolib tanlangach telefon va chat ochiladi'**
  String get contactsVisibleAfterWinner;

  /// No description provided for @auctionStatusLive.
  ///
  /// In uz, this message translates to:
  /// **'Auksion jonli'**
  String get auctionStatusLive;

  /// No description provided for @auctionStatusEnded.
  ///
  /// In uz, this message translates to:
  /// **'Auksion yakunlandi'**
  String get auctionStatusEnded;

  /// No description provided for @winnerSelected.
  ///
  /// In uz, this message translates to:
  /// **'Gʻolib tanlandi'**
  String get winnerSelected;

  /// No description provided for @topBid.
  ///
  /// In uz, this message translates to:
  /// **'Eng yuqori taklif'**
  String get topBid;

  /// No description provided for @timeLeft.
  ///
  /// In uz, this message translates to:
  /// **'Qolgan vaqt'**
  String get timeLeft;

  /// No description provided for @secondsShort.
  ///
  /// In uz, this message translates to:
  /// **'{count} s'**
  String secondsShort(int count);

  /// No description provided for @placeBid.
  ///
  /// In uz, this message translates to:
  /// **'Taklif berish'**
  String get placeBid;

  /// No description provided for @jobDescriptionLabel.
  ///
  /// In uz, this message translates to:
  /// **'Izoh'**
  String get jobDescriptionLabel;

  /// No description provided for @jobTitleLabel.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma nomi'**
  String get jobTitleLabel;

  /// No description provided for @translateDemoHint.
  ///
  /// In uz, this message translates to:
  /// **'Matn kiriting — 3 tilda saqlanadi (demo tarjima)'**
  String get translateDemoHint;

  /// No description provided for @previewForLocale.
  ///
  /// In uz, this message translates to:
  /// **'Tanlangan tilda koʻrinishi'**
  String get previewForLocale;

  /// No description provided for @storedUz.
  ///
  /// In uz, this message translates to:
  /// **'Asl (oʻzbekcha)'**
  String get storedUz;

  /// No description provided for @storedRu.
  ///
  /// In uz, this message translates to:
  /// **'Saqlangan ruscha'**
  String get storedRu;

  /// No description provided for @storedEn.
  ///
  /// In uz, this message translates to:
  /// **'Saqlangan inglizcha'**
  String get storedEn;

  /// No description provided for @logout.
  ///
  /// In uz, this message translates to:
  /// **'Chiqish'**
  String get logout;

  /// No description provided for @settings.
  ///
  /// In uz, this message translates to:
  /// **'Sozlamalar'**
  String get settings;

  /// No description provided for @userDemoName.
  ///
  /// In uz, this message translates to:
  /// **'Foydalanuvchi'**
  String get userDemoName;

  /// No description provided for @selectWinner.
  ///
  /// In uz, this message translates to:
  /// **'Gʻolibni tanlash'**
  String get selectWinner;

  /// No description provided for @signInRequired.
  ///
  /// In uz, this message translates to:
  /// **'Avtorizatsiyadan oʻting'**
  String get signInRequired;

  /// No description provided for @noOpenAuctions.
  ///
  /// In uz, this message translates to:
  /// **'Hozircha ochiq auksion yoʻq'**
  String get noOpenAuctions;

  /// No description provided for @courierOrdersTabAuction.
  ///
  /// In uz, this message translates to:
  /// **'Ro\'yxat'**
  String get courierOrdersTabAuction;

  /// No description provided for @courierOrdersSubtabList.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtmalar'**
  String get courierOrdersSubtabList;

  /// No description provided for @courierOrdersTabInProgress.
  ///
  /// In uz, this message translates to:
  /// **'Jarayonda'**
  String get courierOrdersTabInProgress;

  /// No description provided for @courierOrdersTabCompleted.
  ///
  /// In uz, this message translates to:
  /// **'Bajarilgan'**
  String get courierOrdersTabCompleted;

  /// No description provided for @courierOrdersEmptyInProgress.
  ///
  /// In uz, this message translates to:
  /// **'Hozircha jarayondagi buyurtmalar yoʻq. Auksion tugagach, siz gʻolib boʻlsangiz, ular shu yerda chiqadi.'**
  String get courierOrdersEmptyInProgress;

  /// No description provided for @courierOrdersEmptyCompleted.
  ///
  /// In uz, this message translates to:
  /// **'Hozircha bajarilgan buyurtmalar yoʻq.'**
  String get courierOrdersEmptyCompleted;

  /// No description provided for @adminDashboard.
  ///
  /// In uz, this message translates to:
  /// **'Admin panel'**
  String get adminDashboard;

  /// No description provided for @adminStatistics.
  ///
  /// In uz, this message translates to:
  /// **'Statistika'**
  String get adminStatistics;

  /// No description provided for @adminUsers.
  ///
  /// In uz, this message translates to:
  /// **'Foydalanuvchilar'**
  String get adminUsers;

  /// No description provided for @adminLiveMap.
  ///
  /// In uz, this message translates to:
  /// **'Jonli xarita'**
  String get adminLiveMap;

  /// No description provided for @adminSectionOverview.
  ///
  /// In uz, this message translates to:
  /// **'Asosiy ko\'rsatkichlar'**
  String get adminSectionOverview;

  /// No description provided for @adminSectionOrders.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtmalar va auksionlar'**
  String get adminSectionOrders;

  /// No description provided for @adminSectionUsersSecurity.
  ///
  /// In uz, this message translates to:
  /// **'Foydalanuvchilar va xavfsizlik'**
  String get adminSectionUsersSecurity;

  /// No description provided for @adminSectionShortcuts.
  ///
  /// In uz, this message translates to:
  /// **'Tezkor boshqaruv'**
  String get adminSectionShortcuts;

  /// No description provided for @adminChartOrderStatus.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtmalar taqsimoti'**
  String get adminChartOrderStatus;

  /// No description provided for @adminNavStatsSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Viloyatlar bo\'yicha tahlil'**
  String get adminNavStatsSubtitle;

  /// No description provided for @adminNavUsersSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Rollar va bloklash'**
  String get adminNavUsersSubtitle;

  /// No description provided for @adminNavMapSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Kuryerlar joylashuvi'**
  String get adminNavMapSubtitle;

  /// No description provided for @adminMapMarkerCount.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta kuryer nuqtasi'**
  String adminMapMarkerCount(int count);

  /// No description provided for @adminMapEmptyNoJobsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Jonli kuzatuv yo‘q'**
  String get adminMapEmptyNoJobsTitle;

  /// No description provided for @adminMapEmptyNoJobsBody.
  ///
  /// In uz, this message translates to:
  /// **'Hozircha faol kuzatuvdagi buyurtmalar yo‘q. Bir ozdan keyin yangilang.'**
  String get adminMapEmptyNoJobsBody;

  /// No description provided for @adminMapEmptyNoGpsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Joylashuv kelmagan'**
  String get adminMapEmptyNoGpsTitle;

  /// No description provided for @adminMapEmptyNoGpsBody.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtmalar bor, lekin kuryerlar joylashuvi hali yuborilmagan.'**
  String get adminMapEmptyNoGpsBody;

  /// No description provided for @chartLegendCompleted.
  ///
  /// In uz, this message translates to:
  /// **'Bajarilgan'**
  String get chartLegendCompleted;

  /// No description provided for @chartLegendActive.
  ///
  /// In uz, this message translates to:
  /// **'Jarayonda'**
  String get chartLegendActive;

  /// No description provided for @chartLegendCancelled.
  ///
  /// In uz, this message translates to:
  /// **'Bekor qilingan'**
  String get chartLegendCancelled;

  /// No description provided for @statTotalUsers.
  ///
  /// In uz, this message translates to:
  /// **'Jami foydalanuvchilar'**
  String get statTotalUsers;

  /// No description provided for @statSenders.
  ///
  /// In uz, this message translates to:
  /// **'Yuboruvchilar soni'**
  String get statSenders;

  /// No description provided for @statCouriers.
  ///
  /// In uz, this message translates to:
  /// **'Kuryerlar soni'**
  String get statCouriers;

  /// No description provided for @statActiveJobs.
  ///
  /// In uz, this message translates to:
  /// **'Faol buyurtmalar'**
  String get statActiveJobs;

  /// No description provided for @statLiveAuctions.
  ///
  /// In uz, this message translates to:
  /// **'Faol auksionlar'**
  String get statLiveAuctions;

  /// No description provided for @statCompleted.
  ///
  /// In uz, this message translates to:
  /// **'Bajarilgan buyurtmalar'**
  String get statCompleted;

  /// No description provided for @statUncompletedJobs.
  ///
  /// In uz, this message translates to:
  /// **'Bajarilmagan buyurtmalar'**
  String get statUncompletedJobs;

  /// No description provided for @statCancelled.
  ///
  /// In uz, this message translates to:
  /// **'Bekor qilingan'**
  String get statCancelled;

  /// No description provided for @statBlocked.
  ///
  /// In uz, this message translates to:
  /// **'Bloklangan foydalanuvchilar'**
  String get statBlocked;

  /// No description provided for @statComplaints.
  ///
  /// In uz, this message translates to:
  /// **'Shikoyatlar soni'**
  String get statComplaints;

  /// No description provided for @noJobsFound.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtmalar topilmadi'**
  String get noJobsFound;

  /// No description provided for @regionLabel.
  ///
  /// In uz, this message translates to:
  /// **'Viloyat'**
  String get regionLabel;

  /// No description provided for @districtLabel.
  ///
  /// In uz, this message translates to:
  /// **'Tuman/Shahar'**
  String get districtLabel;

  /// No description provided for @tabList.
  ///
  /// In uz, this message translates to:
  /// **'Ro‘yxat'**
  String get tabList;

  /// No description provided for @tabMap.
  ///
  /// In uz, this message translates to:
  /// **'Xarita'**
  String get tabMap;

  /// No description provided for @courierMapNoOrdersInDistrict.
  ///
  /// In uz, this message translates to:
  /// **'Bu hududda buyurtmalar topilmadi'**
  String get courierMapNoOrdersInDistrict;

  /// No description provided for @courierMapOpenDetail.
  ///
  /// In uz, this message translates to:
  /// **'Batafsil'**
  String get courierMapOpenDetail;

  /// No description provided for @courierMapCoordsShort.
  ///
  /// In uz, this message translates to:
  /// **'{lat}, {lng}'**
  String courierMapCoordsShort(String lat, String lng);

  /// No description provided for @courierPanelBannerTitle.
  ///
  /// In uz, this message translates to:
  /// **'KURYER PANELI'**
  String get courierPanelBannerTitle;

  /// No description provided for @courierGreeting.
  ///
  /// In uz, this message translates to:
  /// **'Assalomu alaykum, {name}!'**
  String courierGreeting(String name);

  /// No description provided for @courierNavHome.
  ///
  /// In uz, this message translates to:
  /// **'Bosh sahifa'**
  String get courierNavHome;

  /// No description provided for @courierNavOrders.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtmalar'**
  String get courierNavOrders;

  /// No description provided for @courierNavMaps.
  ///
  /// In uz, this message translates to:
  /// **'Xaritalar'**
  String get courierNavMaps;

  /// No description provided for @courierNavAccount.
  ///
  /// In uz, this message translates to:
  /// **'Mening hisobim'**
  String get courierNavAccount;

  /// No description provided for @senderBottomNavSwitchRole.
  ///
  /// In uz, this message translates to:
  /// **'Rolni almashtirish'**
  String get senderBottomNavSwitchRole;

  /// No description provided for @bottomNavWallet.
  ///
  /// In uz, this message translates to:
  /// **'Hisobim'**
  String get bottomNavWallet;

  /// No description provided for @courierCardCreated.
  ///
  /// In uz, this message translates to:
  /// **'Yaratilgan vaqti'**
  String get courierCardCreated;

  /// No description provided for @courierStatusWaiting.
  ///
  /// In uz, this message translates to:
  /// **'Kutish jarayonida'**
  String get courierStatusWaiting;

  /// No description provided for @courierDeliveredBadge.
  ///
  /// In uz, this message translates to:
  /// **'Yetkazilgan'**
  String get courierDeliveredBadge;

  /// No description provided for @courierCardIdLabel.
  ///
  /// In uz, this message translates to:
  /// **'ID'**
  String get courierCardIdLabel;

  /// No description provided for @jobDetails.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma tafsilotlari'**
  String get jobDetails;

  /// No description provided for @jobDetailProductInfoTitle.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulot ma\'lumotlari'**
  String get jobDetailProductInfoTitle;

  /// No description provided for @jobDetailNoProductImage.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulot rasmi yuklanmagan'**
  String get jobDetailNoProductImage;

  /// No description provided for @jobDetailVolumeShort.
  ///
  /// In uz, this message translates to:
  /// **'Hajmi'**
  String get jobDetailVolumeShort;

  /// No description provided for @pickupLocation.
  ///
  /// In uz, this message translates to:
  /// **'Qayerdan olinadi'**
  String get pickupLocation;

  /// No description provided for @dropoffLocation.
  ///
  /// In uz, this message translates to:
  /// **'Qayerga yetkaziladi'**
  String get dropoffLocation;

  /// No description provided for @mapDualFlowCardTitle.
  ///
  /// In uz, this message translates to:
  /// **'Manzillarni xaritada belgilang'**
  String get mapDualFlowCardTitle;

  /// No description provided for @mapPickerNextDropoff.
  ///
  /// In uz, this message translates to:
  /// **'Keyingi: yetkazish manzili'**
  String get mapPickerNextDropoff;

  /// No description provided for @mapPickerConfirmBoth.
  ///
  /// In uz, this message translates to:
  /// **'Manzillarni tasdiqlash'**
  String get mapPickerConfirmBoth;

  /// No description provided for @recipientNameLabel.
  ///
  /// In uz, this message translates to:
  /// **'Qabul qiluvchi ismi'**
  String get recipientNameLabel;

  /// No description provided for @recipientPhoneLabel.
  ///
  /// In uz, this message translates to:
  /// **'Qabul qiluvchi telefoni'**
  String get recipientPhoneLabel;

  /// No description provided for @recipientPhoneHelper.
  ///
  /// In uz, this message translates to:
  /// **'+998 yozuvi qatʼiy. Keyingi 9 ta raqamni toʻgʻri kiriting — aks holda kuryer qo‘ng‘iroq qila olmasligi mumkin.'**
  String get recipientPhoneHelper;

  /// No description provided for @joinAuctionCta.
  ///
  /// In uz, this message translates to:
  /// **'Auksionga qo‘shilish'**
  String get joinAuctionCta;

  /// No description provided for @acceptLowerPrice.
  ///
  /// In uz, this message translates to:
  /// **'Narxni qabul qilish'**
  String get acceptLowerPrice;

  /// No description provided for @statusAuction.
  ///
  /// In uz, this message translates to:
  /// **'Auksion'**
  String get statusAuction;

  /// No description provided for @statusCompleted.
  ///
  /// In uz, this message translates to:
  /// **'Bajarildi'**
  String get statusCompleted;

  /// No description provided for @complaint.
  ///
  /// In uz, this message translates to:
  /// **'Shikoyat'**
  String get complaint;

  /// No description provided for @praise.
  ///
  /// In uz, this message translates to:
  /// **'Maqtov'**
  String get praise;

  /// No description provided for @mapSearch.
  ///
  /// In uz, this message translates to:
  /// **'Qidiruv'**
  String get mapSearch;

  /// No description provided for @selectedLocation.
  ///
  /// In uz, this message translates to:
  /// **'Tanlangan joy'**
  String get selectedLocation;

  /// No description provided for @recenterMap.
  ///
  /// In uz, this message translates to:
  /// **'Markazga qaytarish'**
  String get recenterMap;

  /// No description provided for @blockUser.
  ///
  /// In uz, this message translates to:
  /// **'Foydalanuvchini bloklash'**
  String get blockUser;

  /// No description provided for @auctionCurrentOffer.
  ///
  /// In uz, this message translates to:
  /// **'Joriy taklif'**
  String get auctionCurrentOffer;

  /// No description provided for @auctionFloor.
  ///
  /// In uz, this message translates to:
  /// **'Minimal narx'**
  String get auctionFloor;

  /// No description provided for @timeLeftShort.
  ///
  /// In uz, this message translates to:
  /// **'Qolgan vaqt'**
  String get timeLeftShort;

  /// No description provided for @auctionHistory.
  ///
  /// In uz, this message translates to:
  /// **'Auksion tarixi'**
  String get auctionHistory;

  /// No description provided for @auctionLiveScreenTitle.
  ///
  /// In uz, this message translates to:
  /// **'Jonli auksion'**
  String get auctionLiveScreenTitle;

  /// No description provided for @auctionOngoingLabel.
  ///
  /// In uz, this message translates to:
  /// **'Auksion davom etmoqda'**
  String get auctionOngoingLabel;

  /// No description provided for @auctionWaitingStartLabel.
  ///
  /// In uz, this message translates to:
  /// **'Auksion boshlanishi kutilmoqda'**
  String get auctionWaitingStartLabel;

  /// No description provided for @auctionTimeLeftLine.
  ///
  /// In uz, this message translates to:
  /// **'{time} qoldi'**
  String auctionTimeLeftLine(String time);

  /// No description provided for @auctionCouriersParticipatingCount.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta kuryer ishtirok etmoqda'**
  String auctionCouriersParticipatingCount(int count);

  /// No description provided for @auctionOrderDetailsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma tafsilotlari'**
  String get auctionOrderDetailsTitle;

  /// No description provided for @auctionPickupMapLabel.
  ///
  /// In uz, this message translates to:
  /// **'Olish:'**
  String get auctionPickupMapLabel;

  /// No description provided for @auctionDropoffMapLabel.
  ///
  /// In uz, this message translates to:
  /// **'Yetkazish:'**
  String get auctionDropoffMapLabel;

  /// No description provided for @auctionRouteDistance.
  ///
  /// In uz, this message translates to:
  /// **'{km} km'**
  String auctionRouteDistance(String km);

  /// No description provided for @auctionSenderTrustTitle.
  ///
  /// In uz, this message translates to:
  /// **'Yuboruvchi haqida'**
  String get auctionSenderTrustTitle;

  /// No description provided for @auctionCourierRatingsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Kuryerlar reytingi'**
  String get auctionCourierRatingsTitle;

  /// No description provided for @auctionAgreePriceCta.
  ///
  /// In uz, this message translates to:
  /// **'Narxga roziman →'**
  String get auctionAgreePriceCta;

  /// No description provided for @auctionWatchCta.
  ///
  /// In uz, this message translates to:
  /// **'Kuzatish'**
  String get auctionWatchCta;

  /// No description provided for @auctionParticipateOutlined.
  ///
  /// In uz, this message translates to:
  /// **'Ishtirok etish'**
  String get auctionParticipateOutlined;

  /// No description provided for @auctionYouAreLeading.
  ///
  /// In uz, this message translates to:
  /// **'Siz yetakchisiz'**
  String get auctionYouAreLeading;

  /// No description provided for @auctionReviewsCount.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta sharh'**
  String auctionReviewsCount(int count);

  /// No description provided for @auctionStartPriceLabel.
  ///
  /// In uz, this message translates to:
  /// **'Boshlang‘ich narx'**
  String get auctionStartPriceLabel;

  /// No description provided for @auctionHozirgiTaklif.
  ///
  /// In uz, this message translates to:
  /// **'Hozirgi taklif'**
  String get auctionHozirgiTaklif;

  /// No description provided for @auctionYourPriceLabel.
  ///
  /// In uz, this message translates to:
  /// **'Siz qabul qilgan narx'**
  String get auctionYourPriceLabel;

  /// No description provided for @auctionNextOfferLabel.
  ///
  /// In uz, this message translates to:
  /// **'Keyingi taklif («Narxga roziman»)'**
  String get auctionNextOfferLabel;

  /// No description provided for @auctionEndedYouWonBody.
  ///
  /// In uz, this message translates to:
  /// **'Tabriklaymiz! Buyurtma sizga biriktirildi. Buyurtmalar roʻyxatida davom eting.'**
  String get auctionEndedYouWonBody;

  /// No description provided for @auctionEndedOtherWinnerBody.
  ///
  /// In uz, this message translates to:
  /// **'Auksion boshqa kuryer foydasiga yakunlandi.'**
  String get auctionEndedOtherWinnerBody;

  /// No description provided for @auctionEndedNoWinnerBody.
  ///
  /// In uz, this message translates to:
  /// **'Vaqt tugadi. Buyurtma qayta ochiq auksion uchun qoldi.'**
  String get auctionEndedNoWinnerBody;

  /// No description provided for @auctionEndedGenericBody.
  ///
  /// In uz, this message translates to:
  /// **'Auksion yakunlandi.'**
  String get auctionEndedGenericBody;

  /// No description provided for @chooseRoleSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Ilovadan qanday foydalanmoqchisiz?'**
  String get chooseRoleSubtitle;

  /// No description provided for @stepProduct.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulot'**
  String get stepProduct;

  /// No description provided for @stepAddresses.
  ///
  /// In uz, this message translates to:
  /// **'Manzillar'**
  String get stepAddresses;

  /// No description provided for @stepRecipient.
  ///
  /// In uz, this message translates to:
  /// **'Qabul qiluvchi'**
  String get stepRecipient;

  /// No description provided for @stepReview.
  ///
  /// In uz, this message translates to:
  /// **'Tekshirish'**
  String get stepReview;

  /// No description provided for @fragileItem.
  ///
  /// In uz, this message translates to:
  /// **'Nozik mahsulot'**
  String get fragileItem;

  /// No description provided for @needsColdChain.
  ///
  /// In uz, this message translates to:
  /// **'Sovuq saqlash'**
  String get needsColdChain;

  /// No description provided for @completedJobsLabel.
  ///
  /// In uz, this message translates to:
  /// **'Bajarilgan ishlar'**
  String get completedJobsLabel;

  /// No description provided for @markPickedUp.
  ///
  /// In uz, this message translates to:
  /// **'Qabul qildim'**
  String get markPickedUp;

  /// No description provided for @markDelivered.
  ///
  /// In uz, this message translates to:
  /// **'Yetkazib berdim'**
  String get markDelivered;

  /// No description provided for @orderContactSectionTitle.
  ///
  /// In uz, this message translates to:
  /// **'Bog‘lanish ma’lumotlari'**
  String get orderContactSectionTitle;

  /// No description provided for @orderWinnerOutcomeTitle.
  ///
  /// In uz, this message translates to:
  /// **'G‘olib aniqlandi'**
  String get orderWinnerOutcomeTitle;

  /// No description provided for @orderFinalPriceLabel.
  ///
  /// In uz, this message translates to:
  /// **'Yakuniy narx'**
  String get orderFinalPriceLabel;

  /// No description provided for @orderWinnerSelectedAtLabel.
  ///
  /// In uz, this message translates to:
  /// **'Tanlangan vaqt'**
  String get orderWinnerSelectedAtLabel;

  /// No description provided for @orderAuctionStepsCountLabel.
  ///
  /// In uz, this message translates to:
  /// **'Auksion qadamlari'**
  String get orderAuctionStepsCountLabel;

  /// No description provided for @orderAddressesHiddenForNonWinner.
  ///
  /// In uz, this message translates to:
  /// **'Manzillar faqat auksion g‘olibiga ko‘rinadi.'**
  String get orderAddressesHiddenForNonWinner;

  /// No description provided for @courierRatingStarsLabel.
  ///
  /// In uz, this message translates to:
  /// **'Reyting: {value}'**
  String courierRatingStarsLabel(String value);

  /// No description provided for @deliveryNoteOptional.
  ///
  /// In uz, this message translates to:
  /// **'Izoh (ixtiyoriy)'**
  String get deliveryNoteOptional;

  /// No description provided for @submitFeedback.
  ///
  /// In uz, this message translates to:
  /// **'Fikr bildirish'**
  String get submitFeedback;

  /// No description provided for @feedbackComplaintTitle.
  ///
  /// In uz, this message translates to:
  /// **'Shikoyatingizni yozing'**
  String get feedbackComplaintTitle;

  /// No description provided for @feedbackComplaintHint.
  ///
  /// In uz, this message translates to:
  /// **'Nima bo‘lganini qisqacha tushuntiring…'**
  String get feedbackComplaintHint;

  /// No description provided for @feedbackPraiseTitle.
  ///
  /// In uz, this message translates to:
  /// **'Minnatdorchilik'**
  String get feedbackPraiseTitle;

  /// No description provided for @feedbackPraiseStarsHint.
  ///
  /// In uz, this message translates to:
  /// **'1–5 yulduz bilan baholang'**
  String get feedbackPraiseStarsHint;

  /// No description provided for @feedbackPraiseEmojiHint.
  ///
  /// In uz, this message translates to:
  /// **'Yoki smayl bilan:'**
  String get feedbackPraiseEmojiHint;

  /// No description provided for @feedbackSend.
  ///
  /// In uz, this message translates to:
  /// **'Yuborish'**
  String get feedbackSend;

  /// No description provided for @feedbackSentThanks.
  ///
  /// In uz, this message translates to:
  /// **'Rahmat, fikringiz qabul qilindi'**
  String get feedbackSentThanks;

  /// No description provided for @feedbackAlreadySubmitted.
  ///
  /// In uz, this message translates to:
  /// **'Bu buyurtma uchun siz allaqachon fikr bildirgansiz (shikoyat yoki maqtov — bir marta).'**
  String get feedbackAlreadySubmitted;

  /// No description provided for @rateCourierCta.
  ///
  /// In uz, this message translates to:
  /// **'Kuryerni baholash'**
  String get rateCourierCta;

  /// No description provided for @rateSenderCta.
  ///
  /// In uz, this message translates to:
  /// **'Yuboruvchini baholash'**
  String get rateSenderCta;

  /// No description provided for @orderFeedbackSheetTitleCourier.
  ///
  /// In uz, this message translates to:
  /// **'Kuryerni baholang'**
  String get orderFeedbackSheetTitleCourier;

  /// No description provided for @orderFeedbackSheetTitleSender.
  ///
  /// In uz, this message translates to:
  /// **'Yuboruvchini baholang'**
  String get orderFeedbackSheetTitleSender;

  /// No description provided for @orderFeedbackStarsLabel.
  ///
  /// In uz, this message translates to:
  /// **'Baholash (1–5 yulduz, majburiy)'**
  String get orderFeedbackStarsLabel;

  /// No description provided for @orderFeedbackTypeNeutral.
  ///
  /// In uz, this message translates to:
  /// **'Faqat baho'**
  String get orderFeedbackTypeNeutral;

  /// No description provided for @orderFeedbackTypeComplaint.
  ///
  /// In uz, this message translates to:
  /// **'Shikoyat'**
  String get orderFeedbackTypeComplaint;

  /// No description provided for @orderFeedbackTypePraise.
  ///
  /// In uz, this message translates to:
  /// **'Maqtov'**
  String get orderFeedbackTypePraise;

  /// No description provided for @orderFeedbackCommentOptional.
  ///
  /// In uz, this message translates to:
  /// **'Izoh (ixtiyoriy)'**
  String get orderFeedbackCommentOptional;

  /// No description provided for @orderFeedbackYourSummaryTitle.
  ///
  /// In uz, this message translates to:
  /// **'Sizning bahoyingiz'**
  String get orderFeedbackYourSummaryTitle;

  /// No description provided for @orderFeedbackSummaryRating.
  ///
  /// In uz, this message translates to:
  /// **'{stars} / 5'**
  String orderFeedbackSummaryRating(int stars);

  /// No description provided for @orderFeedbackSummaryTypeRating.
  ///
  /// In uz, this message translates to:
  /// **'Baho'**
  String get orderFeedbackSummaryTypeRating;

  /// No description provided for @orderFeedbackSummaryTypeComplaint.
  ///
  /// In uz, this message translates to:
  /// **'Shikoyat'**
  String get orderFeedbackSummaryTypeComplaint;

  /// No description provided for @orderFeedbackSummaryTypePraise.
  ///
  /// In uz, this message translates to:
  /// **'Maqtov'**
  String get orderFeedbackSummaryTypePraise;

  /// No description provided for @orderFeedbackSummaryCategory.
  ///
  /// In uz, this message translates to:
  /// **'Kategoriya: {name}'**
  String orderFeedbackSummaryCategory(String name);

  /// No description provided for @fbCatComplaintLate.
  ///
  /// In uz, this message translates to:
  /// **'Kechikdi'**
  String get fbCatComplaintLate;

  /// No description provided for @fbCatComplaintRude.
  ///
  /// In uz, this message translates to:
  /// **'Muomala yomon'**
  String get fbCatComplaintRude;

  /// No description provided for @fbCatComplaintCareless.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtmaga ehtiyotsiz munosabat'**
  String get fbCatComplaintCareless;

  /// No description provided for @fbCatComplaintAddress.
  ///
  /// In uz, this message translates to:
  /// **'Manzil muammosi'**
  String get fbCatComplaintAddress;

  /// No description provided for @fbCatOther.
  ///
  /// In uz, this message translates to:
  /// **'Boshqa'**
  String get fbCatOther;

  /// No description provided for @fbCatPraiseFast.
  ///
  /// In uz, this message translates to:
  /// **'Tez yetkazdi'**
  String get fbCatPraiseFast;

  /// No description provided for @fbCatPraisePolite.
  ///
  /// In uz, this message translates to:
  /// **'Xushmuomala'**
  String get fbCatPraisePolite;

  /// No description provided for @fbCatPraiseCareful.
  ///
  /// In uz, this message translates to:
  /// **'Ehtiyotkor'**
  String get fbCatPraiseCareful;

  /// No description provided for @fbCatPraiseReliable.
  ///
  /// In uz, this message translates to:
  /// **'Aniq va ishonchli'**
  String get fbCatPraiseReliable;

  /// No description provided for @catComplaintLate.
  ///
  /// In uz, this message translates to:
  /// **'Kechikdi'**
  String get catComplaintLate;

  /// No description provided for @catComplaintDamaged.
  ///
  /// In uz, this message translates to:
  /// **'Zarar yetdi'**
  String get catComplaintDamaged;

  /// No description provided for @catComplaintCommunication.
  ///
  /// In uz, this message translates to:
  /// **'Yomon aloqa'**
  String get catComplaintCommunication;

  /// No description provided for @catPraiseFast.
  ///
  /// In uz, this message translates to:
  /// **'Tez yetkazdi'**
  String get catPraiseFast;

  /// No description provided for @catPraisePolite.
  ///
  /// In uz, this message translates to:
  /// **'Xushmuomala'**
  String get catPraisePolite;

  /// No description provided for @catPraiseCareful.
  ///
  /// In uz, this message translates to:
  /// **'Ehtiyotkor'**
  String get catPraiseCareful;

  /// No description provided for @feedbackCategory.
  ///
  /// In uz, this message translates to:
  /// **'Kategoriya'**
  String get feedbackCategory;

  /// No description provided for @validationRequired.
  ///
  /// In uz, this message translates to:
  /// **'Majburiy maydon'**
  String get validationRequired;

  /// No description provided for @fieldOptionalHint.
  ///
  /// In uz, this message translates to:
  /// **'Ixtiyoriy'**
  String get fieldOptionalHint;

  /// No description provided for @createOrderTitle.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma yaratish'**
  String get createOrderTitle;

  /// No description provided for @createJobConfirmTitle.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtmani tasdiqlash'**
  String get createJobConfirmTitle;

  /// No description provided for @createJobSenderAddressLabel.
  ///
  /// In uz, this message translates to:
  /// **'Yuboruvchi manzili'**
  String get createJobSenderAddressLabel;

  /// No description provided for @createJobReceiverAddressLabel.
  ///
  /// In uz, this message translates to:
  /// **'Qabul qiluvchi manzili'**
  String get createJobReceiverAddressLabel;

  /// No description provided for @createJobDeliveryTimeSection.
  ///
  /// In uz, this message translates to:
  /// **'Yetkazib berish vaqti'**
  String get createJobDeliveryTimeSection;

  /// No description provided for @createJobPickupSlotLabel.
  ///
  /// In uz, this message translates to:
  /// **'Olish'**
  String get createJobPickupSlotLabel;

  /// No description provided for @createJobDeliverySlotLabel.
  ///
  /// In uz, this message translates to:
  /// **'Yetkazish'**
  String get createJobDeliverySlotLabel;

  /// No description provided for @createJobAboutPackage.
  ///
  /// In uz, this message translates to:
  /// **'Paket haqida'**
  String get createJobAboutPackage;

  /// No description provided for @createJobPackageTypeShort.
  ///
  /// In uz, this message translates to:
  /// **'Turi'**
  String get createJobPackageTypeShort;

  /// No description provided for @createJobPackageSizeShort.
  ///
  /// In uz, this message translates to:
  /// **'O‘lchami'**
  String get createJobPackageSizeShort;

  /// No description provided for @createJobPackageWeightShort.
  ///
  /// In uz, this message translates to:
  /// **'Og‘irligi'**
  String get createJobPackageWeightShort;

  /// No description provided for @createJobPackageDescShort.
  ///
  /// In uz, this message translates to:
  /// **'Izoh'**
  String get createJobPackageDescShort;

  /// No description provided for @createJobEstimatedPrice.
  ///
  /// In uz, this message translates to:
  /// **'Taxminiy narx'**
  String get createJobEstimatedPrice;

  /// No description provided for @createJobFinalPriceDisclaimer.
  ///
  /// In uz, this message translates to:
  /// **'Yakuniy narx auksion davomida aniqlanadi'**
  String get createJobFinalPriceDisclaimer;

  /// No description provided for @createJobAuctionHint.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma joylangandan keyin kuryerlar auksionda ishtirok etadi'**
  String get createJobAuctionHint;

  /// No description provided for @createJobPlaceOrder.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtmani joylash'**
  String get createJobPlaceOrder;

  /// No description provided for @productNameLabel.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulot nomi'**
  String get productNameLabel;

  /// No description provided for @productTypeLabel.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulot turi'**
  String get productTypeLabel;

  /// No description provided for @weightKg.
  ///
  /// In uz, this message translates to:
  /// **'Og‘irligi (kg)'**
  String get weightKg;

  /// No description provided for @volumeCategoryLabel.
  ///
  /// In uz, this message translates to:
  /// **'Hajm kategoriyasi'**
  String get volumeCategoryLabel;

  /// No description provided for @orderCommentsLabel.
  ///
  /// In uz, this message translates to:
  /// **'Qo‘shimcha izoh'**
  String get orderCommentsLabel;

  /// No description provided for @orderCommentsHint.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma haqida qo‘shimcha ma’lumot yozing'**
  String get orderCommentsHint;

  /// No description provided for @orderCommentsCharCounter.
  ///
  /// In uz, this message translates to:
  /// **'{current}/{max}'**
  String orderCommentsCharCounter(int current, int max);

  /// No description provided for @orderSuitableTransportTitle.
  ///
  /// In uz, this message translates to:
  /// **'Mos transport'**
  String get orderSuitableTransportTitle;

  /// No description provided for @orderRequiredTransportTitle.
  ///
  /// In uz, this message translates to:
  /// **'Transport turi'**
  String get orderRequiredTransportTitle;

  /// No description provided for @validationSelectSuitableTransport.
  ///
  /// In uz, this message translates to:
  /// **'Kamida bitta transportni tanlang (bir nechtasini tanlash mumkin)'**
  String get validationSelectSuitableTransport;

  /// No description provided for @validationSelectOneTransport.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma uchun bitta transport turini tanlang'**
  String get validationSelectOneTransport;

  /// No description provided for @transportLabelPiyoda.
  ///
  /// In uz, this message translates to:
  /// **'Piyoda'**
  String get transportLabelPiyoda;

  /// No description provided for @transportLabelVelosiped.
  ///
  /// In uz, this message translates to:
  /// **'Velosiped / skuter'**
  String get transportLabelVelosiped;

  /// No description provided for @transportLabelMoto.
  ///
  /// In uz, this message translates to:
  /// **'Moto'**
  String get transportLabelMoto;

  /// No description provided for @transportLabelAvto.
  ///
  /// In uz, this message translates to:
  /// **'Avto'**
  String get transportLabelAvto;

  /// No description provided for @transportLabelTruck.
  ///
  /// In uz, this message translates to:
  /// **'Katta yuk avto'**
  String get transportLabelTruck;

  /// No description provided for @courierTransportEmptyTitle.
  ///
  /// In uz, this message translates to:
  /// **'Transport turi belgilanmagan'**
  String get courierTransportEmptyTitle;

  /// No description provided for @courierTransportEmptySubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtmalarni ko‘rish uchun profilda kamida bitta transport turini tanlang.'**
  String get courierTransportEmptySubtitle;

  /// No description provided for @courierTransportChooseAction.
  ///
  /// In uz, this message translates to:
  /// **'Transport tanlash'**
  String get courierTransportChooseAction;

  /// No description provided for @courierProfileTransportLabel.
  ///
  /// In uz, this message translates to:
  /// **'Transport turlari'**
  String get courierProfileTransportLabel;

  /// No description provided for @courierProfileTransportChange.
  ///
  /// In uz, this message translates to:
  /// **'O‘zgartirish'**
  String get courierProfileTransportChange;

  /// No description provided for @courierTransportSheetTitleProfile.
  ///
  /// In uz, this message translates to:
  /// **'Transport turlarini yangilang'**
  String get courierTransportSheetTitleProfile;

  /// No description provided for @courierTransportSheetTitleSetup.
  ///
  /// In uz, this message translates to:
  /// **'Transport turini tanlang'**
  String get courierTransportSheetTitleSetup;

  /// No description provided for @courierFilterAllDistricts.
  ///
  /// In uz, this message translates to:
  /// **'Barcha tumanlar'**
  String get courierFilterAllDistricts;

  /// No description provided for @jobTransportMismatchMessage.
  ///
  /// In uz, this message translates to:
  /// **'Bu buyurtma sizning transport turlaringizga mos emas.'**
  String get jobTransportMismatchMessage;

  /// No description provided for @volumeCatVerySmall.
  ///
  /// In uz, this message translates to:
  /// **'Juda kichik'**
  String get volumeCatVerySmall;

  /// No description provided for @volumeCatSmall.
  ///
  /// In uz, this message translates to:
  /// **'Kichik'**
  String get volumeCatSmall;

  /// No description provided for @volumeCatMedium.
  ///
  /// In uz, this message translates to:
  /// **'O‘rta'**
  String get volumeCatMedium;

  /// No description provided for @volumeCatLarge.
  ///
  /// In uz, this message translates to:
  /// **'Katta'**
  String get volumeCatLarge;

  /// No description provided for @volumeCatVeryLarge.
  ///
  /// In uz, this message translates to:
  /// **'Katta+'**
  String get volumeCatVeryLarge;

  /// No description provided for @dimensionsMmLabel.
  ///
  /// In uz, this message translates to:
  /// **'Razmeri (mm)'**
  String get dimensionsMmLabel;

  /// No description provided for @dimensionsMmHint.
  ///
  /// In uz, this message translates to:
  /// **'1000x500x200'**
  String get dimensionsMmHint;

  /// No description provided for @validationDimensionsFormat.
  ///
  /// In uz, this message translates to:
  /// **'Format: uchta son, masalan 1000x500x200'**
  String get validationDimensionsFormat;

  /// No description provided for @validationDimensionsRequired.
  ///
  /// In uz, this message translates to:
  /// **'Tanlangan hajm uchun razmer majburiy'**
  String get validationDimensionsRequired;

  /// No description provided for @startingPrice.
  ///
  /// In uz, this message translates to:
  /// **'Boshlang‘ich narx'**
  String get startingPrice;

  /// No description provided for @paymentType.
  ///
  /// In uz, this message translates to:
  /// **'To‘lov turi'**
  String get paymentType;

  /// No description provided for @paymentCash.
  ///
  /// In uz, this message translates to:
  /// **'Naqd'**
  String get paymentCash;

  /// No description provided for @paymentCard.
  ///
  /// In uz, this message translates to:
  /// **'Karta'**
  String get paymentCard;

  /// No description provided for @paymentPrepaid.
  ///
  /// In uz, this message translates to:
  /// **'Oldindan'**
  String get paymentPrepaid;

  /// No description provided for @deliveryTimeTitle.
  ///
  /// In uz, this message translates to:
  /// **'Yetkazish vaqti'**
  String get deliveryTimeTitle;

  /// No description provided for @deliveryFast.
  ///
  /// In uz, this message translates to:
  /// **'Tez'**
  String get deliveryFast;

  /// No description provided for @deliveryRelaxed.
  ///
  /// In uz, this message translates to:
  /// **'Bemalol'**
  String get deliveryRelaxed;

  /// No description provided for @deliveryCustom.
  ///
  /// In uz, this message translates to:
  /// **'Vaqtni tanlash'**
  String get deliveryCustom;

  /// No description provided for @deliveryUntilHint.
  ///
  /// In uz, this message translates to:
  /// **'Masalan: 21:00 gacha'**
  String get deliveryUntilHint;

  /// No description provided for @mapAddressCity.
  ///
  /// In uz, this message translates to:
  /// **'Shahar'**
  String get mapAddressCity;

  /// No description provided for @mapAddressDistrict.
  ///
  /// In uz, this message translates to:
  /// **'Tuman'**
  String get mapAddressDistrict;

  /// No description provided for @mapAddressRegion.
  ///
  /// In uz, this message translates to:
  /// **'Viloyat'**
  String get mapAddressRegion;

  /// No description provided for @mapDistanceLabel.
  ///
  /// In uz, this message translates to:
  /// **'Masofa'**
  String get mapDistanceLabel;

  /// No description provided for @mapDistanceApproximate.
  ///
  /// In uz, this message translates to:
  /// **'Taxminiy (to‘g‘ri chiziq bo‘yicha)'**
  String get mapDistanceApproximate;

  /// No description provided for @mapPickupMarkerHint.
  ///
  /// In uz, this message translates to:
  /// **'Olib ketish nuqtasi'**
  String get mapPickupMarkerHint;

  /// No description provided for @jobRouteMapTitle.
  ///
  /// In uz, this message translates to:
  /// **'Yo‘l xaritasi'**
  String get jobRouteMapTitle;

  /// No description provided for @jobMapNoCoordinates.
  ///
  /// In uz, this message translates to:
  /// **'Xarita uchun manzil koordinatalari mavjud emas.'**
  String get jobMapNoCoordinates;

  /// No description provided for @jobMapMarkerA.
  ///
  /// In uz, this message translates to:
  /// **'A'**
  String get jobMapMarkerA;

  /// No description provided for @jobMapMarkerB.
  ///
  /// In uz, this message translates to:
  /// **'B'**
  String get jobMapMarkerB;

  /// No description provided for @jobMapOneCoordinateOnly.
  ///
  /// In uz, this message translates to:
  /// **'Faqat bitta manzil koordinatasi mavjud — masofa hisoblanmaydi.'**
  String get jobMapOneCoordinateOnly;

  /// No description provided for @courierJobMapToPickupTitle.
  ///
  /// In uz, this message translates to:
  /// **'Olish nuqtasi (A) ga yo‘l'**
  String get courierJobMapToPickupTitle;

  /// No description provided for @courierJobMapToDropoffTitle.
  ///
  /// In uz, this message translates to:
  /// **'Yetkazish nuqtasi (B) ga yo‘l'**
  String get courierJobMapToDropoffTitle;

  /// No description provided for @courierJobMapGpsUnavailable.
  ///
  /// In uz, this message translates to:
  /// **'Joylashuv aniqlanmadi. «Mening joyim» tugmasidan foydalaning.'**
  String get courierJobMapGpsUnavailable;

  /// No description provided for @jobDimensionsMm.
  ///
  /// In uz, this message translates to:
  /// **'Razmeri (mm)'**
  String get jobDimensionsMm;

  /// No description provided for @productPhoto.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulot rasmi'**
  String get productPhoto;

  /// No description provided for @validationProductPhotoRequired.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulot rasmini joylang'**
  String get validationProductPhotoRequired;

  /// No description provided for @takePhoto.
  ///
  /// In uz, this message translates to:
  /// **'Rasmga olish'**
  String get takePhoto;

  /// No description provided for @chooseFile.
  ///
  /// In uz, this message translates to:
  /// **'Fayldan tanlash'**
  String get chooseFile;

  /// No description provided for @searchJobsHint.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtmalarni qidirish'**
  String get searchJobsHint;

  /// No description provided for @profileSection.
  ///
  /// In uz, this message translates to:
  /// **'Profil'**
  String get profileSection;

  /// No description provided for @senderProfileNameLabel.
  ///
  /// In uz, this message translates to:
  /// **'Ism'**
  String get senderProfileNameLabel;

  /// No description provided for @senderProfilePhoneLabel.
  ///
  /// In uz, this message translates to:
  /// **'Telefon'**
  String get senderProfilePhoneLabel;

  /// No description provided for @senderProfileRoleLabel.
  ///
  /// In uz, this message translates to:
  /// **'Rol'**
  String get senderProfileRoleLabel;

  /// No description provided for @senderProfileLanguageLabel.
  ///
  /// In uz, this message translates to:
  /// **'Til'**
  String get senderProfileLanguageLabel;

  /// No description provided for @senderProfileStatusLabel.
  ///
  /// In uz, this message translates to:
  /// **'Holat'**
  String get senderProfileStatusLabel;

  /// No description provided for @senderProfileNameEmpty.
  ///
  /// In uz, this message translates to:
  /// **'Ism kiritilmagan'**
  String get senderProfileNameEmpty;

  /// No description provided for @senderProfilePhoneEmpty.
  ///
  /// In uz, this message translates to:
  /// **'Telefon raqam mavjud emas'**
  String get senderProfilePhoneEmpty;

  /// No description provided for @senderProfileStatusActive.
  ///
  /// In uz, this message translates to:
  /// **'Faol'**
  String get senderProfileStatusActive;

  /// No description provided for @senderProfileStatusBlocked.
  ///
  /// In uz, this message translates to:
  /// **'Bloklangan'**
  String get senderProfileStatusBlocked;

  /// No description provided for @senderProfilePhoneVerified.
  ///
  /// In uz, this message translates to:
  /// **'Telefon tasdiqlangan'**
  String get senderProfilePhoneVerified;

  /// No description provided for @senderProfilePhoneNotVerified.
  ///
  /// In uz, this message translates to:
  /// **'Telefon tasdiqlanmagan'**
  String get senderProfilePhoneNotVerified;

  /// No description provided for @senderProfileVerificationLabel.
  ///
  /// In uz, this message translates to:
  /// **'Telefon holati'**
  String get senderProfileVerificationLabel;

  /// No description provided for @senderWalletTitle.
  ///
  /// In uz, this message translates to:
  /// **'Hamyon'**
  String get senderWalletTitle;

  /// No description provided for @senderWalletSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Tez orada mavjud bo‘ladi.'**
  String get senderWalletSubtitle;

  /// No description provided for @senderProfileEditSection.
  ///
  /// In uz, this message translates to:
  /// **'Ma’lumotlarni tahrirlash'**
  String get senderProfileEditSection;

  /// No description provided for @senderProfileFullNameLabel.
  ///
  /// In uz, this message translates to:
  /// **'To‘liq ism'**
  String get senderProfileFullNameLabel;

  /// No description provided for @senderProfileFullNameHint.
  ///
  /// In uz, this message translates to:
  /// **'Ism va familiyangizni kiriting'**
  String get senderProfileFullNameHint;

  /// No description provided for @senderProfileSecondaryPhoneLabel.
  ///
  /// In uz, this message translates to:
  /// **'Qo‘shimcha telefon'**
  String get senderProfileSecondaryPhoneLabel;

  /// No description provided for @senderProfileSecondaryPhoneHint.
  ///
  /// In uz, this message translates to:
  /// **'+998 __ ___ __ __'**
  String get senderProfileSecondaryPhoneHint;

  /// No description provided for @senderProfileChangePhoto.
  ///
  /// In uz, this message translates to:
  /// **'Rasmni o‘zgartirish'**
  String get senderProfileChangePhoto;

  /// No description provided for @senderProfileRemovePhoto.
  ///
  /// In uz, this message translates to:
  /// **'Rasmni olib tashlash'**
  String get senderProfileRemovePhoto;

  /// No description provided for @senderProfileEditTooltip.
  ///
  /// In uz, this message translates to:
  /// **'Tahrirlash'**
  String get senderProfileEditTooltip;

  /// No description provided for @senderProfileSave.
  ///
  /// In uz, this message translates to:
  /// **'Saqlash'**
  String get senderProfileSave;

  /// No description provided for @senderProfileSaving.
  ///
  /// In uz, this message translates to:
  /// **'Saqlanmoqda…'**
  String get senderProfileSaving;

  /// No description provided for @senderProfileSaveSuccess.
  ///
  /// In uz, this message translates to:
  /// **'Profil yangilandi'**
  String get senderProfileSaveSuccess;

  /// No description provided for @senderProfileInvalidSecondaryPhone.
  ///
  /// In uz, this message translates to:
  /// **'To‘g‘ri O‘zbekiston raqamini kiriting'**
  String get senderProfileInvalidSecondaryPhone;

  /// No description provided for @senderProfileSecondarySameAsPrimary.
  ///
  /// In uz, this message translates to:
  /// **'Asosiy raqamdan boshqa raqam kiriting'**
  String get senderProfileSecondarySameAsPrimary;

  /// No description provided for @senderProfilePrimaryPhoneReadOnly.
  ///
  /// In uz, this message translates to:
  /// **'Asosiy telefon (tizim)'**
  String get senderProfilePrimaryPhoneReadOnly;

  /// No description provided for @openAdminPanel.
  ///
  /// In uz, this message translates to:
  /// **'Admin panelga o‘tish'**
  String get openAdminPanel;

  /// No description provided for @statusPosted.
  ///
  /// In uz, this message translates to:
  /// **'Yaratildi'**
  String get statusPosted;

  /// No description provided for @senderOrderStatusPosted.
  ///
  /// In uz, this message translates to:
  /// **'Kutilmoqda'**
  String get senderOrderStatusPosted;

  /// No description provided for @senderOrderPriceLabel.
  ///
  /// In uz, this message translates to:
  /// **'Narx'**
  String get senderOrderPriceLabel;

  /// No description provided for @senderOrderMinStavkaSuffix.
  ///
  /// In uz, this message translates to:
  /// **'(min. stavka)'**
  String get senderOrderMinStavkaSuffix;

  /// No description provided for @senderOrderContactsHint.
  ///
  /// In uz, this message translates to:
  /// **'Kuryer tanlangach aloqa ma\'lumotlari ko\'rinadi'**
  String get senderOrderContactsHint;

  /// No description provided for @statusAssigned.
  ///
  /// In uz, this message translates to:
  /// **'Biriktirildi'**
  String get statusAssigned;

  /// No description provided for @statusPickedUp.
  ///
  /// In uz, this message translates to:
  /// **'Olib ketildi'**
  String get statusPickedUp;

  /// No description provided for @statusDelivered.
  ///
  /// In uz, this message translates to:
  /// **'Yetkazildi'**
  String get statusDelivered;

  /// No description provided for @senderNotificationsTooltip.
  ///
  /// In uz, this message translates to:
  /// **'Bildirishnomalar'**
  String get senderNotificationsTooltip;

  /// No description provided for @senderNotificationsEmpty.
  ///
  /// In uz, this message translates to:
  /// **'Hozircha yangi bildirishnomalar yo‘q'**
  String get senderNotificationsEmpty;

  /// No description provided for @senderSnackbarAuctionStarted.
  ///
  /// In uz, this message translates to:
  /// **'Auksion boshlandi — buyurtma «Jarayonda» bo‘limida'**
  String get senderSnackbarAuctionStarted;

  /// No description provided for @senderSnackbarAuctionEndedAssigned.
  ///
  /// In uz, this message translates to:
  /// **'Auksion tugadi — kuryer biriktirildi'**
  String get senderSnackbarAuctionEndedAssigned;

  /// No description provided for @senderSnackbarAuctionEndedReopened.
  ///
  /// In uz, this message translates to:
  /// **'Auksion tugadi — g‘olib chiqmadi, buyurtma qayta kutilmoqda'**
  String get senderSnackbarAuctionEndedReopened;

  /// No description provided for @senderSnackbarAuctionEndedCancelled.
  ///
  /// In uz, this message translates to:
  /// **'Auksion tugadi — buyurtma bekor qilindi'**
  String get senderSnackbarAuctionEndedCancelled;

  /// No description provided for @senderNotifCourierNearPickup1Km.
  ///
  /// In uz, this message translates to:
  /// **'Kuryer olib ketish manziliga yaqinlashmoqda (~1 km)'**
  String get senderNotifCourierNearPickup1Km;

  /// No description provided for @senderNotifCourierNearDropoff5Km.
  ///
  /// In uz, this message translates to:
  /// **'Kuryer yetkazish manziliga yaqinlashmoqda (~5 km)'**
  String get senderNotifCourierNearDropoff5Km;

  /// No description provided for @senderNotifCourierNearDropoff2Km.
  ///
  /// In uz, this message translates to:
  /// **'Kuryer yetkazish manziliga yaqinlashmoqda (~2 km)'**
  String get senderNotifCourierNearDropoff2Km;

  /// No description provided for @senderNotifAuctionStartedBody.
  ///
  /// In uz, this message translates to:
  /// **'«{product}». Shu buyurtmangiz uchun kuryerlar taklif bildirmoqda. Buyurtmangiz «Jarayonda» bo‘limiga o‘tkazildi.'**
  String senderNotifAuctionStartedBody(String product);

  /// No description provided for @senderNotifAuctionEndedAssignedBody.
  ///
  /// In uz, this message translates to:
  /// **'«{product}». «{courier}» kuryerning taklifi {amount} yutuq deb belgilandi. To‘liq ma’lumot uchun Buyurtma tafsilotlariga o‘ting.'**
  String senderNotifAuctionEndedAssignedBody(
      String product, String courier, String amount);

  /// No description provided for @senderNotifAuctionReopenedBody.
  ///
  /// In uz, this message translates to:
  /// **'«{product}». Auksion tugadi — g‘olib chiqmadi, buyurtma qayta kutilmoqda.'**
  String senderNotifAuctionReopenedBody(String product);

  /// No description provided for @senderNotifAuctionCancelledBody.
  ///
  /// In uz, this message translates to:
  /// **'«{product}». Auksion tugadi — buyurtma bekor qilindi.'**
  String senderNotifAuctionCancelledBody(String product);

  /// No description provided for @senderNotifOpenJobDetails.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtma tafsilotlari'**
  String get senderNotifOpenJobDetails;

  /// No description provided for @senderNotifUnknownCourier.
  ///
  /// In uz, this message translates to:
  /// **'Kuryer'**
  String get senderNotifUnknownCourier;

  /// No description provided for @liveTrackingBadge.
  ///
  /// In uz, this message translates to:
  /// **'Jonli kuzatuv'**
  String get liveTrackingBadge;

  /// No description provided for @courierTrackingSendingLabel.
  ///
  /// In uz, this message translates to:
  /// **'Jonli lokatsiya yuborilmoqda'**
  String get courierTrackingSendingLabel;

  /// No description provided for @courierTrackingLocationPermissionDenied.
  ///
  /// In uz, this message translates to:
  /// **'Joylashuv ruxsati yo‘q yoki GPS o‘chiq. Sozlamalardan ruxsat bering — jonli kuzatuv uchun kerak.'**
  String get courierTrackingLocationPermissionDenied;

  /// No description provided for @trackingLastUpdatedPrefix.
  ///
  /// In uz, this message translates to:
  /// **'So‘nggi yangilanish:'**
  String get trackingLastUpdatedPrefix;

  /// No description provided for @senderTrackingWaitingCourierLocation.
  ///
  /// In uz, this message translates to:
  /// **'Kuryer joylashuvi hali uzatilmagan. Kuryer ushbu buyurtmani ilovada ochgan va yo‘lga chiqqanidan keyin xarita paydo bo‘ladi.'**
  String get senderTrackingWaitingCourierLocation;

  /// No description provided for @senderTrackingNoCoordinatesForLeg.
  ///
  /// In uz, this message translates to:
  /// **'Bu marshrut uchun manzil koordinatalari kiritilmagan.'**
  String get senderTrackingNoCoordinatesForLeg;

  /// No description provided for @senderTrackingTapToEnlarge.
  ///
  /// In uz, this message translates to:
  /// **'Kattalashtirish uchun xaritaga bosing'**
  String get senderTrackingTapToEnlarge;

  /// No description provided for @senderTrackingFullscreenTitlePickup.
  ///
  /// In uz, this message translates to:
  /// **'Kuryer — olish nuqtasi'**
  String get senderTrackingFullscreenTitlePickup;

  /// No description provided for @senderTrackingFullscreenTitleDropoff.
  ///
  /// In uz, this message translates to:
  /// **'Kuryer — yetkazish manzili'**
  String get senderTrackingFullscreenTitleDropoff;

  /// No description provided for @senderTrackingDistanceMeters.
  ///
  /// In uz, this message translates to:
  /// **'{m} m'**
  String senderTrackingDistanceMeters(int m);

  /// No description provided for @senderTrackingDistanceKm.
  ///
  /// In uz, this message translates to:
  /// **'{km} km'**
  String senderTrackingDistanceKm(String km);

  /// No description provided for @senderTrackingEtaApproxMinutes.
  ///
  /// In uz, this message translates to:
  /// **'Taxminan {minutes} daqiqa'**
  String senderTrackingEtaApproxMinutes(int minutes);

  /// No description provided for @senderTrackingEtaHoursMinutes.
  ///
  /// In uz, this message translates to:
  /// **'Taxminan {hours} soat {minutes} daqiqa'**
  String senderTrackingEtaHoursMinutes(int hours, int minutes);

  /// No description provided for @senderNotificationsSheetTitle.
  ///
  /// In uz, this message translates to:
  /// **'Bildirishnomalar'**
  String get senderNotificationsSheetTitle;

  /// No description provided for @senderNotificationsLoadError.
  ///
  /// In uz, this message translates to:
  /// **'Bildirishnomalarni yuklab bo‘lmadi'**
  String get senderNotificationsLoadError;

  /// No description provided for @senderNotificationsTapToRead.
  ///
  /// In uz, this message translates to:
  /// **'Batafsil uchun bosing'**
  String get senderNotificationsTapToRead;

  /// No description provided for @senderNotificationsTimeJustNow.
  ///
  /// In uz, this message translates to:
  /// **'Hozirgina'**
  String get senderNotificationsTimeJustNow;

  /// No description provided for @senderNotificationsTimeMinutesAgo.
  ///
  /// In uz, this message translates to:
  /// **'{count} daqiqa oldin'**
  String senderNotificationsTimeMinutesAgo(int count);

  /// No description provided for @senderNotificationsTimeHoursAgo.
  ///
  /// In uz, this message translates to:
  /// **'{count} soat oldin'**
  String senderNotificationsTimeHoursAgo(int count);

  /// No description provided for @createJobMenuMore.
  ///
  /// In uz, this message translates to:
  /// **'Sozlamalar'**
  String get createJobMenuMore;

  /// No description provided for @createJobMenuChangeTheme.
  ///
  /// In uz, this message translates to:
  /// **'Rejimni o‘zgartirish'**
  String get createJobMenuChangeTheme;

  /// No description provided for @createJobMenuContactUs.
  ///
  /// In uz, this message translates to:
  /// **'Biz bilan bog‘lanish'**
  String get createJobMenuContactUs;

  /// No description provided for @createJobThemeTitle.
  ///
  /// In uz, this message translates to:
  /// **'Rejimni tanlang'**
  String get createJobThemeTitle;

  /// No description provided for @createJobThemeLight.
  ///
  /// In uz, this message translates to:
  /// **'Kunduzgi rejim'**
  String get createJobThemeLight;

  /// No description provided for @createJobThemeDark.
  ///
  /// In uz, this message translates to:
  /// **'Tungi rejim'**
  String get createJobThemeDark;

  /// No description provided for @createJobThemeSystem.
  ///
  /// In uz, this message translates to:
  /// **'Tizim bo‘yicha'**
  String get createJobThemeSystem;

  /// No description provided for @createJobContactTitle.
  ///
  /// In uz, this message translates to:
  /// **'Biz bilan bog‘lanish'**
  String get createJobContactTitle;

  /// No description provided for @createJobContactPickType.
  ///
  /// In uz, this message translates to:
  /// **'Murojaat turini tanlang'**
  String get createJobContactPickType;

  /// No description provided for @createJobContactComplaint.
  ///
  /// In uz, this message translates to:
  /// **'Shikoyat'**
  String get createJobContactComplaint;

  /// No description provided for @createJobContactPraise.
  ///
  /// In uz, this message translates to:
  /// **'Maqtov'**
  String get createJobContactPraise;

  /// No description provided for @createJobContactApplication.
  ///
  /// In uz, this message translates to:
  /// **'Ariza'**
  String get createJobContactApplication;

  /// No description provided for @createJobContactSuggestion.
  ///
  /// In uz, this message translates to:
  /// **'Taklif'**
  String get createJobContactSuggestion;

  /// No description provided for @createJobContactMessageLabel.
  ///
  /// In uz, this message translates to:
  /// **'Murojaatingizni yozing'**
  String get createJobContactMessageLabel;

  /// No description provided for @createJobContactMessageHint.
  ///
  /// In uz, this message translates to:
  /// **'Murojaat matnini kiriting'**
  String get createJobContactMessageHint;

  /// No description provided for @createJobContactSubmit.
  ///
  /// In uz, this message translates to:
  /// **'Yuborish'**
  String get createJobContactSubmit;

  /// No description provided for @createJobContactSuccess.
  ///
  /// In uz, this message translates to:
  /// **'Murojaatingiz yuborildi'**
  String get createJobContactSuccess;

  /// No description provided for @createJobValidationContactType.
  ///
  /// In uz, this message translates to:
  /// **'Murojaat turini tanlang'**
  String get createJobValidationContactType;

  /// No description provided for @createJobValidationContactMessage.
  ///
  /// In uz, this message translates to:
  /// **'Murojaat matnini kiriting'**
  String get createJobValidationContactMessage;

  /// No description provided for @createJobValidationMessageTooShort.
  ///
  /// In uz, this message translates to:
  /// **'Matn juda qisqa (kamida 15 belgi)'**
  String get createJobValidationMessageTooShort;

  /// No description provided for @adminContactRequests.
  ///
  /// In uz, this message translates to:
  /// **'Murojaatlar'**
  String get adminContactRequests;

  /// No description provided for @adminContactRequestsSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Foydalanuvchi xabarlari'**
  String get adminContactRequestsSubtitle;

  /// No description provided for @adminContactRequestDetail.
  ///
  /// In uz, this message translates to:
  /// **'Murojaat tafsilotlari'**
  String get adminContactRequestDetail;

  /// No description provided for @supportRequestStatusNew.
  ///
  /// In uz, this message translates to:
  /// **'Yangi'**
  String get supportRequestStatusNew;

  /// No description provided for @supportRequestStatusRead.
  ///
  /// In uz, this message translates to:
  /// **'O‘qilgan'**
  String get supportRequestStatusRead;

  /// No description provided for @supportRequestStatusResolved.
  ///
  /// In uz, this message translates to:
  /// **'Hal qilindi'**
  String get supportRequestStatusResolved;

  /// No description provided for @supportRequestFullMessage.
  ///
  /// In uz, this message translates to:
  /// **'To‘liq matn'**
  String get supportRequestFullMessage;

  /// No description provided for @supportRequestMarkRead.
  ///
  /// In uz, this message translates to:
  /// **'O‘qilgan deb belgilash'**
  String get supportRequestMarkRead;

  /// No description provided for @supportRequestMarkResolved.
  ///
  /// In uz, this message translates to:
  /// **'Hal qilindi'**
  String get supportRequestMarkResolved;

  /// No description provided for @adminPanelSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Kuryer boshqaruv paneli'**
  String get adminPanelSubtitle;

  /// No description provided for @adminBottomNavDashboard.
  ///
  /// In uz, this message translates to:
  /// **'Boshqaruv'**
  String get adminBottomNavDashboard;

  /// No description provided for @adminBottomNavUsers.
  ///
  /// In uz, this message translates to:
  /// **'Foydalanuvchilar'**
  String get adminBottomNavUsers;

  /// No description provided for @adminBottomNavOrders.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtmalar'**
  String get adminBottomNavOrders;

  /// No description provided for @adminBottomNavAuctions.
  ///
  /// In uz, this message translates to:
  /// **'Auksionlar'**
  String get adminBottomNavAuctions;

  /// No description provided for @adminBottomNavReports.
  ///
  /// In uz, this message translates to:
  /// **'Hisobotlar'**
  String get adminBottomNavReports;

  /// No description provided for @adminBottomNavFinance.
  ///
  /// In uz, this message translates to:
  /// **'Moliya'**
  String get adminBottomNavFinance;

  /// No description provided for @adminPanelNavSettings.
  ///
  /// In uz, this message translates to:
  /// **'Sozlamalar'**
  String get adminPanelNavSettings;

  /// No description provided for @adminQuickActionsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Tezkor amallar'**
  String get adminQuickActionsTitle;

  /// No description provided for @adminActionViewList.
  ///
  /// In uz, this message translates to:
  /// **'Ko\'rish'**
  String get adminActionViewList;

  /// No description provided for @adminActionEditRole.
  ///
  /// In uz, this message translates to:
  /// **'Rolni tahrirlash'**
  String get adminActionEditRole;

  /// No description provided for @adminActionBan.
  ///
  /// In uz, this message translates to:
  /// **'Bloklash'**
  String get adminActionBan;

  /// No description provided for @adminActionUnblock.
  ///
  /// In uz, this message translates to:
  /// **'Blokdan chiqarish'**
  String get adminActionUnblock;

  /// No description provided for @adminActionVerify.
  ///
  /// In uz, this message translates to:
  /// **'Tasdiqlash'**
  String get adminActionVerify;

  /// No description provided for @adminFinanceSectionTitle.
  ///
  /// In uz, this message translates to:
  /// **'Moliya va tranzaksiyalar'**
  String get adminFinanceSectionTitle;

  /// No description provided for @adminFinanceTotalRevenue.
  ///
  /// In uz, this message translates to:
  /// **'Jami tushum'**
  String get adminFinanceTotalRevenue;

  /// No description provided for @adminFinanceCommissions.
  ///
  /// In uz, this message translates to:
  /// **'Olingan komissiyalar'**
  String get adminFinanceCommissions;

  /// No description provided for @adminFinanceSuccessfulPayments.
  ///
  /// In uz, this message translates to:
  /// **'Muvaffaqiyatli to\'lovlar'**
  String get adminFinanceSuccessfulPayments;

  /// No description provided for @adminFinanceCourierPayouts.
  ///
  /// In uz, this message translates to:
  /// **'Kuryer to\'lovlari'**
  String get adminFinanceCourierPayouts;

  /// No description provided for @adminFinanceDemoHint.
  ///
  /// In uz, this message translates to:
  /// **'Namuna ko\'rsatkichlar'**
  String get adminFinanceDemoHint;

  /// No description provided for @adminReportsSectionTitle.
  ///
  /// In uz, this message translates to:
  /// **'Hisobotlar va shikoyatlar'**
  String get adminReportsSectionTitle;

  /// No description provided for @adminOrderFilterAll.
  ///
  /// In uz, this message translates to:
  /// **'Barchasi'**
  String get adminOrderFilterAll;

  /// No description provided for @adminOrderFilterPending.
  ///
  /// In uz, this message translates to:
  /// **'Kutilmoqda'**
  String get adminOrderFilterPending;

  /// No description provided for @adminOrderFilterAuction.
  ///
  /// In uz, this message translates to:
  /// **'Auksion'**
  String get adminOrderFilterAuction;

  /// No description provided for @adminOrderFilterInDelivery.
  ///
  /// In uz, this message translates to:
  /// **'Yetkazilmoqda'**
  String get adminOrderFilterInDelivery;

  /// No description provided for @adminOrderFilterCompleted.
  ///
  /// In uz, this message translates to:
  /// **'Bajarildi'**
  String get adminOrderFilterCompleted;

  /// No description provided for @adminUserFilterAll.
  ///
  /// In uz, this message translates to:
  /// **'Barchasi'**
  String get adminUserFilterAll;

  /// No description provided for @adminUserFilterSenders.
  ///
  /// In uz, this message translates to:
  /// **'Yuboruvchilar'**
  String get adminUserFilterSenders;

  /// No description provided for @adminUserFilterCouriers.
  ///
  /// In uz, this message translates to:
  /// **'Kuryerlar'**
  String get adminUserFilterCouriers;

  /// No description provided for @adminUserFilterBlocked.
  ///
  /// In uz, this message translates to:
  /// **'Bloklanganlar'**
  String get adminUserFilterBlocked;

  /// No description provided for @adminUserFilterNew.
  ///
  /// In uz, this message translates to:
  /// **'Yangilar'**
  String get adminUserFilterNew;

  /// No description provided for @adminUserFilterComplaints.
  ///
  /// In uz, this message translates to:
  /// **'Shikoyatli'**
  String get adminUserFilterComplaints;

  /// No description provided for @adminUserFilterAdmins.
  ///
  /// In uz, this message translates to:
  /// **'Adminlar'**
  String get adminUserFilterAdmins;

  /// No description provided for @adminSettingsSectionShortcuts.
  ///
  /// In uz, this message translates to:
  /// **'Tizim va yo\'nalishlar'**
  String get adminSettingsSectionShortcuts;

  /// No description provided for @adminOpenStatistics.
  ///
  /// In uz, this message translates to:
  /// **'Statistikani ochish'**
  String get adminOpenStatistics;

  /// No description provided for @adminOpenMap.
  ///
  /// In uz, this message translates to:
  /// **'Jonli xarita'**
  String get adminOpenMap;

  /// No description provided for @adminOpenContactRequests.
  ///
  /// In uz, this message translates to:
  /// **'Murojaatlarni ochish'**
  String get adminOpenContactRequests;

  /// No description provided for @adminOpenFullSettings.
  ///
  /// In uz, this message translates to:
  /// **'Ilova sozlamalari'**
  String get adminOpenFullSettings;

  /// No description provided for @adminComingSoonNotifications.
  ///
  /// In uz, this message translates to:
  /// **'Bildirishnomalar tez orada'**
  String get adminComingSoonNotifications;

  /// No description provided for @adminSearchHint.
  ///
  /// In uz, this message translates to:
  /// **'Qidirish'**
  String get adminSearchHint;

  /// No description provided for @adminLanguageTileTitle.
  ///
  /// In uz, this message translates to:
  /// **'Ilova tili'**
  String get adminLanguageTileTitle;

  /// No description provided for @adminOrdersSectionTitle.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtmalar'**
  String get adminOrdersSectionTitle;

  /// No description provided for @adminAuctionsSectionTitle.
  ///
  /// In uz, this message translates to:
  /// **'Auksionlar'**
  String get adminAuctionsSectionTitle;

  /// No description provided for @adminNoJobsInList.
  ///
  /// In uz, this message translates to:
  /// **'Ro\'yxat bo\'sh'**
  String get adminNoJobsInList;

  /// No description provided for @adminRegionPerformanceTitle.
  ///
  /// In uz, this message translates to:
  /// **'Hududlar bo\'yicha samaradorlik'**
  String get adminRegionPerformanceTitle;

  /// No description provided for @adminRegionPerformanceHint.
  ///
  /// In uz, this message translates to:
  /// **'Namuna jadval — keyinroq real ma\'lumot'**
  String get adminRegionPerformanceHint;

  /// No description provided for @adminAnalyticsSectionTitle.
  ///
  /// In uz, this message translates to:
  /// **'Tahlil va diagrammalar'**
  String get adminAnalyticsSectionTitle;

  /// No description provided for @adminChartDeliveryGrowth.
  ///
  /// In uz, this message translates to:
  /// **'Yetkazib berish dinamikasi'**
  String get adminChartDeliveryGrowth;

  /// No description provided for @adminChartUsersVsCourier.
  ///
  /// In uz, this message translates to:
  /// **'Foydalanuvchilar va kuryerlar'**
  String get adminChartUsersVsCourier;

  /// No description provided for @adminChartCompletionDonut.
  ///
  /// In uz, this message translates to:
  /// **'Yakunlangan buyurtmalar ulushi'**
  String get adminChartCompletionDonut;

  /// No description provided for @adminDesignSampleChartNote.
  ///
  /// In uz, this message translates to:
  /// **'Diagrammalar statistikaga moslashtirilgan namuna'**
  String get adminDesignSampleChartNote;

  /// No description provided for @adminStatusActive.
  ///
  /// In uz, this message translates to:
  /// **'Faol'**
  String get adminStatusActive;

  /// No description provided for @adminStatusBlockedShort.
  ///
  /// In uz, this message translates to:
  /// **'Bloklangan'**
  String get adminStatusBlockedShort;

  /// No description provided for @adminUserManagementTitle.
  ///
  /// In uz, this message translates to:
  /// **'Foydalanuvchilarni boshqarish'**
  String get adminUserManagementTitle;

  /// No description provided for @adminJobOrderNumber.
  ///
  /// In uz, this message translates to:
  /// **'№ {id}'**
  String adminJobOrderNumber(String id);

  /// No description provided for @adminPickupInfo.
  ///
  /// In uz, this message translates to:
  /// **'Olib ketish'**
  String get adminPickupInfo;

  /// No description provided for @adminDropoffInfo.
  ///
  /// In uz, this message translates to:
  /// **'Yetkazish'**
  String get adminDropoffInfo;

  /// No description provided for @adminReportSenderCourierComplaints.
  ///
  /// In uz, this message translates to:
  /// **'Yuboruvchi / kuryer shikoyatlari'**
  String get adminReportSenderCourierComplaints;

  /// No description provided for @adminReportFlaggedOrders.
  ///
  /// In uz, this message translates to:
  /// **'Belgilangan buyurtmalar'**
  String get adminReportFlaggedOrders;

  /// No description provided for @adminReportUrgentHighlights.
  ///
  /// In uz, this message translates to:
  /// **'Muhim xabarlar'**
  String get adminReportUrgentHighlights;

  /// No description provided for @adminActionQuickResolve.
  ///
  /// In uz, this message translates to:
  /// **'Tez hal qilish'**
  String get adminActionQuickResolve;

  /// No description provided for @adminActionReject.
  ///
  /// In uz, this message translates to:
  /// **'Rad etish'**
  String get adminActionReject;

  /// No description provided for @adminActionInvestigate.
  ///
  /// In uz, this message translates to:
  /// **'O\'rganish'**
  String get adminActionInvestigate;

  /// No description provided for @adminFinancePendingPayouts.
  ///
  /// In uz, this message translates to:
  /// **'Kutilayotgan to\'lovlar'**
  String get adminFinancePendingPayouts;

  /// No description provided for @adminDistrictActivityTitle.
  ///
  /// In uz, this message translates to:
  /// **'Tumanlar bo\'yicha faollik'**
  String get adminDistrictActivityTitle;

  /// No description provided for @adminOrderHotspotsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtmalar nuqtalari'**
  String get adminOrderHotspotsTitle;

  /// No description provided for @adminCourierAvailabilityTitle.
  ///
  /// In uz, this message translates to:
  /// **'Kuryer bandligi (namuna)'**
  String get adminCourierAvailabilityTitle;

  /// No description provided for @adminGridAddAdmin.
  ///
  /// In uz, this message translates to:
  /// **'Admin qo\'shish'**
  String get adminGridAddAdmin;

  /// No description provided for @adminGridManageRoles.
  ///
  /// In uz, this message translates to:
  /// **'Rollarni boshqarish'**
  String get adminGridManageRoles;

  /// No description provided for @adminGridViewReports.
  ///
  /// In uz, this message translates to:
  /// **'Hisobotlar'**
  String get adminGridViewReports;

  /// No description provided for @adminGridBlockUser.
  ///
  /// In uz, this message translates to:
  /// **'Bloklash'**
  String get adminGridBlockUser;

  /// No description provided for @adminGridApproveCourier.
  ///
  /// In uz, this message translates to:
  /// **'Kuryerni tasdiqlash'**
  String get adminGridApproveCourier;

  /// No description provided for @adminGridMonitorAuctions.
  ///
  /// In uz, this message translates to:
  /// **'Auksionlar'**
  String get adminGridMonitorAuctions;

  /// No description provided for @adminGridSystemSettings.
  ///
  /// In uz, this message translates to:
  /// **'Tizim sozlamalari'**
  String get adminGridSystemSettings;

  /// No description provided for @adminBottomNavFeedback.
  ///
  /// In uz, this message translates to:
  /// **'Feedback'**
  String get adminBottomNavFeedback;

  /// No description provided for @adminBottomNavRegions.
  ///
  /// In uz, this message translates to:
  /// **'Hududlar'**
  String get adminBottomNavRegions;

  /// No description provided for @adminControlOverviewTitle.
  ///
  /// In uz, this message translates to:
  /// **'Operatsion ko‘rinish'**
  String get adminControlOverviewTitle;

  /// No description provided for @adminControlFeedbackTitle.
  ///
  /// In uz, this message translates to:
  /// **'Feedback va sifat'**
  String get adminControlFeedbackTitle;

  /// No description provided for @adminControlGeoTitle.
  ///
  /// In uz, this message translates to:
  /// **'Geografiya'**
  String get adminControlGeoTitle;

  /// No description provided for @adminControlAuctionTitle.
  ///
  /// In uz, this message translates to:
  /// **'Auksion va yetkazish'**
  String get adminControlAuctionTitle;

  /// No description provided for @adminControlUsersTotal.
  ///
  /// In uz, this message translates to:
  /// **'Jami foydalanuvchilar'**
  String get adminControlUsersTotal;

  /// No description provided for @adminControlSenders.
  ///
  /// In uz, this message translates to:
  /// **'Yuboruvchilar'**
  String get adminControlSenders;

  /// No description provided for @adminControlCouriers.
  ///
  /// In uz, this message translates to:
  /// **'Kuryerlar'**
  String get adminControlCouriers;

  /// No description provided for @adminControlOrdersTotal.
  ///
  /// In uz, this message translates to:
  /// **'Jami buyurtmalar'**
  String get adminControlOrdersTotal;

  /// No description provided for @adminControlPosted.
  ///
  /// In uz, this message translates to:
  /// **'E’lon qilingan'**
  String get adminControlPosted;

  /// No description provided for @adminControlAuctionLive.
  ///
  /// In uz, this message translates to:
  /// **'Auksionda'**
  String get adminControlAuctionLive;

  /// No description provided for @adminControlAssigned.
  ///
  /// In uz, this message translates to:
  /// **'Tayinlangan'**
  String get adminControlAssigned;

  /// No description provided for @adminControlPickedUp.
  ///
  /// In uz, this message translates to:
  /// **'Olib ketilgan'**
  String get adminControlPickedUp;

  /// No description provided for @adminControlDelivered.
  ///
  /// In uz, this message translates to:
  /// **'Yetkazilgan'**
  String get adminControlDelivered;

  /// No description provided for @adminControlCompleted.
  ///
  /// In uz, this message translates to:
  /// **'Yakunlangan'**
  String get adminControlCompleted;

  /// No description provided for @adminControlCancelled.
  ///
  /// In uz, this message translates to:
  /// **'Bekor qilingan'**
  String get adminControlCancelled;

  /// No description provided for @adminControlBlocked.
  ///
  /// In uz, this message translates to:
  /// **'Bloklangan'**
  String get adminControlBlocked;

  /// No description provided for @adminControlRatingsTotal.
  ///
  /// In uz, this message translates to:
  /// **'Jami baholar'**
  String get adminControlRatingsTotal;

  /// No description provided for @adminControlAvgRating.
  ///
  /// In uz, this message translates to:
  /// **'O‘rtacha baho'**
  String get adminControlAvgRating;

  /// No description provided for @adminControlComplaintsNew.
  ///
  /// In uz, this message translates to:
  /// **'Shikoyatlar (order_feedback)'**
  String get adminControlComplaintsNew;

  /// No description provided for @adminControlPraises.
  ///
  /// In uz, this message translates to:
  /// **'Maqtovlar'**
  String get adminControlPraises;

  /// No description provided for @adminControlLegacyComplaints.
  ///
  /// In uz, this message translates to:
  /// **'Eski shikoyatlar'**
  String get adminControlLegacyComplaints;

  /// No description provided for @adminControlTopComplaintTargets.
  ///
  /// In uz, this message translates to:
  /// **'Eng ko‘p shikoyat olgan (kimga)'**
  String get adminControlTopComplaintTargets;

  /// No description provided for @adminControlTopCouriersRating.
  ///
  /// In uz, this message translates to:
  /// **'Profil bahosi bo‘yicha kuryerlar'**
  String get adminControlTopCouriersRating;

  /// No description provided for @adminControlUsersByRegion.
  ///
  /// In uz, this message translates to:
  /// **'Viloyat bo‘yicha userlar'**
  String get adminControlUsersByRegion;

  /// No description provided for @adminControlJobsByRegion.
  ///
  /// In uz, this message translates to:
  /// **'Viloyat bo‘yicha buyurtmalar'**
  String get adminControlJobsByRegion;

  /// No description provided for @adminControlDistrictsHint.
  ///
  /// In uz, this message translates to:
  /// **'Tumanlar (userlar, top)'**
  String get adminControlDistrictsHint;

  /// No description provided for @adminControlAuctionsTouched.
  ///
  /// In uz, this message translates to:
  /// **'Auksion ishtiroki'**
  String get adminControlAuctionsTouched;

  /// No description provided for @adminControlAvgBids.
  ///
  /// In uz, this message translates to:
  /// **'O‘rtacha takliflar soni'**
  String get adminControlAvgBids;

  /// No description provided for @adminControlAvgDiscount.
  ///
  /// In uz, this message translates to:
  /// **'O‘rtacha narx pasayishi (birlik)'**
  String get adminControlAvgDiscount;

  /// No description provided for @adminControlCompletedDeliveries.
  ///
  /// In uz, this message translates to:
  /// **'Yakunlangan yetkazishlar'**
  String get adminControlCompletedDeliveries;

  /// No description provided for @adminControlActiveTracking.
  ///
  /// In uz, this message translates to:
  /// **'Faol kuzatuv (tracking)'**
  String get adminControlActiveTracking;

  /// No description provided for @adminOrderFilterComplaint.
  ///
  /// In uz, this message translates to:
  /// **'Shikoyatli'**
  String get adminOrderFilterComplaint;

  /// No description provided for @adminOrderFilterAuctionBids.
  ///
  /// In uz, this message translates to:
  /// **'Taklif bo‘lgan'**
  String get adminOrderFilterAuctionBids;

  /// No description provided for @adminOrderFilterRecent30.
  ///
  /// In uz, this message translates to:
  /// **'So‘nggi 30 kun'**
  String get adminOrderFilterRecent30;

  /// No description provided for @adminUserFilterLowRating.
  ///
  /// In uz, this message translates to:
  /// **'Past baho'**
  String get adminUserFilterLowRating;

  /// No description provided for @adminUserRegionAll.
  ///
  /// In uz, this message translates to:
  /// **'Barcha viloyatlar'**
  String get adminUserRegionAll;

  /// No description provided for @adminUserRegionFilterHint.
  ///
  /// In uz, this message translates to:
  /// **'Viloyat bo‘yicha'**
  String get adminUserRegionFilterHint;

  /// No description provided for @adminFeedbackSectionTitle.
  ///
  /// In uz, this message translates to:
  /// **'Feedback va shikoyatlar'**
  String get adminFeedbackSectionTitle;

  /// No description provided for @adminFeedbackTabComplaints.
  ///
  /// In uz, this message translates to:
  /// **'Shikoyatlar'**
  String get adminFeedbackTabComplaints;

  /// No description provided for @adminFeedbackTabAll.
  ///
  /// In uz, this message translates to:
  /// **'Hammasi'**
  String get adminFeedbackTabAll;

  /// No description provided for @adminFeedbackLowRating.
  ///
  /// In uz, this message translates to:
  /// **'Past baho (≤2)'**
  String get adminFeedbackLowRating;

  /// No description provided for @adminFeedbackSenderToCourier.
  ///
  /// In uz, this message translates to:
  /// **'Yuboruvchi → kuryer'**
  String get adminFeedbackSenderToCourier;

  /// No description provided for @adminComplaintReview.
  ///
  /// In uz, this message translates to:
  /// **'Ko‘rib chiqish'**
  String get adminComplaintReview;

  /// No description provided for @adminComplaintStatusLabel.
  ///
  /// In uz, this message translates to:
  /// **'Holat'**
  String get adminComplaintStatusLabel;

  /// No description provided for @adminComplaintNoteLabel.
  ///
  /// In uz, this message translates to:
  /// **'Admin izohi'**
  String get adminComplaintNoteLabel;

  /// No description provided for @adminComplaintSave.
  ///
  /// In uz, this message translates to:
  /// **'Saqlash'**
  String get adminComplaintSave;

  /// No description provided for @adminComplaintStatusNew.
  ///
  /// In uz, this message translates to:
  /// **'Yangi'**
  String get adminComplaintStatusNew;

  /// No description provided for @adminComplaintStatusReviewed.
  ///
  /// In uz, this message translates to:
  /// **'Ko‘rib chiqilgan'**
  String get adminComplaintStatusReviewed;

  /// No description provided for @adminComplaintStatusResolved.
  ///
  /// In uz, this message translates to:
  /// **'Hal qilingan'**
  String get adminComplaintStatusResolved;

  /// No description provided for @adminRegionsSectionTitle.
  ///
  /// In uz, this message translates to:
  /// **'Hudud tahlili'**
  String get adminRegionsSectionTitle;

  /// No description provided for @adminRegionsCompleted.
  ///
  /// In uz, this message translates to:
  /// **'Yakunlangan buyurtmalar'**
  String get adminRegionsCompleted;

  /// No description provided for @adminRegionsOrders.
  ///
  /// In uz, this message translates to:
  /// **'Buyurtmalar'**
  String get adminRegionsOrders;

  /// No description provided for @adminRegionsSenders.
  ///
  /// In uz, this message translates to:
  /// **'Yuboruvchilar'**
  String get adminRegionsSenders;

  /// No description provided for @adminRegionsCouriers.
  ///
  /// In uz, this message translates to:
  /// **'Kuryerlar'**
  String get adminRegionsCouriers;

  /// No description provided for @adminRegionsComplaints.
  ///
  /// In uz, this message translates to:
  /// **'Shikoyatlar (user)'**
  String get adminRegionsComplaints;

  /// No description provided for @adminRegionsSelectRegion.
  ///
  /// In uz, this message translates to:
  /// **'Viloyat tafsiloti'**
  String get adminRegionsSelectRegion;

  /// No description provided for @adminHeaderSettings.
  ///
  /// In uz, this message translates to:
  /// **'Sozlamalar'**
  String get adminHeaderSettings;

  /// No description provided for @adminMetaFrom.
  ///
  /// In uz, this message translates to:
  /// **'Kimdan'**
  String get adminMetaFrom;

  /// No description provided for @adminMetaTo.
  ///
  /// In uz, this message translates to:
  /// **'Kimga'**
  String get adminMetaTo;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru', 'uz'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
    case 'uz':
      return AppLocalizationsUz();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
