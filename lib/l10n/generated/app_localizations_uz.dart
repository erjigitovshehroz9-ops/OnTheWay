// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class AppLocalizationsUz extends AppLocalizations {
  AppLocalizationsUz([String locale = 'uz']) : super(locale);

  @override
  String get appTitle => 'Kuryer Auksion';

  @override
  String get splashTagline => 'Tez. Zamonaviy. Qulay yetkazib berish.';

  @override
  String get getStarted => 'Boshlash';

  @override
  String get language => 'Til';

  @override
  String get languageUzbek => 'Oʻzbekcha';

  @override
  String get languageRussian => 'Ruscha';

  @override
  String get languageEnglish => 'Inglizcha';

  @override
  String get back => 'Orqaga';

  @override
  String get continueWord => 'Davom etish';

  @override
  String get save => 'Saqlash';

  @override
  String get retry => 'Qayta urinish';

  @override
  String get loading => 'Yuklanmoqda…';

  @override
  String get errorGeneric => 'Nomaʼlum xatolik';

  @override
  String get phoneLoginTitle => 'Telefon raqamingiz';

  @override
  String get phoneHint => '+998 __ ___ __ __';

  @override
  String get sendCode => 'Kod yuborish';

  @override
  String get errorInvalidPhone => 'Toʻgʻri telefon raqamini kiriting';

  @override
  String get smsTitle => 'SMS tasdiqlash';

  @override
  String get smsSubtitle => 'Raqamingizga yuborilgan kodni kiriting';

  @override
  String get verify => 'Tasdiqlash';

  @override
  String get resendCode => 'Kodni qayta yuborish';

  @override
  String get errorInvalidCode => 'Kod notoʻgʻri yoki muddati oʻtgan';

  @override
  String get offerTitle => 'Ommaviy oferta';

  @override
  String get offerWelcome => 'Xush kelibsiz';

  @override
  String get offerBody =>
      'Ushbu oferta shartnomada xizmat koʻrsatish, toʻlovlar, javobgarlik va maʼlumotlarni qayta ishlash qoidalari bayon etilgan. Ofertaga rozilik bildirmasangiz, roʻyxatdan oʻtishni davom ettira olmaysiz.';

  @override
  String get offerAcceptCheckbox => 'Oferta shartlariga roziman';

  @override
  String get acceptAndContinue => 'Qabul qilish va davom etish';

  @override
  String get errorMustAcceptOffer =>
      'Davom etish uchun ofertaga rozilik bildiring';

  @override
  String get chooseRoleTitle => 'Rolingizni tanlang';

  @override
  String get roleSender => 'Yuboruvchi';

  @override
  String get roleSenderDesc => 'Buyurtma yaratish va kuryer tanlash';

  @override
  String get roleCourier => 'Kuryer';

  @override
  String get roleCourierDesc => 'Auksionda ishtirok etish';

  @override
  String get roleAdmin => 'Administrator';

  @override
  String get roleAdminDesc => 'Platformani boshqarish';

  @override
  String get confirmRole => 'Tanlash';

  @override
  String get senderHomeTitle => 'Bosh sahifa';

  @override
  String get courierHomeTitle => 'Kuryer paneli';

  @override
  String get adminHomeTitle => 'Admin paneli';

  @override
  String get whereToHint => 'Qayerga yetkazish kerak?';

  @override
  String get createJob => 'Buyurtma yaratish';

  @override
  String get nearbyCouriers => 'Yaqin atrofdagi kuryerlar';

  @override
  String get activeJobs => 'Faol buyurtmalar';

  @override
  String get demoJobCardTitle => 'Namuna buyurtma';

  @override
  String get contactsHiddenUntilAuction =>
      'Auksion tugaguncha aloqa maʼlumotlari yashirin';

  @override
  String get contactsVisibleAfterWinner =>
      'Gʻolib tanlangach telefon va chat ochiladi';

  @override
  String get auctionStatusLive => 'Auksion jonli';

  @override
  String get auctionStatusEnded => 'Auksion yakunlandi';

  @override
  String get winnerSelected => 'Gʻolib tanlandi';

  @override
  String get topBid => 'Eng yuqori taklif';

  @override
  String get timeLeft => 'Qolgan vaqt';

  @override
  String secondsShort(int count) {
    return '$count s';
  }

  @override
  String get placeBid => 'Taklif berish';

  @override
  String get jobDescriptionLabel => 'Izoh';

  @override
  String get jobTitleLabel => 'Buyurtma nomi';

  @override
  String get translateDemoHint =>
      'Matn kiriting — 3 tilda saqlanadi (demo tarjima)';

  @override
  String get previewForLocale => 'Tanlangan tilda koʻrinishi';

  @override
  String get storedUz => 'Asl (oʻzbekcha)';

  @override
  String get storedRu => 'Saqlangan ruscha';

  @override
  String get storedEn => 'Saqlangan inglizcha';

  @override
  String get logout => 'Chiqish';

  @override
  String get settings => 'Sozlamalar';

  @override
  String get userDemoName => 'Foydalanuvchi';

  @override
  String get selectWinner => 'Gʻolibni tanlash';

  @override
  String get signInRequired => 'Avtorizatsiyadan oʻting';

  @override
  String get noOpenAuctions => 'Hozircha ochiq auksion yoʻq';

  @override
  String get courierOrdersTabAuction => 'Ro\'yxat';

  @override
  String get courierOrdersSubtabList => 'Buyurtmalar';

  @override
  String get courierOrdersTabInProgress => 'Jarayonda';

  @override
  String get courierOrdersTabCompleted => 'Bajarilgan';

  @override
  String get courierOrdersEmptyInProgress =>
      'Hozircha jarayondagi buyurtmalar yoʻq. Auksion tugagach, siz gʻolib boʻlsangiz, ular shu yerda chiqadi.';

  @override
  String get courierOrdersEmptyCompleted =>
      'Hozircha bajarilgan buyurtmalar yoʻq.';

  @override
  String get adminDashboard => 'Admin panel';

  @override
  String get adminStatistics => 'Statistika';

  @override
  String get adminUsers => 'Foydalanuvchilar';

  @override
  String get adminLiveMap => 'Jonli xarita';

  @override
  String get adminSectionOverview => 'Asosiy ko\'rsatkichlar';

  @override
  String get adminSectionOrders => 'Buyurtmalar va auksionlar';

  @override
  String get adminSectionUsersSecurity => 'Foydalanuvchilar va xavfsizlik';

  @override
  String get adminSectionShortcuts => 'Tezkor boshqaruv';

  @override
  String get adminChartOrderStatus => 'Buyurtmalar taqsimoti';

  @override
  String get adminNavStatsSubtitle => 'Viloyatlar bo\'yicha tahlil';

  @override
  String get adminNavUsersSubtitle => 'Rollar va bloklash';

  @override
  String get adminNavMapSubtitle => 'Kuryerlar joylashuvi';

  @override
  String adminMapMarkerCount(int count) {
    return '$count ta kuryer nuqtasi';
  }

  @override
  String get adminMapEmptyNoJobsTitle => 'Jonli kuzatuv yo‘q';

  @override
  String get adminMapEmptyNoJobsBody =>
      'Hozircha faol kuzatuvdagi buyurtmalar yo‘q. Bir ozdan keyin yangilang.';

  @override
  String get adminMapEmptyNoGpsTitle => 'Joylashuv kelmagan';

  @override
  String get adminMapEmptyNoGpsBody =>
      'Buyurtmalar bor, lekin kuryerlar joylashuvi hali yuborilmagan.';

  @override
  String get chartLegendCompleted => 'Bajarilgan';

  @override
  String get chartLegendActive => 'Jarayonda';

  @override
  String get chartLegendCancelled => 'Bekor qilingan';

  @override
  String get statTotalUsers => 'Jami foydalanuvchilar';

  @override
  String get statSenders => 'Yuboruvchilar soni';

  @override
  String get statCouriers => 'Kuryerlar soni';

  @override
  String get statActiveJobs => 'Faol buyurtmalar';

  @override
  String get statLiveAuctions => 'Faol auksionlar';

  @override
  String get statCompleted => 'Bajarilgan buyurtmalar';

  @override
  String get statUncompletedJobs => 'Bajarilmagan buyurtmalar';

  @override
  String get statCancelled => 'Bekor qilingan';

  @override
  String get statBlocked => 'Bloklangan foydalanuvchilar';

  @override
  String get statComplaints => 'Shikoyatlar soni';

  @override
  String get noJobsFound => 'Buyurtmalar topilmadi';

  @override
  String get regionLabel => 'Viloyat';

  @override
  String get districtLabel => 'Tuman/Shahar';

  @override
  String get tabList => 'Ro‘yxat';

  @override
  String get tabMap => 'Xarita';

  @override
  String get courierMapNoOrdersInDistrict => 'Bu hududda buyurtmalar topilmadi';

  @override
  String get courierMapOpenDetail => 'Batafsil';

  @override
  String courierMapCoordsShort(String lat, String lng) {
    return '$lat, $lng';
  }

  @override
  String get courierPanelBannerTitle => 'KURYER PANELI';

  @override
  String courierGreeting(String name) {
    return 'Assalomu alaykum, $name!';
  }

  @override
  String get courierNavHome => 'Bosh sahifa';

  @override
  String get courierNavOrders => 'Buyurtmalar';

  @override
  String get courierNavMaps => 'Xaritalar';

  @override
  String get courierNavAccount => 'Mening hisobim';

  @override
  String get senderBottomNavSwitchRole => 'Rolni almashtirish';

  @override
  String get bottomNavWallet => 'Hisobim';

  @override
  String get courierCardCreated => 'Yaratilgan vaqti';

  @override
  String get courierStatusWaiting => 'Kutish jarayonida';

  @override
  String get courierDeliveredBadge => 'Yetkazilgan';

  @override
  String get courierCardIdLabel => 'ID';

  @override
  String get jobDetails => 'Buyurtma tafsilotlari';

  @override
  String get jobDetailProductInfoTitle => 'Mahsulot ma\'lumotlari';

  @override
  String get jobDetailNoProductImage => 'Mahsulot rasmi yuklanmagan';

  @override
  String get jobDetailVolumeShort => 'Hajmi';

  @override
  String get pickupLocation => 'Qayerdan olinadi';

  @override
  String get dropoffLocation => 'Qayerga yetkaziladi';

  @override
  String get mapDualFlowCardTitle => 'Manzillarni xaritada belgilang';

  @override
  String get mapPickerNextDropoff => 'Keyingi: yetkazish manzili';

  @override
  String get mapPickerConfirmBoth => 'Manzillarni tasdiqlash';

  @override
  String get recipientNameLabel => 'Qabul qiluvchi ismi';

  @override
  String get recipientPhoneLabel => 'Qabul qiluvchi telefoni';

  @override
  String get recipientPhoneHelper =>
      '+998 yozuvi qatʼiy. Keyingi 9 ta raqamni toʻgʻri kiriting — aks holda kuryer qo‘ng‘iroq qila olmasligi mumkin.';

  @override
  String get joinAuctionCta => 'Auksionga qo‘shilish';

  @override
  String get acceptLowerPrice => 'Narxni qabul qilish';

  @override
  String get statusAuction => 'Auksion';

  @override
  String get statusCompleted => 'Bajarildi';

  @override
  String get complaint => 'Shikoyat';

  @override
  String get praise => 'Maqtov';

  @override
  String get mapSearch => 'Qidiruv';

  @override
  String get selectedLocation => 'Tanlangan joy';

  @override
  String get recenterMap => 'Markazga qaytarish';

  @override
  String get blockUser => 'Foydalanuvchini bloklash';

  @override
  String get auctionCurrentOffer => 'Joriy taklif';

  @override
  String get auctionFloor => 'Minimal narx';

  @override
  String get timeLeftShort => 'Qolgan vaqt';

  @override
  String get auctionHistory => 'Auksion tarixi';

  @override
  String get auctionLiveScreenTitle => 'Jonli auksion';

  @override
  String get auctionOngoingLabel => 'Auksion davom etmoqda';

  @override
  String get auctionWaitingStartLabel => 'Auksion boshlanishi kutilmoqda';

  @override
  String auctionTimeLeftLine(String time) {
    return '$time qoldi';
  }

  @override
  String auctionCouriersParticipatingCount(int count) {
    return '$count ta kuryer ishtirok etmoqda';
  }

  @override
  String get auctionOrderDetailsTitle => 'Buyurtma tafsilotlari';

  @override
  String get auctionPickupMapLabel => 'Olish:';

  @override
  String get auctionDropoffMapLabel => 'Yetkazish:';

  @override
  String auctionRouteDistance(String km) {
    return '$km km';
  }

  @override
  String get auctionSenderTrustTitle => 'Yuboruvchi haqida';

  @override
  String get auctionCourierRatingsTitle => 'Kuryerlar reytingi';

  @override
  String get auctionAgreePriceCta => 'Narxga roziman →';

  @override
  String get auctionWatchCta => 'Kuzatish';

  @override
  String get auctionParticipateOutlined => 'Ishtirok etish';

  @override
  String get auctionYouAreLeading => 'Siz yetakchisiz';

  @override
  String auctionReviewsCount(int count) {
    return '$count ta sharh';
  }

  @override
  String get auctionStartPriceLabel => 'Boshlang‘ich narx';

  @override
  String get auctionHozirgiTaklif => 'Hozirgi taklif';

  @override
  String get auctionYourPriceLabel => 'Siz qabul qilgan narx';

  @override
  String get auctionNextOfferLabel => 'Keyingi taklif («Narxga roziman»)';

  @override
  String get auctionEndedYouWonBody =>
      'Tabriklaymiz! Buyurtma sizga biriktirildi. Buyurtmalar roʻyxatida davom eting.';

  @override
  String get auctionEndedOtherWinnerBody =>
      'Auksion boshqa kuryer foydasiga yakunlandi.';

  @override
  String get auctionEndedNoWinnerBody =>
      'Vaqt tugadi. Buyurtma qayta ochiq auksion uchun qoldi.';

  @override
  String get auctionEndedGenericBody => 'Auksion yakunlandi.';

  @override
  String get chooseRoleSubtitle => 'Ilovadan qanday foydalanmoqchisiz?';

  @override
  String get stepProduct => 'Mahsulot';

  @override
  String get stepAddresses => 'Manzillar';

  @override
  String get stepRecipient => 'Qabul qiluvchi';

  @override
  String get stepReview => 'Tekshirish';

  @override
  String get fragileItem => 'Nozik mahsulot';

  @override
  String get needsColdChain => 'Sovuq saqlash';

  @override
  String get completedJobsLabel => 'Bajarilgan ishlar';

  @override
  String get markPickedUp => 'Qabul qildim';

  @override
  String get markDelivered => 'Yetkazib berdim';

  @override
  String get orderContactSectionTitle => 'Bog‘lanish ma’lumotlari';

  @override
  String get orderWinnerOutcomeTitle => 'G‘olib aniqlandi';

  @override
  String get orderFinalPriceLabel => 'Yakuniy narx';

  @override
  String get orderWinnerSelectedAtLabel => 'Tanlangan vaqt';

  @override
  String get orderAuctionStepsCountLabel => 'Auksion qadamlari';

  @override
  String get orderAddressesHiddenForNonWinner =>
      'Manzillar faqat auksion g‘olibiga ko‘rinadi.';

  @override
  String courierRatingStarsLabel(String value) {
    return 'Reyting: $value';
  }

  @override
  String get deliveryNoteOptional => 'Izoh (ixtiyoriy)';

  @override
  String get submitFeedback => 'Fikr bildirish';

  @override
  String get feedbackComplaintTitle => 'Shikoyatingizni yozing';

  @override
  String get feedbackComplaintHint => 'Nima bo‘lganini qisqacha tushuntiring…';

  @override
  String get feedbackPraiseTitle => 'Minnatdorchilik';

  @override
  String get feedbackPraiseStarsHint => '1–5 yulduz bilan baholang';

  @override
  String get feedbackPraiseEmojiHint => 'Yoki smayl bilan:';

  @override
  String get feedbackSend => 'Yuborish';

  @override
  String get feedbackSentThanks => 'Rahmat, fikringiz qabul qilindi';

  @override
  String get feedbackAlreadySubmitted =>
      'Bu buyurtma uchun siz allaqachon fikr bildirgansiz (shikoyat yoki maqtov — bir marta).';

  @override
  String get rateCourierCta => 'Kuryerni baholash';

  @override
  String get rateSenderCta => 'Yuboruvchini baholash';

  @override
  String get orderFeedbackSheetTitleCourier => 'Kuryerni baholang';

  @override
  String get orderFeedbackSheetTitleSender => 'Yuboruvchini baholang';

  @override
  String get orderFeedbackStarsLabel => 'Baholash (1–5 yulduz, majburiy)';

  @override
  String get orderFeedbackTypeNeutral => 'Faqat baho';

  @override
  String get orderFeedbackTypeComplaint => 'Shikoyat';

  @override
  String get orderFeedbackTypePraise => 'Maqtov';

  @override
  String get orderFeedbackCommentOptional => 'Izoh (ixtiyoriy)';

  @override
  String get orderFeedbackYourSummaryTitle => 'Sizning bahoyingiz';

  @override
  String orderFeedbackSummaryRating(int stars) {
    return '$stars / 5';
  }

  @override
  String get orderFeedbackSummaryTypeRating => 'Baho';

  @override
  String get orderFeedbackSummaryTypeComplaint => 'Shikoyat';

  @override
  String get orderFeedbackSummaryTypePraise => 'Maqtov';

  @override
  String orderFeedbackSummaryCategory(String name) {
    return 'Kategoriya: $name';
  }

  @override
  String get fbCatComplaintLate => 'Kechikdi';

  @override
  String get fbCatComplaintRude => 'Muomala yomon';

  @override
  String get fbCatComplaintCareless => 'Buyurtmaga ehtiyotsiz munosabat';

  @override
  String get fbCatComplaintAddress => 'Manzil muammosi';

  @override
  String get fbCatOther => 'Boshqa';

  @override
  String get fbCatPraiseFast => 'Tez yetkazdi';

  @override
  String get fbCatPraisePolite => 'Xushmuomala';

  @override
  String get fbCatPraiseCareful => 'Ehtiyotkor';

  @override
  String get fbCatPraiseReliable => 'Aniq va ishonchli';

  @override
  String get catComplaintLate => 'Kechikdi';

  @override
  String get catComplaintDamaged => 'Zarar yetdi';

  @override
  String get catComplaintCommunication => 'Yomon aloqa';

  @override
  String get catPraiseFast => 'Tez yetkazdi';

  @override
  String get catPraisePolite => 'Xushmuomala';

  @override
  String get catPraiseCareful => 'Ehtiyotkor';

  @override
  String get feedbackCategory => 'Kategoriya';

  @override
  String get validationRequired => 'Majburiy maydon';

  @override
  String get fieldOptionalHint => 'Ixtiyoriy';

  @override
  String get createOrderTitle => 'Buyurtma yaratish';

  @override
  String get createJobConfirmTitle => 'Buyurtmani tasdiqlash';

  @override
  String get createJobSenderAddressLabel => 'Yuboruvchi manzili';

  @override
  String get createJobReceiverAddressLabel => 'Qabul qiluvchi manzili';

  @override
  String get createJobDeliveryTimeSection => 'Yetkazib berish vaqti';

  @override
  String get createJobPickupSlotLabel => 'Olish';

  @override
  String get createJobDeliverySlotLabel => 'Yetkazish';

  @override
  String get createJobAboutPackage => 'Paket haqida';

  @override
  String get createJobPackageTypeShort => 'Turi';

  @override
  String get createJobPackageSizeShort => 'O‘lchami';

  @override
  String get createJobPackageWeightShort => 'Og‘irligi';

  @override
  String get createJobPackageDescShort => 'Izoh';

  @override
  String get createJobEstimatedPrice => 'Taxminiy narx';

  @override
  String get createJobFinalPriceDisclaimer =>
      'Yakuniy narx auksion davomida aniqlanadi';

  @override
  String get createJobAuctionHint =>
      'Buyurtma joylangandan keyin kuryerlar auksionda ishtirok etadi';

  @override
  String get createJobPlaceOrder => 'Buyurtmani joylash';

  @override
  String get productNameLabel => 'Mahsulot nomi';

  @override
  String get productTypeLabel => 'Mahsulot turi';

  @override
  String get weightKg => 'Og‘irligi (kg)';

  @override
  String get volumeCategoryLabel => 'Hajm kategoriyasi';

  @override
  String get orderCommentsLabel => 'Qo‘shimcha izoh';

  @override
  String get orderCommentsHint => 'Buyurtma haqida qo‘shimcha ma’lumot yozing';

  @override
  String orderCommentsCharCounter(int current, int max) {
    return '$current/$max';
  }

  @override
  String get orderSuitableTransportTitle => 'Mos transport';

  @override
  String get orderRequiredTransportTitle => 'Transport turi';

  @override
  String get validationSelectSuitableTransport =>
      'Kamida bitta transportni tanlang (bir nechtasini tanlash mumkin)';

  @override
  String get validationSelectOneTransport =>
      'Buyurtma uchun bitta transport turini tanlang';

  @override
  String get transportLabelPiyoda => 'Piyoda';

  @override
  String get transportLabelVelosiped => 'Velosiped / skuter';

  @override
  String get transportLabelMoto => 'Moto';

  @override
  String get transportLabelAvto => 'Avto';

  @override
  String get transportLabelTruck => 'Katta yuk avto';

  @override
  String get courierTransportEmptyTitle => 'Transport turi belgilanmagan';

  @override
  String get courierTransportEmptySubtitle =>
      'Buyurtmalarni ko‘rish uchun profilda kamida bitta transport turini tanlang.';

  @override
  String get courierTransportChooseAction => 'Transport tanlash';

  @override
  String get courierProfileTransportLabel => 'Transport turlari';

  @override
  String get courierProfileTransportChange => 'O‘zgartirish';

  @override
  String get courierTransportSheetTitleProfile =>
      'Transport turlarini yangilang';

  @override
  String get courierTransportSheetTitleSetup => 'Transport turini tanlang';

  @override
  String get courierFilterAllDistricts => 'Barcha tumanlar';

  @override
  String get jobTransportMismatchMessage =>
      'Bu buyurtma sizning transport turlaringizga mos emas.';

  @override
  String get volumeCatVerySmall => 'Juda kichik';

  @override
  String get volumeCatSmall => 'Kichik';

  @override
  String get volumeCatMedium => 'O‘rta';

  @override
  String get volumeCatLarge => 'Katta';

  @override
  String get volumeCatVeryLarge => 'Katta+';

  @override
  String get dimensionsMmLabel => 'Razmeri (mm)';

  @override
  String get dimensionsMmHint => '1000x500x200';

  @override
  String get validationDimensionsFormat =>
      'Format: uchta son, masalan 1000x500x200';

  @override
  String get validationDimensionsRequired =>
      'Tanlangan hajm uchun razmer majburiy';

  @override
  String get startingPrice => 'Boshlang‘ich narx';

  @override
  String get paymentType => 'To‘lov turi';

  @override
  String get paymentCash => 'Naqd';

  @override
  String get paymentCard => 'Karta';

  @override
  String get paymentPrepaid => 'Oldindan';

  @override
  String get deliveryTimeTitle => 'Yetkazish vaqti';

  @override
  String get deliveryFast => 'Tez';

  @override
  String get deliveryRelaxed => 'Bemalol';

  @override
  String get deliveryCustom => 'Vaqtni tanlash';

  @override
  String get deliveryUntilHint => 'Masalan: 21:00 gacha';

  @override
  String get mapAddressCity => 'Shahar';

  @override
  String get mapAddressDistrict => 'Tuman';

  @override
  String get mapAddressRegion => 'Viloyat';

  @override
  String get mapDistanceLabel => 'Masofa';

  @override
  String get mapDistanceApproximate => 'Taxminiy (to‘g‘ri chiziq bo‘yicha)';

  @override
  String get mapPickupMarkerHint => 'Olib ketish nuqtasi';

  @override
  String get jobRouteMapTitle => 'Yo‘l xaritasi';

  @override
  String get jobMapNoCoordinates =>
      'Xarita uchun manzil koordinatalari mavjud emas.';

  @override
  String get jobMapMarkerA => 'A';

  @override
  String get jobMapMarkerB => 'B';

  @override
  String get jobMapOneCoordinateOnly =>
      'Faqat bitta manzil koordinatasi mavjud — masofa hisoblanmaydi.';

  @override
  String get courierJobMapToPickupTitle => 'Olish nuqtasi (A) ga yo‘l';

  @override
  String get courierJobMapToDropoffTitle => 'Yetkazish nuqtasi (B) ga yo‘l';

  @override
  String get courierJobMapGpsUnavailable =>
      'Joylashuv aniqlanmadi. «Mening joyim» tugmasidan foydalaning.';

  @override
  String get jobDimensionsMm => 'Razmeri (mm)';

  @override
  String get productPhoto => 'Mahsulot rasmi';

  @override
  String get validationProductPhotoRequired => 'Mahsulot rasmini joylang';

  @override
  String get takePhoto => 'Rasmga olish';

  @override
  String get chooseFile => 'Fayldan tanlash';

  @override
  String get searchJobsHint => 'Buyurtmalarni qidirish';

  @override
  String get profileSection => 'Profil';

  @override
  String get senderProfileNameLabel => 'Ism';

  @override
  String get senderProfilePhoneLabel => 'Telefon';

  @override
  String get senderProfileRoleLabel => 'Rol';

  @override
  String get senderProfileLanguageLabel => 'Til';

  @override
  String get senderProfileStatusLabel => 'Holat';

  @override
  String get senderProfileNameEmpty => 'Ism kiritilmagan';

  @override
  String get senderProfilePhoneEmpty => 'Telefon raqam mavjud emas';

  @override
  String get senderProfileStatusActive => 'Faol';

  @override
  String get senderProfileStatusBlocked => 'Bloklangan';

  @override
  String get senderProfilePhoneVerified => 'Telefon tasdiqlangan';

  @override
  String get senderProfilePhoneNotVerified => 'Telefon tasdiqlanmagan';

  @override
  String get senderProfileVerificationLabel => 'Telefon holati';

  @override
  String get senderWalletTitle => 'Hamyon';

  @override
  String get senderWalletSubtitle => 'Tez orada mavjud bo‘ladi.';

  @override
  String get senderProfileEditSection => 'Ma’lumotlarni tahrirlash';

  @override
  String get senderProfileFullNameLabel => 'To‘liq ism';

  @override
  String get senderProfileFullNameHint => 'Ism va familiyangizni kiriting';

  @override
  String get senderProfileSecondaryPhoneLabel => 'Qo‘shimcha telefon';

  @override
  String get senderProfileSecondaryPhoneHint => '+998 __ ___ __ __';

  @override
  String get senderProfileChangePhoto => 'Rasmni o‘zgartirish';

  @override
  String get senderProfileRemovePhoto => 'Rasmni olib tashlash';

  @override
  String get senderProfileEditTooltip => 'Tahrirlash';

  @override
  String get senderProfileSave => 'Saqlash';

  @override
  String get senderProfileSaving => 'Saqlanmoqda…';

  @override
  String get senderProfileSaveSuccess => 'Profil yangilandi';

  @override
  String get senderProfileInvalidSecondaryPhone =>
      'To‘g‘ri O‘zbekiston raqamini kiriting';

  @override
  String get senderProfileSecondarySameAsPrimary =>
      'Asosiy raqamdan boshqa raqam kiriting';

  @override
  String get senderProfilePrimaryPhoneReadOnly => 'Asosiy telefon (tizim)';

  @override
  String get openAdminPanel => 'Admin panelga o‘tish';

  @override
  String get statusPosted => 'Yaratildi';

  @override
  String get senderOrderStatusPosted => 'Kutilmoqda';

  @override
  String get senderOrderPriceLabel => 'Narx';

  @override
  String get senderOrderMinStavkaSuffix => '(min. stavka)';

  @override
  String get senderOrderContactsHint =>
      'Kuryer tanlangach aloqa ma\'lumotlari ko\'rinadi';

  @override
  String get statusAssigned => 'Biriktirildi';

  @override
  String get statusPickedUp => 'Olib ketildi';

  @override
  String get statusDelivered => 'Yetkazildi';

  @override
  String get senderNotificationsTooltip => 'Bildirishnomalar';

  @override
  String get senderNotificationsEmpty => 'Hozircha yangi bildirishnomalar yo‘q';

  @override
  String get senderSnackbarAuctionStarted =>
      'Auksion boshlandi — buyurtma «Jarayonda» bo‘limida';

  @override
  String get senderSnackbarAuctionEndedAssigned =>
      'Auksion tugadi — kuryer biriktirildi';

  @override
  String get senderSnackbarAuctionEndedReopened =>
      'Auksion tugadi — g‘olib chiqmadi, buyurtma qayta kutilmoqda';

  @override
  String get senderSnackbarAuctionEndedCancelled =>
      'Auksion tugadi — buyurtma bekor qilindi';

  @override
  String get senderNotifCourierNearPickup1Km =>
      'Kuryer olib ketish manziliga yaqinlashmoqda (~1 km)';

  @override
  String get senderNotifCourierNearDropoff5Km =>
      'Kuryer yetkazish manziliga yaqinlashmoqda (~5 km)';

  @override
  String get senderNotifCourierNearDropoff2Km =>
      'Kuryer yetkazish manziliga yaqinlashmoqda (~2 km)';

  @override
  String senderNotifAuctionStartedBody(String product) {
    return '«$product». Shu buyurtmangiz uchun kuryerlar taklif bildirmoqda. Buyurtmangiz «Jarayonda» bo‘limiga o‘tkazildi.';
  }

  @override
  String senderNotifAuctionEndedAssignedBody(
      String product, String courier, String amount) {
    return '«$product». «$courier» kuryerning taklifi $amount yutuq deb belgilandi. To‘liq ma’lumot uchun Buyurtma tafsilotlariga o‘ting.';
  }

  @override
  String senderNotifAuctionReopenedBody(String product) {
    return '«$product». Auksion tugadi — g‘olib chiqmadi, buyurtma qayta kutilmoqda.';
  }

  @override
  String senderNotifAuctionCancelledBody(String product) {
    return '«$product». Auksion tugadi — buyurtma bekor qilindi.';
  }

  @override
  String get senderNotifOpenJobDetails => 'Buyurtma tafsilotlari';

  @override
  String get senderNotifUnknownCourier => 'Kuryer';

  @override
  String get liveTrackingBadge => 'Jonli kuzatuv';

  @override
  String get courierTrackingSendingLabel => 'Jonli lokatsiya yuborilmoqda';

  @override
  String get courierTrackingLocationPermissionDenied =>
      'Joylashuv ruxsati yo‘q yoki GPS o‘chiq. Sozlamalardan ruxsat bering — jonli kuzatuv uchun kerak.';

  @override
  String get trackingLastUpdatedPrefix => 'So‘nggi yangilanish:';

  @override
  String get senderTrackingWaitingCourierLocation =>
      'Kuryer joylashuvi hali uzatilmagan. Kuryer ushbu buyurtmani ilovada ochgan va yo‘lga chiqqanidan keyin xarita paydo bo‘ladi.';

  @override
  String get senderTrackingNoCoordinatesForLeg =>
      'Bu marshrut uchun manzil koordinatalari kiritilmagan.';

  @override
  String get senderTrackingTapToEnlarge =>
      'Kattalashtirish uchun xaritaga bosing';

  @override
  String get senderTrackingFullscreenTitlePickup => 'Kuryer — olish nuqtasi';

  @override
  String get senderTrackingFullscreenTitleDropoff =>
      'Kuryer — yetkazish manzili';

  @override
  String senderTrackingDistanceMeters(int m) {
    return '$m m';
  }

  @override
  String senderTrackingDistanceKm(String km) {
    return '$km km';
  }

  @override
  String senderTrackingEtaApproxMinutes(int minutes) {
    return 'Taxminan $minutes daqiqa';
  }

  @override
  String senderTrackingEtaHoursMinutes(int hours, int minutes) {
    return 'Taxminan $hours soat $minutes daqiqa';
  }

  @override
  String get senderNotificationsSheetTitle => 'Bildirishnomalar';

  @override
  String get senderNotificationsLoadError =>
      'Bildirishnomalarni yuklab bo‘lmadi';

  @override
  String get senderNotificationsTapToRead => 'Batafsil uchun bosing';

  @override
  String get senderNotificationsTimeJustNow => 'Hozirgina';

  @override
  String senderNotificationsTimeMinutesAgo(int count) {
    return '$count daqiqa oldin';
  }

  @override
  String senderNotificationsTimeHoursAgo(int count) {
    return '$count soat oldin';
  }

  @override
  String get createJobMenuMore => 'Sozlamalar';

  @override
  String get createJobMenuChangeTheme => 'Rejimni o‘zgartirish';

  @override
  String get createJobMenuContactUs => 'Biz bilan bog‘lanish';

  @override
  String get createJobThemeTitle => 'Rejimni tanlang';

  @override
  String get createJobThemeLight => 'Kunduzgi rejim';

  @override
  String get createJobThemeDark => 'Tungi rejim';

  @override
  String get createJobThemeSystem => 'Tizim bo‘yicha';

  @override
  String get createJobContactTitle => 'Biz bilan bog‘lanish';

  @override
  String get createJobContactPickType => 'Murojaat turini tanlang';

  @override
  String get createJobContactComplaint => 'Shikoyat';

  @override
  String get createJobContactPraise => 'Maqtov';

  @override
  String get createJobContactApplication => 'Ariza';

  @override
  String get createJobContactSuggestion => 'Taklif';

  @override
  String get createJobContactMessageLabel => 'Murojaatingizni yozing';

  @override
  String get createJobContactMessageHint => 'Murojaat matnini kiriting';

  @override
  String get createJobContactSubmit => 'Yuborish';

  @override
  String get createJobContactSuccess => 'Murojaatingiz yuborildi';

  @override
  String get createJobValidationContactType => 'Murojaat turini tanlang';

  @override
  String get createJobValidationContactMessage => 'Murojaat matnini kiriting';

  @override
  String get createJobValidationMessageTooShort =>
      'Matn juda qisqa (kamida 15 belgi)';

  @override
  String get adminContactRequests => 'Murojaatlar';

  @override
  String get adminContactRequestsSubtitle => 'Foydalanuvchi xabarlari';

  @override
  String get adminContactRequestDetail => 'Murojaat tafsilotlari';

  @override
  String get supportRequestStatusNew => 'Yangi';

  @override
  String get supportRequestStatusRead => 'O‘qilgan';

  @override
  String get supportRequestStatusResolved => 'Hal qilindi';

  @override
  String get supportRequestFullMessage => 'To‘liq matn';

  @override
  String get supportRequestMarkRead => 'O‘qilgan deb belgilash';

  @override
  String get supportRequestMarkResolved => 'Hal qilindi';

  @override
  String get adminPanelSubtitle => 'Kuryer boshqaruv paneli';

  @override
  String get adminBottomNavDashboard => 'Boshqaruv';

  @override
  String get adminBottomNavUsers => 'Foydalanuvchilar';

  @override
  String get adminBottomNavOrders => 'Buyurtmalar';

  @override
  String get adminBottomNavAuctions => 'Auksionlar';

  @override
  String get adminBottomNavReports => 'Hisobotlar';

  @override
  String get adminBottomNavFinance => 'Moliya';

  @override
  String get adminPanelNavSettings => 'Sozlamalar';

  @override
  String get adminQuickActionsTitle => 'Tezkor amallar';

  @override
  String get adminActionViewList => 'Ko\'rish';

  @override
  String get adminActionEditRole => 'Rolni tahrirlash';

  @override
  String get adminActionBan => 'Bloklash';

  @override
  String get adminActionUnblock => 'Blokdan chiqarish';

  @override
  String get adminActionVerify => 'Tasdiqlash';

  @override
  String get adminFinanceSectionTitle => 'Moliya va tranzaksiyalar';

  @override
  String get adminFinanceTotalRevenue => 'Jami tushum';

  @override
  String get adminFinanceCommissions => 'Olingan komissiyalar';

  @override
  String get adminFinanceSuccessfulPayments => 'Muvaffaqiyatli to\'lovlar';

  @override
  String get adminFinanceCourierPayouts => 'Kuryer to\'lovlari';

  @override
  String get adminFinanceDemoHint => 'Namuna ko\'rsatkichlar';

  @override
  String get adminReportsSectionTitle => 'Hisobotlar va shikoyatlar';

  @override
  String get adminOrderFilterAll => 'Barchasi';

  @override
  String get adminOrderFilterPending => 'Kutilmoqda';

  @override
  String get adminOrderFilterAuction => 'Auksion';

  @override
  String get adminOrderFilterInDelivery => 'Yetkazilmoqda';

  @override
  String get adminOrderFilterCompleted => 'Bajarildi';

  @override
  String get adminUserFilterAll => 'Barchasi';

  @override
  String get adminUserFilterSenders => 'Yuboruvchilar';

  @override
  String get adminUserFilterCouriers => 'Kuryerlar';

  @override
  String get adminUserFilterBlocked => 'Bloklanganlar';

  @override
  String get adminUserFilterNew => 'Yangilar';

  @override
  String get adminUserFilterComplaints => 'Shikoyatli';

  @override
  String get adminUserFilterAdmins => 'Adminlar';

  @override
  String get adminSettingsSectionShortcuts => 'Tizim va yo\'nalishlar';

  @override
  String get adminOpenStatistics => 'Statistikani ochish';

  @override
  String get adminOpenMap => 'Jonli xarita';

  @override
  String get adminOpenContactRequests => 'Murojaatlarni ochish';

  @override
  String get adminOpenFullSettings => 'Ilova sozlamalari';

  @override
  String get adminComingSoonNotifications => 'Bildirishnomalar tez orada';

  @override
  String get adminSearchHint => 'Qidirish';

  @override
  String get adminLanguageTileTitle => 'Ilova tili';

  @override
  String get adminOrdersSectionTitle => 'Buyurtmalar';

  @override
  String get adminAuctionsSectionTitle => 'Auksionlar';

  @override
  String get adminNoJobsInList => 'Ro\'yxat bo\'sh';

  @override
  String get adminRegionPerformanceTitle => 'Hududlar bo\'yicha samaradorlik';

  @override
  String get adminRegionPerformanceHint =>
      'Namuna jadval — keyinroq real ma\'lumot';

  @override
  String get adminAnalyticsSectionTitle => 'Tahlil va diagrammalar';

  @override
  String get adminChartDeliveryGrowth => 'Yetkazib berish dinamikasi';

  @override
  String get adminChartUsersVsCourier => 'Foydalanuvchilar va kuryerlar';

  @override
  String get adminChartCompletionDonut => 'Yakunlangan buyurtmalar ulushi';

  @override
  String get adminDesignSampleChartNote =>
      'Diagrammalar statistikaga moslashtirilgan namuna';

  @override
  String get adminStatusActive => 'Faol';

  @override
  String get adminStatusBlockedShort => 'Bloklangan';

  @override
  String get adminUserManagementTitle => 'Foydalanuvchilarni boshqarish';

  @override
  String adminJobOrderNumber(String id) {
    return '№ $id';
  }

  @override
  String get adminPickupInfo => 'Olib ketish';

  @override
  String get adminDropoffInfo => 'Yetkazish';

  @override
  String get adminReportSenderCourierComplaints =>
      'Yuboruvchi / kuryer shikoyatlari';

  @override
  String get adminReportFlaggedOrders => 'Belgilangan buyurtmalar';

  @override
  String get adminReportUrgentHighlights => 'Muhim xabarlar';

  @override
  String get adminActionQuickResolve => 'Tez hal qilish';

  @override
  String get adminActionReject => 'Rad etish';

  @override
  String get adminActionInvestigate => 'O\'rganish';

  @override
  String get adminFinancePendingPayouts => 'Kutilayotgan to\'lovlar';

  @override
  String get adminDistrictActivityTitle => 'Tumanlar bo\'yicha faollik';

  @override
  String get adminOrderHotspotsTitle => 'Buyurtmalar nuqtalari';

  @override
  String get adminCourierAvailabilityTitle => 'Kuryer bandligi (namuna)';

  @override
  String get adminGridAddAdmin => 'Admin qo\'shish';

  @override
  String get adminGridManageRoles => 'Rollarni boshqarish';

  @override
  String get adminGridViewReports => 'Hisobotlar';

  @override
  String get adminGridBlockUser => 'Bloklash';

  @override
  String get adminGridApproveCourier => 'Kuryerni tasdiqlash';

  @override
  String get adminGridMonitorAuctions => 'Auksionlar';

  @override
  String get adminGridSystemSettings => 'Tizim sozlamalari';

  @override
  String get adminBottomNavFeedback => 'Feedback';

  @override
  String get adminBottomNavRegions => 'Hududlar';

  @override
  String get adminControlOverviewTitle => 'Operatsion ko‘rinish';

  @override
  String get adminControlFeedbackTitle => 'Feedback va sifat';

  @override
  String get adminControlGeoTitle => 'Geografiya';

  @override
  String get adminControlAuctionTitle => 'Auksion va yetkazish';

  @override
  String get adminControlUsersTotal => 'Jami foydalanuvchilar';

  @override
  String get adminControlSenders => 'Yuboruvchilar';

  @override
  String get adminControlCouriers => 'Kuryerlar';

  @override
  String get adminControlOrdersTotal => 'Jami buyurtmalar';

  @override
  String get adminControlPosted => 'E’lon qilingan';

  @override
  String get adminControlAuctionLive => 'Auksionda';

  @override
  String get adminControlAssigned => 'Tayinlangan';

  @override
  String get adminControlPickedUp => 'Olib ketilgan';

  @override
  String get adminControlDelivered => 'Yetkazilgan';

  @override
  String get adminControlCompleted => 'Yakunlangan';

  @override
  String get adminControlCancelled => 'Bekor qilingan';

  @override
  String get adminControlBlocked => 'Bloklangan';

  @override
  String get adminControlRatingsTotal => 'Jami baholar';

  @override
  String get adminControlAvgRating => 'O‘rtacha baho';

  @override
  String get adminControlComplaintsNew => 'Shikoyatlar (order_feedback)';

  @override
  String get adminControlPraises => 'Maqtovlar';

  @override
  String get adminControlLegacyComplaints => 'Eski shikoyatlar';

  @override
  String get adminControlTopComplaintTargets =>
      'Eng ko‘p shikoyat olgan (kimga)';

  @override
  String get adminControlTopCouriersRating =>
      'Profil bahosi bo‘yicha kuryerlar';

  @override
  String get adminControlUsersByRegion => 'Viloyat bo‘yicha userlar';

  @override
  String get adminControlJobsByRegion => 'Viloyat bo‘yicha buyurtmalar';

  @override
  String get adminControlDistrictsHint => 'Tumanlar (userlar, top)';

  @override
  String get adminControlAuctionsTouched => 'Auksion ishtiroki';

  @override
  String get adminControlAvgBids => 'O‘rtacha takliflar soni';

  @override
  String get adminControlAvgDiscount => 'O‘rtacha narx pasayishi (birlik)';

  @override
  String get adminControlCompletedDeliveries => 'Yakunlangan yetkazishlar';

  @override
  String get adminControlActiveTracking => 'Faol kuzatuv (tracking)';

  @override
  String get adminOrderFilterComplaint => 'Shikoyatli';

  @override
  String get adminOrderFilterAuctionBids => 'Taklif bo‘lgan';

  @override
  String get adminOrderFilterRecent30 => 'So‘nggi 30 kun';

  @override
  String get adminUserFilterLowRating => 'Past baho';

  @override
  String get adminUserRegionAll => 'Barcha viloyatlar';

  @override
  String get adminUserRegionFilterHint => 'Viloyat bo‘yicha';

  @override
  String get adminFeedbackSectionTitle => 'Feedback va shikoyatlar';

  @override
  String get adminFeedbackTabComplaints => 'Shikoyatlar';

  @override
  String get adminFeedbackTabAll => 'Hammasi';

  @override
  String get adminFeedbackLowRating => 'Past baho (≤2)';

  @override
  String get adminFeedbackSenderToCourier => 'Yuboruvchi → kuryer';

  @override
  String get adminComplaintReview => 'Ko‘rib chiqish';

  @override
  String get adminComplaintStatusLabel => 'Holat';

  @override
  String get adminComplaintNoteLabel => 'Admin izohi';

  @override
  String get adminComplaintSave => 'Saqlash';

  @override
  String get adminComplaintStatusNew => 'Yangi';

  @override
  String get adminComplaintStatusReviewed => 'Ko‘rib chiqilgan';

  @override
  String get adminComplaintStatusResolved => 'Hal qilingan';

  @override
  String get adminRegionsSectionTitle => 'Hudud tahlili';

  @override
  String get adminRegionsCompleted => 'Yakunlangan buyurtmalar';

  @override
  String get adminRegionsOrders => 'Buyurtmalar';

  @override
  String get adminRegionsSenders => 'Yuboruvchilar';

  @override
  String get adminRegionsCouriers => 'Kuryerlar';

  @override
  String get adminRegionsComplaints => 'Shikoyatlar (user)';

  @override
  String get adminRegionsSelectRegion => 'Viloyat tafsiloti';

  @override
  String get adminHeaderSettings => 'Sozlamalar';

  @override
  String get adminMetaFrom => 'Kimdan';

  @override
  String get adminMetaTo => 'Kimga';
}
