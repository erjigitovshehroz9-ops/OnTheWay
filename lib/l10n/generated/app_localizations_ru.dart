// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Курьер Аукцион';

  @override
  String get splashTagline => 'Быстро. Современно. Удобная доставка.';

  @override
  String get getStarted => 'Начать';

  @override
  String get language => 'Язык';

  @override
  String get languageUzbek => 'Узбекский';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageEnglish => 'Английский';

  @override
  String get back => 'Назад';

  @override
  String get continueWord => 'Продолжить';

  @override
  String get save => 'Сохранить';

  @override
  String get retry => 'Повторить';

  @override
  String get loading => 'Загрузка…';

  @override
  String get errorGeneric => 'Неизвестная ошибка';

  @override
  String get phoneLoginTitle => 'Ваш номер телефона';

  @override
  String get phoneHint => '+998 __ ___ __ __';

  @override
  String get sendCode => 'Отправить код';

  @override
  String get errorInvalidPhone => 'Введите корректный номер';

  @override
  String get smsTitle => 'SMS подтверждение';

  @override
  String get smsSubtitle => 'Введите код из SMS';

  @override
  String get verify => 'Подтвердить';

  @override
  String get resendCode => 'Отправить код снова';

  @override
  String get errorInvalidCode => 'Неверный или просроченный код';

  @override
  String get offerTitle => 'Публичная оферта';

  @override
  String get offerWelcome => 'Добро пожаловать';

  @override
  String get offerBody =>
      'В этой оферте описаны правила оказания услуг, платежей, ответственности и обработки данных. Без согласия с офертой регистрация невозможна.';

  @override
  String get offerAcceptCheckbox => 'Я согласен с условиями оферты';

  @override
  String get acceptAndContinue => 'Принять и продолжить';

  @override
  String get errorMustAcceptOffer => 'Примите оферту, чтобы продолжить';

  @override
  String get chooseRoleTitle => 'Выберите роль';

  @override
  String get roleSender => 'Отправитель';

  @override
  String get roleSenderDesc => 'Создание заказа и выбор курьера';

  @override
  String get roleCourier => 'Курьер';

  @override
  String get roleCourierDesc => 'Участие в аукционе';

  @override
  String get roleAdmin => 'Администратор';

  @override
  String get roleAdminDesc => 'Управление платформой';

  @override
  String get confirmRole => 'Выбрать';

  @override
  String get senderHomeTitle => 'Главная';

  @override
  String get courierHomeTitle => 'Панель курьера';

  @override
  String get adminHomeTitle => 'Админ-панель';

  @override
  String get whereToHint => 'Куда доставить?';

  @override
  String get createJob => 'Создать заказ';

  @override
  String get nearbyCouriers => 'Курьеры рядом';

  @override
  String get activeJobs => 'Активные заказы';

  @override
  String get demoJobCardTitle => 'Демо заказ';

  @override
  String get contactsHiddenUntilAuction => 'Контакты скрыты до конца аукциона';

  @override
  String get contactsVisibleAfterWinner =>
      'После выбора победителя откроются звонок и чат';

  @override
  String get auctionStatusLive => 'Аукцион идёт';

  @override
  String get auctionStatusEnded => 'Аукцион завершён';

  @override
  String get winnerSelected => 'Победитель выбран';

  @override
  String get topBid => 'Лучшая ставка';

  @override
  String get timeLeft => 'Осталось';

  @override
  String secondsShort(int count) {
    return '$count с';
  }

  @override
  String get placeBid => 'Сделать ставку';

  @override
  String get jobDescriptionLabel => 'Описание';

  @override
  String get jobTitleLabel => 'Название заказа';

  @override
  String get translateDemoHint =>
      'Введите текст — сохранится на 3 языках (демо-перевод)';

  @override
  String get previewForLocale => 'Как видно на текущем языке';

  @override
  String get storedUz => 'Оригинал (узб.)';

  @override
  String get storedRu => 'Сохранено (рус.)';

  @override
  String get storedEn => 'Сохранено (англ.)';

  @override
  String get logout => 'Выйти';

  @override
  String get settings => 'Настройки';

  @override
  String get userDemoName => 'Пользователь';

  @override
  String get selectWinner => 'Выбрать победителя';

  @override
  String get signInRequired => 'Войдите в аккаунт';

  @override
  String get noOpenAuctions => 'Сейчас нет открытых аукционов';

  @override
  String get courierOrdersTabAuction => 'Список';

  @override
  String get courierOrdersSubtabList => 'Заказы';

  @override
  String get courierOrdersTabInProgress => 'В работе';

  @override
  String get courierOrdersTabCompleted => 'Выполнено';

  @override
  String get courierOrdersEmptyInProgress =>
      'Пока нет заказов в работе. После аукциона, если вы победите, они появятся здесь.';

  @override
  String get courierOrdersEmptyCompleted => 'Пока нет выполненных заказов.';

  @override
  String get adminDashboard => 'Admin panel';

  @override
  String get adminStatistics => 'Statistika';

  @override
  String get adminUsers => 'Foydalanuvchilar';

  @override
  String get adminLiveMap => 'Jonli xarita';

  @override
  String get adminSectionOverview => 'Ключевые показатели';

  @override
  String get adminSectionOrders => 'Заказы и аукционы';

  @override
  String get adminSectionUsersSecurity => 'Пользователи и безопасность';

  @override
  String get adminSectionShortcuts => 'Быстрые действия';

  @override
  String get adminChartOrderStatus => 'Структура заказов';

  @override
  String get adminNavStatsSubtitle => 'Аналитика по регионам';

  @override
  String get adminNavUsersSubtitle => 'Роли и блокировки';

  @override
  String get adminNavMapSubtitle => 'Позиции курьеров';

  @override
  String adminMapMarkerCount(int count) {
    return '$count точек курьеров';
  }

  @override
  String get adminMapEmptyNoJobsTitle => 'Нет живого трекинга';

  @override
  String get adminMapEmptyNoJobsBody =>
      'Сейчас нет заказов с активным отслеживанием. Обновите позже.';

  @override
  String get adminMapEmptyNoGpsTitle => 'Нет координат';

  @override
  String get adminMapEmptyNoGpsBody =>
      'Заказы есть, но координаты курьеров ещё не поступили.';

  @override
  String get chartLegendCompleted => 'Завершено';

  @override
  String get chartLegendActive => 'В работе';

  @override
  String get chartLegendCancelled => 'Отменено';

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
  String get courierMapNoOrdersInDistrict => 'В этом районе заказов нет';

  @override
  String get courierMapOpenDetail => 'Подробнее';

  @override
  String courierMapCoordsShort(String lat, String lng) {
    return '$lat, $lng';
  }

  @override
  String get courierPanelBannerTitle => 'ПАНЕЛЬ КУРЬЕРА';

  @override
  String courierGreeting(String name) {
    return 'Здравствуйте, $name!';
  }

  @override
  String get courierNavHome => 'Главная';

  @override
  String get courierNavOrders => 'Заказы';

  @override
  String get courierNavMaps => 'Карты';

  @override
  String get courierNavAccount => 'Профиль';

  @override
  String get senderBottomNavSwitchRole => 'Смена роли';

  @override
  String get bottomNavWallet => 'Счёт';

  @override
  String get courierCardCreated => 'Создано';

  @override
  String get courierStatusWaiting => 'В процессе';

  @override
  String get courierDeliveredBadge => 'Доставлено';

  @override
  String get courierCardIdLabel => 'ID';

  @override
  String get jobDetails => 'Buyurtma tafsilotlari';

  @override
  String get jobDetailProductInfoTitle => 'Сведения о товаре';

  @override
  String get jobDetailNoProductImage => 'Фото товара не загружено';

  @override
  String get jobDetailVolumeShort => 'Объём';

  @override
  String get pickupLocation => 'Qayerdan olinadi';

  @override
  String get dropoffLocation => 'Qayerga yetkaziladi';

  @override
  String get mapDualFlowCardTitle => 'Укажите адреса на карте';

  @override
  String get mapPickerNextDropoff => 'Далее: адрес доставки';

  @override
  String get mapPickerConfirmBoth => 'Подтвердить адреса';

  @override
  String get recipientNameLabel => 'Qabul qiluvchi ismi';

  @override
  String get recipientPhoneLabel => 'Qabul qiluvchi telefoni';

  @override
  String get recipientPhoneHelper =>
      '+998 отображается автоматически. Введите ещё 9 цифр — иначе курьер может не дозвониться.';

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
  String get auctionLiveScreenTitle => 'Аукцион в прямом эфире';

  @override
  String get auctionOngoingLabel => 'Аукцион продолжается';

  @override
  String get auctionWaitingStartLabel => 'Ожидание начала аукциона';

  @override
  String auctionTimeLeftLine(String time) {
    return 'Осталось $time';
  }

  @override
  String auctionCouriersParticipatingCount(int count) {
    return 'Участвует курьеров: $count';
  }

  @override
  String get auctionOrderDetailsTitle => 'Детали заказа';

  @override
  String get auctionPickupMapLabel => 'Забор:';

  @override
  String get auctionDropoffMapLabel => 'Доставка:';

  @override
  String auctionRouteDistance(String km) {
    return '$km км';
  }

  @override
  String get auctionSenderTrustTitle => 'Об отправителе';

  @override
  String get auctionCourierRatingsTitle => 'Рейтинг курьеров';

  @override
  String get auctionAgreePriceCta => 'Согласен с ценой →';

  @override
  String get auctionWatchCta => 'Наблюдать';

  @override
  String get auctionParticipateOutlined => 'Участвовать';

  @override
  String get auctionYouAreLeading => 'Вы лидируете';

  @override
  String auctionReviewsCount(int count) {
    return '$count отзывов';
  }

  @override
  String get auctionStartPriceLabel => 'Стартовая цена';

  @override
  String get auctionHozirgiTaklif => 'Текущая ставка';

  @override
  String get auctionYourPriceLabel => 'Ваша принятая цена';

  @override
  String get auctionNextOfferLabel =>
      'Следующее предложение («Согласен с ценой»)';

  @override
  String get auctionEndedYouWonBody =>
      'Поздравляем! Заказ закреплён за вами. Продолжайте в списке заказов.';

  @override
  String get auctionEndedOtherWinnerBody =>
      'Аукцион завершился в пользу другого курьера.';

  @override
  String get auctionEndedNoWinnerBody =>
      'Время вышло. Заказ снова доступен для аукциона.';

  @override
  String get auctionEndedGenericBody => 'Аукцион завершён.';

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
  String get needsColdChain => 'Холодная цепь';

  @override
  String get completedJobsLabel => 'Bajarilgan ishlar';

  @override
  String get markPickedUp => 'Qabul qildim';

  @override
  String get markDelivered => 'Yetkazib berdim';

  @override
  String get orderContactSectionTitle => 'Контакты';

  @override
  String get orderWinnerOutcomeTitle => 'Победитель определён';

  @override
  String get orderFinalPriceLabel => 'Итоговая цена';

  @override
  String get orderWinnerSelectedAtLabel => 'Время выбора';

  @override
  String get orderAuctionStepsCountLabel => 'Шаги аукциона';

  @override
  String get orderAddressesHiddenForNonWinner =>
      'Адреса видны только победившему курьеру.';

  @override
  String courierRatingStarsLabel(String value) {
    return 'Рейтинг: $value';
  }

  @override
  String get deliveryNoteOptional => 'Izoh (ixtiyoriy)';

  @override
  String get submitFeedback => 'Оставить отзыв';

  @override
  String get feedbackComplaintTitle => 'Опишите жалобу';

  @override
  String get feedbackComplaintHint => 'Кратко опишите, что произошло…';

  @override
  String get feedbackPraiseTitle => 'Благодарность';

  @override
  String get feedbackPraiseStarsHint => 'Оцените от 1 до 5 звёзд';

  @override
  String get feedbackPraiseEmojiHint => 'Или выберите смайл:';

  @override
  String get feedbackSend => 'Отправить';

  @override
  String get feedbackSentThanks => 'Спасибо, отзыв сохранён';

  @override
  String get feedbackAlreadySubmitted =>
      'Вы уже оставили отзыв по этому заказу (один раз: жалоба или благодарность).';

  @override
  String get rateCourierCta => 'Оценить курьера';

  @override
  String get rateSenderCta => 'Оценить отправителя';

  @override
  String get orderFeedbackSheetTitleCourier => 'Оцените курьера';

  @override
  String get orderFeedbackSheetTitleSender => 'Оцените отправителя';

  @override
  String get orderFeedbackStarsLabel => 'Оценка (1–5 звёзд, обязательно)';

  @override
  String get orderFeedbackTypeNeutral => 'Только оценка';

  @override
  String get orderFeedbackTypeComplaint => 'Жалоба';

  @override
  String get orderFeedbackTypePraise => 'Благодарность';

  @override
  String get orderFeedbackCommentOptional => 'Комментарий (необязательно)';

  @override
  String get orderFeedbackYourSummaryTitle => 'Ваш отзыв';

  @override
  String orderFeedbackSummaryRating(int stars) {
    return '$stars / 5';
  }

  @override
  String get orderFeedbackSummaryTypeRating => 'Оценка';

  @override
  String get orderFeedbackSummaryTypeComplaint => 'Жалоба';

  @override
  String get orderFeedbackSummaryTypePraise => 'Благодарность';

  @override
  String orderFeedbackSummaryCategory(String name) {
    return 'Категория: $name';
  }

  @override
  String get fbCatComplaintLate => 'Опоздал';

  @override
  String get fbCatComplaintRude => 'Плохое общение';

  @override
  String get fbCatComplaintCareless => 'Небрежное отношение к заказу';

  @override
  String get fbCatComplaintAddress => 'Проблема с адресом';

  @override
  String get fbCatOther => 'Другое';

  @override
  String get fbCatPraiseFast => 'Быстрая доставка';

  @override
  String get fbCatPraisePolite => 'Вежливый';

  @override
  String get fbCatPraiseCareful => 'Аккуратный';

  @override
  String get fbCatPraiseReliable => 'Чёткий и надёжный';

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
  String get fieldOptionalHint => 'Необязательно';

  @override
  String get createOrderTitle => 'Buyurtma yaratish';

  @override
  String get createJobConfirmTitle => 'Подтверждение заказа';

  @override
  String get createJobSenderAddressLabel => 'Адрес отправителя';

  @override
  String get createJobReceiverAddressLabel => 'Адрес получателя';

  @override
  String get createJobDeliveryTimeSection => 'Время доставки';

  @override
  String get createJobPickupSlotLabel => 'Забор';

  @override
  String get createJobDeliverySlotLabel => 'Доставка';

  @override
  String get createJobAboutPackage => 'О посылке';

  @override
  String get createJobPackageTypeShort => 'Тип';

  @override
  String get createJobPackageSizeShort => 'Размер';

  @override
  String get createJobPackageWeightShort => 'Вес';

  @override
  String get createJobPackageDescShort => 'Описание';

  @override
  String get createJobEstimatedPrice => 'Ориентировочная цена';

  @override
  String get createJobFinalPriceDisclaimer =>
      'Итоговая цена определяется на аукционе';

  @override
  String get createJobAuctionHint =>
      'После размещения заказа курьеры примут участие в аукционе';

  @override
  String get createJobPlaceOrder => 'Разместить заказ';

  @override
  String get productNameLabel => 'Mahsulot nomi';

  @override
  String get productTypeLabel => 'Mahsulot turi';

  @override
  String get weightKg => 'Вес (кг)';

  @override
  String get volumeCategoryLabel => 'Категория объёма';

  @override
  String get orderCommentsLabel => 'Дополнительный комментарий';

  @override
  String get orderCommentsHint => 'Дополнительная информация о заказе';

  @override
  String orderCommentsCharCounter(int current, int max) {
    return '$current/$max';
  }

  @override
  String get orderSuitableTransportTitle => 'Подходящий транспорт';

  @override
  String get orderRequiredTransportTitle => 'Тип транспорта';

  @override
  String get validationSelectSuitableTransport =>
      'Выберите хотя бы один транспорт (можно несколько)';

  @override
  String get validationSelectOneTransport =>
      'Выберите один тип транспорта для заказа';

  @override
  String get transportLabelPiyoda => 'Пешком';

  @override
  String get transportLabelVelosiped => 'Велосипед / скутер';

  @override
  String get transportLabelMoto => 'Мото';

  @override
  String get transportLabelAvto => 'Авто';

  @override
  String get transportLabelTruck => 'Крупный грузовик';

  @override
  String get courierTransportEmptyTitle => 'Тип транспорта не выбран';

  @override
  String get courierTransportEmptySubtitle =>
      'Чтобы видеть подходящие заказы, укажите в профиле хотя бы один тип транспорта.';

  @override
  String get courierTransportChooseAction => 'Выбрать транспорт';

  @override
  String get courierProfileTransportLabel => 'Типы транспорта';

  @override
  String get courierProfileTransportChange => 'Изменить';

  @override
  String get courierTransportSheetTitleProfile => 'Обновите типы транспорта';

  @override
  String get courierTransportSheetTitleSetup => 'Выберите тип транспорта';

  @override
  String get courierFilterAllDistricts => 'Все районы';

  @override
  String get jobTransportMismatchMessage =>
      'Этот заказ не подходит под ваши типы транспорта.';

  @override
  String get volumeCatVerySmall => 'Очень маленький';

  @override
  String get volumeCatSmall => 'Маленький';

  @override
  String get volumeCatMedium => 'Средний';

  @override
  String get volumeCatLarge => 'Большой';

  @override
  String get volumeCatVeryLarge => 'Крупный+';

  @override
  String get dimensionsMmLabel => 'Размеры (мм)';

  @override
  String get dimensionsMmHint => '1000x500x200';

  @override
  String get validationDimensionsFormat =>
      'Формат: три числа, например 1000x500x200';

  @override
  String get validationDimensionsRequired =>
      'Для этого объёма размер обязателен';

  @override
  String get startingPrice => 'Начальная цена';

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
  String get deliveryUntilHint => 'Например: до 21:00';

  @override
  String get mapAddressCity => 'Город';

  @override
  String get mapAddressDistrict => 'Район';

  @override
  String get mapAddressRegion => 'Область';

  @override
  String get mapDistanceLabel => 'Расстояние';

  @override
  String get mapDistanceApproximate => 'Приблизительно (по прямой)';

  @override
  String get mapPickupMarkerHint => 'Точка забора';

  @override
  String get jobRouteMapTitle => 'Карта маршрута';

  @override
  String get jobMapNoCoordinates => 'Нет координат для карты.';

  @override
  String get jobMapMarkerA => 'A';

  @override
  String get jobMapMarkerB => 'B';

  @override
  String get jobMapOneCoordinateOnly =>
      'Есть координаты только одного адреса — расстояние не показано.';

  @override
  String get courierJobMapToPickupTitle => 'Маршрут к точке забора (A)';

  @override
  String get courierJobMapToDropoffTitle => 'Маршрут к точке доставки (B)';

  @override
  String get courierJobMapGpsUnavailable =>
      'Не удалось определить местоположение. Нажмите «Моё местоположение».';

  @override
  String get jobDimensionsMm => 'Размеры (мм)';

  @override
  String get productPhoto => 'Фото товара';

  @override
  String get validationProductPhotoRequired => 'Добавьте фото товара';

  @override
  String get takePhoto => 'Rasmga olish';

  @override
  String get chooseFile => 'Fayldan tanlash';

  @override
  String get searchJobsHint => 'Buyurtmalarni qidirish';

  @override
  String get profileSection => 'Профиль';

  @override
  String get senderProfileNameLabel => 'Имя';

  @override
  String get senderProfilePhoneLabel => 'Телефон';

  @override
  String get senderProfileRoleLabel => 'Роль';

  @override
  String get senderProfileLanguageLabel => 'Язык';

  @override
  String get senderProfileStatusLabel => 'Статус';

  @override
  String get senderProfileNameEmpty => 'Имя не указано';

  @override
  String get senderProfilePhoneEmpty => 'Нет номера телефона';

  @override
  String get senderProfileStatusActive => 'Активен';

  @override
  String get senderProfileStatusBlocked => 'Заблокирован';

  @override
  String get senderProfilePhoneVerified => 'Телефон подтверждён';

  @override
  String get senderProfilePhoneNotVerified => 'Телефон не подтверждён';

  @override
  String get senderProfileVerificationLabel => 'Статус телефона';

  @override
  String get senderWalletTitle => 'Кошелёк';

  @override
  String get senderWalletSubtitle => 'Скоро будет доступно.';

  @override
  String get senderProfileEditSection => 'Редактирование';

  @override
  String get senderProfileFullNameLabel => 'Полное имя';

  @override
  String get senderProfileFullNameHint => 'Имя и фамилия';

  @override
  String get senderProfileSecondaryPhoneLabel => 'Доп. телефон';

  @override
  String get senderProfileSecondaryPhoneHint => '+998 __ ___ __ __';

  @override
  String get senderProfileChangePhoto => 'Сменить фото';

  @override
  String get senderProfileRemovePhoto => 'Удалить фото';

  @override
  String get senderProfileEditTooltip => 'Изменить';

  @override
  String get senderProfileSave => 'Сохранить';

  @override
  String get senderProfileSaving => 'Сохранение…';

  @override
  String get senderProfileSaveSuccess => 'Профиль обновлён';

  @override
  String get senderProfileInvalidSecondaryPhone =>
      'Введите корректный номер Узбекистана';

  @override
  String get senderProfileSecondarySameAsPrimary =>
      'Укажите номер, отличный от основного';

  @override
  String get senderProfilePrimaryPhoneReadOnly => 'Основной телефон (аккаунт)';

  @override
  String get openAdminPanel => 'Admin panelga o‘tish';

  @override
  String get statusPosted => 'Yaratildi';

  @override
  String get senderOrderStatusPosted => 'Ожидание';

  @override
  String get senderOrderPriceLabel => 'Цена';

  @override
  String get senderOrderMinStavkaSuffix => '(мин. ставка)';

  @override
  String get senderOrderContactsHint =>
      'После выбора курьера появятся контактные данные';

  @override
  String get statusAssigned => 'Biriktirildi';

  @override
  String get statusPickedUp => 'Olib ketildi';

  @override
  String get statusDelivered => 'Yetkazildi';

  @override
  String get senderNotificationsTooltip => 'Уведомления';

  @override
  String get senderNotificationsEmpty => 'Новых уведомлений пока нет';

  @override
  String get senderSnackbarAuctionStarted =>
      'Аукцион начался — заказ в разделе «В процессе»';

  @override
  String get senderSnackbarAuctionEndedAssigned =>
      'Аукцион завершён — назначен курьер';

  @override
  String get senderSnackbarAuctionEndedReopened =>
      'Аукцион завершён — победителя нет, заказ снова в ожидании';

  @override
  String get senderSnackbarAuctionEndedCancelled =>
      'Аукцион завершён — заказ отменён';

  @override
  String get senderNotifCourierNearPickup1Km =>
      'Курьер приближается к точке забора (~1 км)';

  @override
  String get senderNotifCourierNearDropoff5Km =>
      'Курьер приближается к точке доставки (~5 км)';

  @override
  String get senderNotifCourierNearDropoff2Km =>
      'Курьер приближается к точке доставки (~2 км)';

  @override
  String senderNotifAuctionStartedBody(String product) {
    return '«$product». Курьеры подают предложения по этому заказу. Заказ перенесён в раздел «В процессе».';
  }

  @override
  String senderNotifAuctionEndedAssignedBody(
      String product, String courier, String amount) {
    return '«$product». Победившей признана ставка курьера «$courier»: $amount. Полные сведения — в деталях заказа.';
  }

  @override
  String senderNotifAuctionReopenedBody(String product) {
    return '«$product». Аукцион завершён — победителя нет, заказ снова в ожидании.';
  }

  @override
  String senderNotifAuctionCancelledBody(String product) {
    return '«$product». Аукцион завершён — заказ отменён.';
  }

  @override
  String get senderNotifOpenJobDetails => 'Детали заказа';

  @override
  String get senderNotifUnknownCourier => 'Курьер';

  @override
  String get liveTrackingBadge => 'Онлайн‑слежение';

  @override
  String get courierTrackingSendingLabel => 'Передаётся местоположение';

  @override
  String get courierTrackingLocationPermissionDenied =>
      'Нет доступа к геолокации или GPS выключен. Разрешите доступ в настройках — нужно для онлайн‑слежения.';

  @override
  String get trackingLastUpdatedPrefix => 'Последнее обновление:';

  @override
  String get senderTrackingWaitingCourierLocation =>
      'Местоположение курьера пока не передаётся. Карта появится, когда курьер откроет заказ в приложении и выйдет в путь.';

  @override
  String get senderTrackingNoCoordinatesForLeg =>
      'Для маршрута нет координат адреса.';

  @override
  String get senderTrackingTapToEnlarge => 'Нажмите на карту, чтобы увеличить';

  @override
  String get senderTrackingFullscreenTitlePickup => 'Курьер — точка забора';

  @override
  String get senderTrackingFullscreenTitleDropoff => 'Курьер — доставка';

  @override
  String senderTrackingDistanceMeters(int m) {
    return '$m м';
  }

  @override
  String senderTrackingDistanceKm(String km) {
    return '$km км';
  }

  @override
  String senderTrackingEtaApproxMinutes(int minutes) {
    return 'Около $minutes мин';
  }

  @override
  String senderTrackingEtaHoursMinutes(int hours, int minutes) {
    return 'Около $hours ч $minutes мин';
  }

  @override
  String get senderNotificationsSheetTitle => 'Уведомления';

  @override
  String get senderNotificationsLoadError => 'Не удалось загрузить уведомления';

  @override
  String get senderNotificationsTapToRead => 'Нажмите для подробностей';

  @override
  String get senderNotificationsTimeJustNow => 'Только что';

  @override
  String senderNotificationsTimeMinutesAgo(int count) {
    return '$count мин. назад';
  }

  @override
  String senderNotificationsTimeHoursAgo(int count) {
    return '$count ч назад';
  }

  @override
  String get createJobMenuMore => 'Настройки';

  @override
  String get createJobMenuChangeTheme => 'Сменить тему';

  @override
  String get createJobMenuContactUs => 'Связаться с нами';

  @override
  String get createJobThemeTitle => 'Выберите тему';

  @override
  String get createJobThemeLight => 'Светлая';

  @override
  String get createJobThemeDark => 'Тёмная';

  @override
  String get createJobThemeSystem => 'Как в системе';

  @override
  String get createJobContactTitle => 'Связаться с нами';

  @override
  String get createJobContactPickType => 'Выберите тип обращения';

  @override
  String get createJobContactComplaint => 'Жалоба';

  @override
  String get createJobContactPraise => 'Благодарность';

  @override
  String get createJobContactApplication => 'Заявление';

  @override
  String get createJobContactSuggestion => 'Предложение';

  @override
  String get createJobContactMessageLabel => 'Ваше обращение';

  @override
  String get createJobContactMessageHint => 'Введите текст обращения';

  @override
  String get createJobContactSubmit => 'Отправить';

  @override
  String get createJobContactSuccess => 'Сообщение отправлено';

  @override
  String get createJobValidationContactType => 'Выберите тип обращения';

  @override
  String get createJobValidationContactMessage => 'Введите текст';

  @override
  String get createJobValidationMessageTooShort =>
      'Слишком короткий текст (мин. 15 символов)';

  @override
  String get adminContactRequests => 'Обращения';

  @override
  String get adminContactRequestsSubtitle => 'Сообщения пользователей';

  @override
  String get adminContactRequestDetail => 'Детали обращения';

  @override
  String get supportRequestStatusNew => 'Новое';

  @override
  String get supportRequestStatusRead => 'Прочитано';

  @override
  String get supportRequestStatusResolved => 'Решено';

  @override
  String get supportRequestFullMessage => 'Полный текст';

  @override
  String get supportRequestMarkRead => 'Пометить прочитанным';

  @override
  String get supportRequestMarkResolved => 'Пометить решённым';

  @override
  String get adminPanelSubtitle => 'Панель управления курьерами';

  @override
  String get adminBottomNavDashboard => 'Обзор';

  @override
  String get adminBottomNavUsers => 'Пользователи';

  @override
  String get adminBottomNavOrders => 'Заказы';

  @override
  String get adminBottomNavAuctions => 'Аукционы';

  @override
  String get adminBottomNavReports => 'Отчёты';

  @override
  String get adminBottomNavFinance => 'Финансы';

  @override
  String get adminPanelNavSettings => 'Настройки';

  @override
  String get adminQuickActionsTitle => 'Быстрые действия';

  @override
  String get adminActionViewList => 'Просмотр';

  @override
  String get adminActionEditRole => 'Роль';

  @override
  String get adminActionBan => 'Блок';

  @override
  String get adminActionUnblock => 'Разблок.';

  @override
  String get adminActionVerify => 'Проверка';

  @override
  String get adminFinanceSectionTitle => 'Финансы и транзакции';

  @override
  String get adminFinanceTotalRevenue => 'Всего поступлений';

  @override
  String get adminFinanceCommissions => 'Комиссии';

  @override
  String get adminFinanceSuccessfulPayments => 'Успешные оплаты';

  @override
  String get adminFinanceCourierPayouts => 'Выплаты курьерам';

  @override
  String get adminFinanceDemoHint => 'Примерные данные';

  @override
  String get adminReportsSectionTitle => 'Отчёты и жалобы';

  @override
  String get adminOrderFilterAll => 'Все';

  @override
  String get adminOrderFilterPending => 'Ожидание';

  @override
  String get adminOrderFilterAuction => 'Аукцион';

  @override
  String get adminOrderFilterInDelivery => 'Доставка';

  @override
  String get adminOrderFilterCompleted => 'Завершено';

  @override
  String get adminUserFilterAll => 'Все';

  @override
  String get adminUserFilterSenders => 'Отправители';

  @override
  String get adminUserFilterCouriers => 'Курьеры';

  @override
  String get adminUserFilterBlocked => 'Заблок.';

  @override
  String get adminUserFilterNew => 'Новые';

  @override
  String get adminUserFilterComplaints => 'Жалобы';

  @override
  String get adminUserFilterAdmins => 'Админы';

  @override
  String get adminSettingsSectionShortcuts => 'Система и разделы';

  @override
  String get adminOpenStatistics => 'Статистика';

  @override
  String get adminOpenMap => 'Карта';

  @override
  String get adminOpenContactRequests => 'Обращения';

  @override
  String get adminOpenFullSettings => 'Настройки приложения';

  @override
  String get adminComingSoonNotifications => 'Уведомления скоро';

  @override
  String get adminSearchHint => 'Поиск';

  @override
  String get adminLanguageTileTitle => 'Язык приложения';

  @override
  String get adminOrdersSectionTitle => 'Заказы';

  @override
  String get adminAuctionsSectionTitle => 'Аукционы';

  @override
  String get adminNoJobsInList => 'Список пуст';

  @override
  String get adminRegionPerformanceTitle => 'Эффективность по регионам';

  @override
  String get adminRegionPerformanceHint => 'Пример — позже реальные данные';

  @override
  String get adminAnalyticsSectionTitle => 'Аналитика и графики';

  @override
  String get adminChartDeliveryGrowth => 'Динамика доставок';

  @override
  String get adminChartUsersVsCourier => 'Пользователи и курьеры';

  @override
  String get adminChartCompletionDonut => 'Доля завершённых заказов';

  @override
  String get adminDesignSampleChartNote =>
      'Графики привязаны к статистике (образец)';

  @override
  String get adminStatusActive => 'Активен';

  @override
  String get adminStatusBlockedShort => 'Заблокирован';

  @override
  String get adminUserManagementTitle => 'Управление пользователями';

  @override
  String adminJobOrderNumber(String id) {
    return '№ $id';
  }

  @override
  String get adminPickupInfo => 'Забор';

  @override
  String get adminDropoffInfo => 'Доставка';

  @override
  String get adminReportSenderCourierComplaints =>
      'Жалобы отправителей / курьеров';

  @override
  String get adminReportFlaggedOrders => 'Помеченные заказы';

  @override
  String get adminReportUrgentHighlights => 'Срочные сообщения';

  @override
  String get adminActionQuickResolve => 'Быстрое решение';

  @override
  String get adminActionReject => 'Отклонить';

  @override
  String get adminActionInvestigate => 'Разобраться';

  @override
  String get adminFinancePendingPayouts => 'Ожидающие выплаты';

  @override
  String get adminDistrictActivityTitle => 'Активность по районам';

  @override
  String get adminOrderHotspotsTitle => 'Точки заказов';

  @override
  String get adminCourierAvailabilityTitle => 'Загрузка курьеров (пример)';

  @override
  String get adminGridAddAdmin => 'Добавить админа';

  @override
  String get adminGridManageRoles => 'Роли';

  @override
  String get adminGridViewReports => 'Отчёты';

  @override
  String get adminGridBlockUser => 'Блокировка';

  @override
  String get adminGridApproveCourier => 'Курьер ОК';

  @override
  String get adminGridMonitorAuctions => 'Аукционы';

  @override
  String get adminGridSystemSettings => 'Система';

  @override
  String get adminBottomNavFeedback => 'Отзывы';

  @override
  String get adminBottomNavRegions => 'Регионы';

  @override
  String get adminControlOverviewTitle => 'Оперативный обзор';

  @override
  String get adminControlFeedbackTitle => 'Отзывы и качество';

  @override
  String get adminControlGeoTitle => 'География';

  @override
  String get adminControlAuctionTitle => 'Аукцион и доставка';

  @override
  String get adminControlUsersTotal => 'Всего пользователей';

  @override
  String get adminControlSenders => 'Отправители';

  @override
  String get adminControlCouriers => 'Курьеры';

  @override
  String get adminControlOrdersTotal => 'Всего заказов';

  @override
  String get adminControlPosted => 'Опубликовано';

  @override
  String get adminControlAuctionLive => 'Аукцион';

  @override
  String get adminControlAssigned => 'Назначено';

  @override
  String get adminControlPickedUp => 'Забрано';

  @override
  String get adminControlDelivered => 'Доставлено';

  @override
  String get adminControlCompleted => 'Завершено';

  @override
  String get adminControlCancelled => 'Отменено';

  @override
  String get adminControlBlocked => 'Заблокировано';

  @override
  String get adminControlRatingsTotal => 'Всего оценок';

  @override
  String get adminControlAvgRating => 'Средняя оценка';

  @override
  String get adminControlComplaintsNew => 'Жалобы (order_feedback)';

  @override
  String get adminControlPraises => 'Похвалы';

  @override
  String get adminControlLegacyComplaints => 'Старые жалобы';

  @override
  String get adminControlTopComplaintTargets => 'Чаще всего жалуются (кому)';

  @override
  String get adminControlTopCouriersRating => 'Курьеры по рейтингу профиля';

  @override
  String get adminControlUsersByRegion => 'Пользователи по региону';

  @override
  String get adminControlJobsByRegion => 'Заказы по региону';

  @override
  String get adminControlDistrictsHint => 'Районы (пользователи, топ)';

  @override
  String get adminControlAuctionsTouched => 'Аукционы с активностью';

  @override
  String get adminControlAvgBids => 'Среднее число ставок';

  @override
  String get adminControlAvgDiscount => 'Среднее снижение цены (ед.)';

  @override
  String get adminControlCompletedDeliveries => 'Завершённые доставки';

  @override
  String get adminControlActiveTracking => 'Активное отслеживание';

  @override
  String get adminOrderFilterComplaint => 'С жалобой';

  @override
  String get adminOrderFilterAuctionBids => 'Со ставками';

  @override
  String get adminOrderFilterRecent30 => '30 дней';

  @override
  String get adminUserFilterLowRating => 'Низкий рейтинг';

  @override
  String get adminUserRegionAll => 'Все регионы';

  @override
  String get adminUserRegionFilterHint => 'Фильтр по региону';

  @override
  String get adminFeedbackSectionTitle => 'Отзывы и жалобы';

  @override
  String get adminFeedbackTabComplaints => 'Жалобы';

  @override
  String get adminFeedbackTabAll => 'Все';

  @override
  String get adminFeedbackLowRating => 'Низкая оценка (≤2)';

  @override
  String get adminFeedbackSenderToCourier => 'Отправитель → курьер';

  @override
  String get adminComplaintReview => 'Разбор';

  @override
  String get adminComplaintStatusLabel => 'Статус';

  @override
  String get adminComplaintNoteLabel => 'Заметка админа';

  @override
  String get adminComplaintSave => 'Сохранить';

  @override
  String get adminComplaintStatusNew => 'Новая';

  @override
  String get adminComplaintStatusReviewed => 'Просмотрена';

  @override
  String get adminComplaintStatusResolved => 'Решена';

  @override
  String get adminRegionsSectionTitle => 'Аналитика по регионам';

  @override
  String get adminRegionsCompleted => 'Завершённые заказы';

  @override
  String get adminRegionsOrders => 'Заказы';

  @override
  String get adminRegionsSenders => 'Отправители';

  @override
  String get adminRegionsCouriers => 'Курьеры';

  @override
  String get adminRegionsComplaints => 'Жалобы (пользователь)';

  @override
  String get adminRegionsSelectRegion => 'Детали региона';

  @override
  String get adminHeaderSettings => 'Настройки';

  @override
  String get adminMetaFrom => 'От';

  @override
  String get adminMetaTo => 'Кому';
}
