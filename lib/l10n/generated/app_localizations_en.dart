// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Courier Auction';

  @override
  String get splashTagline => 'Fast. Modern. Smooth delivery.';

  @override
  String get getStarted => 'Get started';

  @override
  String get language => 'Language';

  @override
  String get languageUzbek => 'Uzbek';

  @override
  String get languageRussian => 'Russian';

  @override
  String get languageEnglish => 'English';

  @override
  String get back => 'Back';

  @override
  String get continueWord => 'Continue';

  @override
  String get save => 'Save';

  @override
  String get retry => 'Retry';

  @override
  String get loading => 'Loading…';

  @override
  String get errorGeneric => 'Something went wrong';

  @override
  String get phoneLoginTitle => 'Your phone number';

  @override
  String get phoneHint => '+998 __ ___ __ __';

  @override
  String get sendCode => 'Send code';

  @override
  String get errorInvalidPhone => 'Enter a valid phone number';

  @override
  String get smsTitle => 'SMS verification';

  @override
  String get smsSubtitle => 'Enter the code we sent you';

  @override
  String get verify => 'Verify';

  @override
  String get resendCode => 'Resend code';

  @override
  String get errorInvalidCode => 'Invalid or expired code';

  @override
  String get offerTitle => 'Public offer';

  @override
  String get offerWelcome => 'Welcome';

  @override
  String get offerBody =>
      'This agreement covers service terms, payments, liability, and data handling. You cannot continue registration without accepting the offer.';

  @override
  String get offerAcceptCheckbox => 'I accept the offer terms';

  @override
  String get acceptAndContinue => 'Accept and continue';

  @override
  String get errorMustAcceptOffer => 'Accept the offer to continue';

  @override
  String get chooseRoleTitle => 'Choose your role';

  @override
  String get roleSender => 'Sender';

  @override
  String get roleSenderDesc => 'Create jobs and pick a courier';

  @override
  String get roleCourier => 'Courier';

  @override
  String get roleCourierDesc => 'Join auctions';

  @override
  String get roleAdmin => 'Administrator';

  @override
  String get roleAdminDesc => 'Manage the platform';

  @override
  String get confirmRole => 'Confirm';

  @override
  String get senderHomeTitle => 'Home';

  @override
  String get courierHomeTitle => 'Courier hub';

  @override
  String get adminHomeTitle => 'Admin';

  @override
  String get whereToHint => 'Where to deliver?';

  @override
  String get createJob => 'Create job';

  @override
  String get nearbyCouriers => 'Nearby couriers';

  @override
  String get activeJobs => 'Active jobs';

  @override
  String get demoJobCardTitle => 'Demo job';

  @override
  String get contactsHiddenUntilAuction =>
      'Contact details stay hidden until the auction ends';

  @override
  String get contactsVisibleAfterWinner =>
      'After a winner is chosen, call and chat unlock';

  @override
  String get auctionStatusLive => 'Live auction';

  @override
  String get auctionStatusEnded => 'Auction ended';

  @override
  String get winnerSelected => 'Winner selected';

  @override
  String get topBid => 'Top bid';

  @override
  String get timeLeft => 'Time left';

  @override
  String secondsShort(int count) {
    return '${count}s';
  }

  @override
  String get placeBid => 'Place bid';

  @override
  String get jobDescriptionLabel => 'Description';

  @override
  String get jobTitleLabel => 'Job title';

  @override
  String get translateDemoHint =>
      'Type text — stored in 3 languages (demo translation)';

  @override
  String get previewForLocale => 'Preview for current language';

  @override
  String get storedUz => 'Original (Uzbek)';

  @override
  String get storedRu => 'Stored Russian';

  @override
  String get storedEn => 'Stored English';

  @override
  String get logout => 'Log out';

  @override
  String get settings => 'Settings';

  @override
  String get userDemoName => 'User';

  @override
  String get selectWinner => 'Select winner';

  @override
  String get signInRequired => 'Please sign in';

  @override
  String get noOpenAuctions => 'No open auctions right now';

  @override
  String get courierOrdersTabAuction => 'List';

  @override
  String get courierOrdersSubtabList => 'Orders';

  @override
  String get courierOrdersTabInProgress => 'In progress';

  @override
  String get courierOrdersTabCompleted => 'Completed';

  @override
  String get courierOrdersEmptyInProgress =>
      'No active deliveries yet. After an auction ends, if you win, your jobs appear here.';

  @override
  String get courierOrdersEmptyCompleted => 'No completed jobs yet.';

  @override
  String get adminDashboard => 'Admin panel';

  @override
  String get adminStatistics => 'Statistika';

  @override
  String get adminUsers => 'Foydalanuvchilar';

  @override
  String get adminLiveMap => 'Jonli xarita';

  @override
  String get adminSectionOverview => 'Key metrics';

  @override
  String get adminSectionOrders => 'Orders & auctions';

  @override
  String get adminSectionUsersSecurity => 'Users & safety';

  @override
  String get adminSectionShortcuts => 'Quick actions';

  @override
  String get adminChartOrderStatus => 'Order mix';

  @override
  String get adminNavStatsSubtitle => 'Regional breakdown';

  @override
  String get adminNavUsersSubtitle => 'Roles & blocking';

  @override
  String get adminNavMapSubtitle => 'Live courier positions';

  @override
  String adminMapMarkerCount(int count) {
    return '$count courier points';
  }

  @override
  String get adminMapEmptyNoJobsTitle => 'No live tracking';

  @override
  String get adminMapEmptyNoJobsBody =>
      'There are no active tracking jobs right now. Pull to refresh or try again shortly.';

  @override
  String get adminMapEmptyNoGpsTitle => 'No positions yet';

  @override
  String get adminMapEmptyNoGpsBody =>
      'Jobs exist, but courier GPS positions have not been received yet.';

  @override
  String get chartLegendCompleted => 'Completed';

  @override
  String get chartLegendActive => 'In progress';

  @override
  String get chartLegendCancelled => 'Cancelled';

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
  String get courierMapNoOrdersInDistrict => 'No orders in this area';

  @override
  String get courierMapOpenDetail => 'Details';

  @override
  String courierMapCoordsShort(String lat, String lng) {
    return '$lat, $lng';
  }

  @override
  String get courierPanelBannerTitle => 'COURIER PANEL';

  @override
  String courierGreeting(String name) {
    return 'Hello, $name!';
  }

  @override
  String get courierNavHome => 'Home';

  @override
  String get courierNavOrders => 'Orders';

  @override
  String get courierNavMaps => 'Maps';

  @override
  String get courierNavAccount => 'My account';

  @override
  String get senderBottomNavSwitchRole => 'Switch role';

  @override
  String get bottomNavWallet => 'Account';

  @override
  String get courierCardCreated => 'Created';

  @override
  String get courierStatusWaiting => 'In progress';

  @override
  String get courierDeliveredBadge => 'Delivered';

  @override
  String get courierCardIdLabel => 'ID';

  @override
  String get jobDetails => 'Buyurtma tafsilotlari';

  @override
  String get jobDetailProductInfoTitle => 'Product information';

  @override
  String get jobDetailNoProductImage => 'No product image uploaded';

  @override
  String get jobDetailVolumeShort => 'Volume';

  @override
  String get pickupLocation => 'Qayerdan olinadi';

  @override
  String get dropoffLocation => 'Qayerga yetkaziladi';

  @override
  String get mapDualFlowCardTitle => 'Set addresses on the map';

  @override
  String get mapPickerNextDropoff => 'Next: delivery location';

  @override
  String get mapPickerConfirmBoth => 'Confirm addresses';

  @override
  String get recipientNameLabel => 'Qabul qiluvchi ismi';

  @override
  String get recipientPhoneLabel => 'Qabul qiluvchi telefoni';

  @override
  String get recipientPhoneHelper =>
      '+998 is fixed. Enter exactly 9 digits after it so the courier can call the recipient.';

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
  String get auctionLiveScreenTitle => 'Live auction';

  @override
  String get auctionOngoingLabel => 'Auction in progress';

  @override
  String get auctionWaitingStartLabel => 'Waiting for the auction to start';

  @override
  String auctionTimeLeftLine(String time) {
    return '$time left';
  }

  @override
  String auctionCouriersParticipatingCount(int count) {
    return '$count couriers participating';
  }

  @override
  String get auctionOrderDetailsTitle => 'Order details';

  @override
  String get auctionPickupMapLabel => 'Pickup:';

  @override
  String get auctionDropoffMapLabel => 'Drop-off:';

  @override
  String auctionRouteDistance(String km) {
    return '$km km';
  }

  @override
  String get auctionSenderTrustTitle => 'About the sender';

  @override
  String get auctionCourierRatingsTitle => 'Courier ratings';

  @override
  String get auctionAgreePriceCta => 'Accept price →';

  @override
  String get auctionWatchCta => 'Watch';

  @override
  String get auctionParticipateOutlined => 'Participate';

  @override
  String get auctionYouAreLeading => 'You are leading';

  @override
  String auctionReviewsCount(int count) {
    return '$count reviews';
  }

  @override
  String get auctionStartPriceLabel => 'Starting price';

  @override
  String get auctionHozirgiTaklif => 'Current bid';

  @override
  String get auctionYourPriceLabel => 'Your accepted price';

  @override
  String get auctionNextOfferLabel => 'Next offer (Accept price)';

  @override
  String get auctionEndedYouWonBody =>
      'Congratulations! The order is assigned to you. Continue from your orders list.';

  @override
  String get auctionEndedOtherWinnerBody =>
      'The auction ended in another courier’s favor.';

  @override
  String get auctionEndedNoWinnerBody =>
      'Time ran out. The order is open for auction again.';

  @override
  String get auctionEndedGenericBody => 'The auction has ended.';

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
  String get needsColdChain => 'Cold storage';

  @override
  String get completedJobsLabel => 'Bajarilgan ishlar';

  @override
  String get markPickedUp => 'Qabul qildim';

  @override
  String get markDelivered => 'Yetkazib berdim';

  @override
  String get orderContactSectionTitle => 'Contact details';

  @override
  String get orderWinnerOutcomeTitle => 'Winner confirmed';

  @override
  String get orderFinalPriceLabel => 'Final price';

  @override
  String get orderWinnerSelectedAtLabel => 'Selected at';

  @override
  String get orderAuctionStepsCountLabel => 'Auction steps';

  @override
  String get orderAddressesHiddenForNonWinner =>
      'Addresses are visible only to the winning courier.';

  @override
  String courierRatingStarsLabel(String value) {
    return 'Rating: $value';
  }

  @override
  String get deliveryNoteOptional => 'Izoh (ixtiyoriy)';

  @override
  String get submitFeedback => 'Leave feedback';

  @override
  String get feedbackComplaintTitle => 'Describe your complaint';

  @override
  String get feedbackComplaintHint => 'Briefly explain what went wrong…';

  @override
  String get feedbackPraiseTitle => 'Give praise';

  @override
  String get feedbackPraiseStarsHint => 'Rate with 1–5 stars';

  @override
  String get feedbackPraiseEmojiHint => 'Or pick a quick emoji:';

  @override
  String get feedbackSend => 'Send';

  @override
  String get feedbackSentThanks => 'Thanks — your feedback was saved';

  @override
  String get feedbackAlreadySubmitted =>
      'You already left feedback for this order (one complaint or praise per order).';

  @override
  String get rateCourierCta => 'Rate courier';

  @override
  String get rateSenderCta => 'Rate sender';

  @override
  String get orderFeedbackSheetTitleCourier => 'Rate the courier';

  @override
  String get orderFeedbackSheetTitleSender => 'Rate the sender';

  @override
  String get orderFeedbackStarsLabel => 'Rating (1–5 stars, required)';

  @override
  String get orderFeedbackTypeNeutral => 'Rating only';

  @override
  String get orderFeedbackTypeComplaint => 'Complaint';

  @override
  String get orderFeedbackTypePraise => 'Praise';

  @override
  String get orderFeedbackCommentOptional => 'Comment (optional)';

  @override
  String get orderFeedbackYourSummaryTitle => 'Your feedback';

  @override
  String orderFeedbackSummaryRating(int stars) {
    return '$stars / 5';
  }

  @override
  String get orderFeedbackSummaryTypeRating => 'Rating';

  @override
  String get orderFeedbackSummaryTypeComplaint => 'Complaint';

  @override
  String get orderFeedbackSummaryTypePraise => 'Praise';

  @override
  String orderFeedbackSummaryCategory(String name) {
    return 'Category: $name';
  }

  @override
  String get fbCatComplaintLate => 'Late delivery';

  @override
  String get fbCatComplaintRude => 'Poor attitude';

  @override
  String get fbCatComplaintCareless => 'Careless with the order';

  @override
  String get fbCatComplaintAddress => 'Address issue';

  @override
  String get fbCatOther => 'Other';

  @override
  String get fbCatPraiseFast => 'Fast delivery';

  @override
  String get fbCatPraisePolite => 'Polite';

  @override
  String get fbCatPraiseCareful => 'Careful';

  @override
  String get fbCatPraiseReliable => 'Clear and reliable';

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
  String get fieldOptionalHint => 'Optional';

  @override
  String get createOrderTitle => 'Buyurtma yaratish';

  @override
  String get createJobConfirmTitle => 'Confirm order';

  @override
  String get createJobSenderAddressLabel => 'Sender address';

  @override
  String get createJobReceiverAddressLabel => 'Recipient address';

  @override
  String get createJobDeliveryTimeSection => 'Delivery time';

  @override
  String get createJobPickupSlotLabel => 'Pickup';

  @override
  String get createJobDeliverySlotLabel => 'Delivery';

  @override
  String get createJobAboutPackage => 'About the package';

  @override
  String get createJobPackageTypeShort => 'Type';

  @override
  String get createJobPackageSizeShort => 'Size';

  @override
  String get createJobPackageWeightShort => 'Weight';

  @override
  String get createJobPackageDescShort => 'Description';

  @override
  String get createJobEstimatedPrice => 'Estimated price';

  @override
  String get createJobFinalPriceDisclaimer =>
      'Final price is set during the auction';

  @override
  String get createJobAuctionHint =>
      'After you submit, couriers will bid in the auction';

  @override
  String get createJobPlaceOrder => 'Place order';

  @override
  String get productNameLabel => 'Mahsulot nomi';

  @override
  String get productTypeLabel => 'Mahsulot turi';

  @override
  String get weightKg => 'Weight (kg)';

  @override
  String get volumeCategoryLabel => 'Volume category';

  @override
  String get orderCommentsLabel => 'Additional notes';

  @override
  String get orderCommentsHint => 'Add any extra details about this order';

  @override
  String orderCommentsCharCounter(int current, int max) {
    return '$current/$max';
  }

  @override
  String get orderSuitableTransportTitle => 'Suitable vehicle';

  @override
  String get orderRequiredTransportTitle => 'Vehicle type';

  @override
  String get validationSelectSuitableTransport =>
      'Select at least one vehicle (you can select several)';

  @override
  String get validationSelectOneTransport =>
      'Select one vehicle type for this order';

  @override
  String get transportLabelPiyoda => 'On foot';

  @override
  String get transportLabelVelosiped => 'Bicycle / scooter';

  @override
  String get transportLabelMoto => 'Motorcycle';

  @override
  String get transportLabelAvto => 'Car';

  @override
  String get transportLabelTruck => 'Large truck';

  @override
  String get courierTransportEmptyTitle => 'No vehicle type selected';

  @override
  String get courierTransportEmptySubtitle =>
      'Choose at least one vehicle type in your profile to see matching orders.';

  @override
  String get courierTransportChooseAction => 'Choose vehicles';

  @override
  String get courierProfileTransportLabel => 'Vehicle types';

  @override
  String get courierProfileTransportChange => 'Change';

  @override
  String get courierTransportSheetTitleProfile => 'Update your vehicle types';

  @override
  String get courierTransportSheetTitleSetup => 'Choose your vehicle types';

  @override
  String get courierFilterAllDistricts => 'All districts';

  @override
  String get jobTransportMismatchMessage =>
      'This order does not match your vehicle types.';

  @override
  String get volumeCatVerySmall => 'Very small';

  @override
  String get volumeCatSmall => 'Small';

  @override
  String get volumeCatMedium => 'Medium';

  @override
  String get volumeCatLarge => 'Large';

  @override
  String get volumeCatVeryLarge => 'Large+';

  @override
  String get dimensionsMmLabel => 'Dimensions (mm)';

  @override
  String get dimensionsMmHint => '1000x500x200';

  @override
  String get validationDimensionsFormat =>
      'Format: three numbers, e.g. 1000x500x200';

  @override
  String get validationDimensionsRequired =>
      'Dimensions are required for this volume';

  @override
  String get startingPrice => 'Starting price';

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
  String get deliveryUntilHint => 'e.g. until 21:00';

  @override
  String get mapAddressCity => 'City';

  @override
  String get mapAddressDistrict => 'District';

  @override
  String get mapAddressRegion => 'Region';

  @override
  String get mapDistanceLabel => 'Distance';

  @override
  String get mapDistanceApproximate => 'Approximate (straight line)';

  @override
  String get mapPickupMarkerHint => 'Pickup point';

  @override
  String get jobRouteMapTitle => 'Route map';

  @override
  String get jobMapNoCoordinates => 'No map coordinates for these addresses.';

  @override
  String get jobMapMarkerA => 'A';

  @override
  String get jobMapMarkerB => 'B';

  @override
  String get jobMapOneCoordinateOnly =>
      'Only one address has coordinates — distance is not shown.';

  @override
  String get courierJobMapToPickupTitle => 'Route to pickup (A)';

  @override
  String get courierJobMapToDropoffTitle => 'Route to delivery (B)';

  @override
  String get courierJobMapGpsUnavailable =>
      'Could not get your location. Use the My location button.';

  @override
  String get jobDimensionsMm => 'Dimensions (mm)';

  @override
  String get productPhoto => 'Product photo';

  @override
  String get validationProductPhotoRequired => 'Add a product photo';

  @override
  String get takePhoto => 'Rasmga olish';

  @override
  String get chooseFile => 'Fayldan tanlash';

  @override
  String get searchJobsHint => 'Buyurtmalarni qidirish';

  @override
  String get profileSection => 'Profile';

  @override
  String get senderProfileNameLabel => 'Name';

  @override
  String get senderProfilePhoneLabel => 'Phone';

  @override
  String get senderProfileRoleLabel => 'Role';

  @override
  String get senderProfileLanguageLabel => 'Language';

  @override
  String get senderProfileStatusLabel => 'Status';

  @override
  String get senderProfileNameEmpty => 'No name added';

  @override
  String get senderProfilePhoneEmpty => 'No phone number';

  @override
  String get senderProfileStatusActive => 'Active';

  @override
  String get senderProfileStatusBlocked => 'Blocked';

  @override
  String get senderProfilePhoneVerified => 'Phone verified';

  @override
  String get senderProfilePhoneNotVerified => 'Phone not verified';

  @override
  String get senderProfileVerificationLabel => 'Phone status';

  @override
  String get senderWalletTitle => 'Wallet';

  @override
  String get senderWalletSubtitle => 'Coming soon.';

  @override
  String get senderProfileEditSection => 'Edit details';

  @override
  String get senderProfileFullNameLabel => 'Full name';

  @override
  String get senderProfileFullNameHint => 'Enter your first and last name';

  @override
  String get senderProfileSecondaryPhoneLabel => 'Additional phone';

  @override
  String get senderProfileSecondaryPhoneHint => '+998 __ ___ __ __';

  @override
  String get senderProfileChangePhoto => 'Change photo';

  @override
  String get senderProfileRemovePhoto => 'Remove photo';

  @override
  String get senderProfileEditTooltip => 'Edit';

  @override
  String get senderProfileSave => 'Save';

  @override
  String get senderProfileSaving => 'Saving…';

  @override
  String get senderProfileSaveSuccess => 'Profile updated';

  @override
  String get senderProfileInvalidSecondaryPhone =>
      'Enter a valid Uzbekistan phone number';

  @override
  String get senderProfileSecondarySameAsPrimary =>
      'Use a number different from your primary phone';

  @override
  String get senderProfilePrimaryPhoneReadOnly => 'Primary phone (account)';

  @override
  String get openAdminPanel => 'Admin panelga o‘tish';

  @override
  String get statusPosted => 'Yaratildi';

  @override
  String get senderOrderStatusPosted => 'Pending';

  @override
  String get senderOrderPriceLabel => 'Price';

  @override
  String get senderOrderMinStavkaSuffix => '(min. bid)';

  @override
  String get senderOrderContactsHint =>
      'After a courier is chosen, contact details will appear';

  @override
  String get statusAssigned => 'Biriktirildi';

  @override
  String get statusPickedUp => 'Olib ketildi';

  @override
  String get statusDelivered => 'Yetkazildi';

  @override
  String get senderNotificationsTooltip => 'Notifications';

  @override
  String get senderNotificationsEmpty => 'No new notifications yet';

  @override
  String get senderSnackbarAuctionStarted =>
      'Auction started — see your order under In progress';

  @override
  String get senderSnackbarAuctionEndedAssigned =>
      'Auction ended — a courier was assigned';

  @override
  String get senderSnackbarAuctionEndedReopened =>
      'Auction ended — no winner; order is waiting again';

  @override
  String get senderSnackbarAuctionEndedCancelled =>
      'Auction ended — order was cancelled';

  @override
  String get senderNotifCourierNearPickup1Km =>
      'Courier approaching pickup (~1 km)';

  @override
  String get senderNotifCourierNearDropoff5Km =>
      'Courier approaching delivery (~5 km)';

  @override
  String get senderNotifCourierNearDropoff2Km =>
      'Courier approaching delivery (~2 km)';

  @override
  String senderNotifAuctionStartedBody(String product) {
    return '«$product». Couriers are submitting offers for this order. Your order has been moved to the In progress section.';
  }

  @override
  String senderNotifAuctionEndedAssignedBody(
      String product, String courier, String amount) {
    return '«$product». The winning bid from courier «$courier» is $amount. Open Order details for full information.';
  }

  @override
  String senderNotifAuctionReopenedBody(String product) {
    return '«$product». Auction ended — no winner; the order is waiting again.';
  }

  @override
  String senderNotifAuctionCancelledBody(String product) {
    return '«$product». Auction ended — the order was cancelled.';
  }

  @override
  String get senderNotifOpenJobDetails => 'Order details';

  @override
  String get senderNotifUnknownCourier => 'Courier';

  @override
  String get liveTrackingBadge => 'Live tracking';

  @override
  String get courierTrackingSendingLabel => 'Live location is being shared';

  @override
  String get courierTrackingLocationPermissionDenied =>
      'Location permission is off or GPS is disabled. Allow location access in settings — required for live tracking.';

  @override
  String get trackingLastUpdatedPrefix => 'Last update:';

  @override
  String get senderTrackingWaitingCourierLocation =>
      'Courier location not shared yet. The map appears once the courier opens this order in the app and starts moving.';

  @override
  String get senderTrackingNoCoordinatesForLeg =>
      'No map coordinates for this route.';

  @override
  String get senderTrackingTapToEnlarge => 'Tap the map to enlarge';

  @override
  String get senderTrackingFullscreenTitlePickup => 'Courier — pickup';

  @override
  String get senderTrackingFullscreenTitleDropoff => 'Courier — delivery';

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
    return 'About $minutes min';
  }

  @override
  String senderTrackingEtaHoursMinutes(int hours, int minutes) {
    return 'About $hours h $minutes min';
  }

  @override
  String get senderNotificationsSheetTitle => 'Notifications';

  @override
  String get senderNotificationsLoadError => 'Could not load notifications';

  @override
  String get senderNotificationsTapToRead => 'Tap for details';

  @override
  String get senderNotificationsTimeJustNow => 'Just now';

  @override
  String senderNotificationsTimeMinutesAgo(int count) {
    return '$count min ago';
  }

  @override
  String senderNotificationsTimeHoursAgo(int count) {
    return '$count h ago';
  }

  @override
  String get createJobMenuMore => 'Settings';

  @override
  String get createJobMenuChangeTheme => 'Change appearance';

  @override
  String get createJobMenuContactUs => 'Contact us';

  @override
  String get createJobThemeTitle => 'Choose appearance';

  @override
  String get createJobThemeLight => 'Light';

  @override
  String get createJobThemeDark => 'Dark';

  @override
  String get createJobThemeSystem => 'System default';

  @override
  String get createJobContactTitle => 'Contact us';

  @override
  String get createJobContactPickType => 'Choose request type';

  @override
  String get createJobContactComplaint => 'Complaint';

  @override
  String get createJobContactPraise => 'Praise';

  @override
  String get createJobContactApplication => 'Request';

  @override
  String get createJobContactSuggestion => 'Suggestion';

  @override
  String get createJobContactMessageLabel => 'Your message';

  @override
  String get createJobContactMessageHint => 'Enter your message';

  @override
  String get createJobContactSubmit => 'Send';

  @override
  String get createJobContactSuccess => 'Your message was sent';

  @override
  String get createJobValidationContactType => 'Select a request type';

  @override
  String get createJobValidationContactMessage => 'Enter your message';

  @override
  String get createJobValidationMessageTooShort =>
      'Message is too short (min 15 characters)';

  @override
  String get adminContactRequests => 'Support requests';

  @override
  String get adminContactRequestsSubtitle => 'User messages';

  @override
  String get adminContactRequestDetail => 'Request details';

  @override
  String get supportRequestStatusNew => 'New';

  @override
  String get supportRequestStatusRead => 'Read';

  @override
  String get supportRequestStatusResolved => 'Resolved';

  @override
  String get supportRequestFullMessage => 'Full message';

  @override
  String get supportRequestMarkRead => 'Mark as read';

  @override
  String get supportRequestMarkResolved => 'Mark resolved';

  @override
  String get adminPanelSubtitle => 'Courier management dashboard';

  @override
  String get adminBottomNavDashboard => 'Dashboard';

  @override
  String get adminBottomNavUsers => 'Users';

  @override
  String get adminBottomNavOrders => 'Orders';

  @override
  String get adminBottomNavAuctions => 'Auctions';

  @override
  String get adminBottomNavReports => 'Reports';

  @override
  String get adminBottomNavFinance => 'Finance';

  @override
  String get adminPanelNavSettings => 'Settings';

  @override
  String get adminQuickActionsTitle => 'Quick actions';

  @override
  String get adminActionViewList => 'View';

  @override
  String get adminActionEditRole => 'Edit role';

  @override
  String get adminActionBan => 'Ban';

  @override
  String get adminActionUnblock => 'Unblock';

  @override
  String get adminActionVerify => 'Verify';

  @override
  String get adminFinanceSectionTitle => 'Finance & transactions';

  @override
  String get adminFinanceTotalRevenue => 'Total revenue';

  @override
  String get adminFinanceCommissions => 'Commissions earned';

  @override
  String get adminFinanceSuccessfulPayments => 'Successful payments';

  @override
  String get adminFinanceCourierPayouts => 'Courier payouts';

  @override
  String get adminFinanceDemoHint => 'Sample figures';

  @override
  String get adminReportsSectionTitle => 'Reports & complaints';

  @override
  String get adminOrderFilterAll => 'All';

  @override
  String get adminOrderFilterPending => 'Pending';

  @override
  String get adminOrderFilterAuction => 'Auction';

  @override
  String get adminOrderFilterInDelivery => 'In delivery';

  @override
  String get adminOrderFilterCompleted => 'Completed';

  @override
  String get adminUserFilterAll => 'All';

  @override
  String get adminUserFilterSenders => 'Senders';

  @override
  String get adminUserFilterCouriers => 'Couriers';

  @override
  String get adminUserFilterBlocked => 'Blocked';

  @override
  String get adminUserFilterNew => 'New';

  @override
  String get adminUserFilterComplaints => 'Complaints';

  @override
  String get adminUserFilterAdmins => 'Admins';

  @override
  String get adminSettingsSectionShortcuts => 'System & navigation';

  @override
  String get adminOpenStatistics => 'Open statistics';

  @override
  String get adminOpenMap => 'Live map';

  @override
  String get adminOpenContactRequests => 'Open support requests';

  @override
  String get adminOpenFullSettings => 'App settings';

  @override
  String get adminComingSoonNotifications => 'Notifications coming soon';

  @override
  String get adminSearchHint => 'Search';

  @override
  String get adminLanguageTileTitle => 'App language';

  @override
  String get adminOrdersSectionTitle => 'Orders';

  @override
  String get adminAuctionsSectionTitle => 'Auctions';

  @override
  String get adminNoJobsInList => 'No items';

  @override
  String get adminRegionPerformanceTitle => 'Regional performance';

  @override
  String get adminRegionPerformanceHint => 'Sample grid — live data later';

  @override
  String get adminAnalyticsSectionTitle => 'Analytics & charts';

  @override
  String get adminChartDeliveryGrowth => 'Delivery activity';

  @override
  String get adminChartUsersVsCourier => 'Users vs couriers';

  @override
  String get adminChartCompletionDonut => 'Completed orders share';

  @override
  String get adminDesignSampleChartNote =>
      'Charts scaled to your stats (sample curve)';

  @override
  String get adminStatusActive => 'Active';

  @override
  String get adminStatusBlockedShort => 'Blocked';

  @override
  String get adminUserManagementTitle => 'User management';

  @override
  String adminJobOrderNumber(String id) {
    return '# $id';
  }

  @override
  String get adminPickupInfo => 'Pickup';

  @override
  String get adminDropoffInfo => 'Drop-off';

  @override
  String get adminReportSenderCourierComplaints =>
      'Sender / courier complaints';

  @override
  String get adminReportFlaggedOrders => 'Flagged orders';

  @override
  String get adminReportUrgentHighlights => 'Urgent highlights';

  @override
  String get adminActionQuickResolve => 'Quick resolve';

  @override
  String get adminActionReject => 'Reject';

  @override
  String get adminActionInvestigate => 'Investigate';

  @override
  String get adminFinancePendingPayouts => 'Pending payouts';

  @override
  String get adminDistrictActivityTitle => 'District activity';

  @override
  String get adminOrderHotspotsTitle => 'Order hotspots';

  @override
  String get adminCourierAvailabilityTitle => 'Courier load (sample)';

  @override
  String get adminGridAddAdmin => 'Add admin';

  @override
  String get adminGridManageRoles => 'Manage roles';

  @override
  String get adminGridViewReports => 'Reports';

  @override
  String get adminGridBlockUser => 'Block user';

  @override
  String get adminGridApproveCourier => 'Approve courier';

  @override
  String get adminGridMonitorAuctions => 'Auctions';

  @override
  String get adminGridSystemSettings => 'System settings';

  @override
  String get adminBottomNavFeedback => 'Feedback';

  @override
  String get adminBottomNavRegions => 'Regions';

  @override
  String get adminControlOverviewTitle => 'Operations overview';

  @override
  String get adminControlFeedbackTitle => 'Feedback & quality';

  @override
  String get adminControlGeoTitle => 'Geography';

  @override
  String get adminControlAuctionTitle => 'Auctions & delivery';

  @override
  String get adminControlUsersTotal => 'Total users';

  @override
  String get adminControlSenders => 'Senders';

  @override
  String get adminControlCouriers => 'Couriers';

  @override
  String get adminControlOrdersTotal => 'Total orders';

  @override
  String get adminControlPosted => 'Posted';

  @override
  String get adminControlAuctionLive => 'Auction live';

  @override
  String get adminControlAssigned => 'Assigned';

  @override
  String get adminControlPickedUp => 'Picked up';

  @override
  String get adminControlDelivered => 'Delivered';

  @override
  String get adminControlCompleted => 'Completed';

  @override
  String get adminControlCancelled => 'Cancelled';

  @override
  String get adminControlBlocked => 'Blocked users';

  @override
  String get adminControlRatingsTotal => 'Total ratings';

  @override
  String get adminControlAvgRating => 'Average rating';

  @override
  String get adminControlComplaintsNew => 'Complaints (order_feedback)';

  @override
  String get adminControlPraises => 'Praises';

  @override
  String get adminControlLegacyComplaints => 'Legacy complaints';

  @override
  String get adminControlTopComplaintTargets => 'Most complained (to user)';

  @override
  String get adminControlTopCouriersRating => 'Top couriers by profile rating';

  @override
  String get adminControlUsersByRegion => 'Users by region';

  @override
  String get adminControlJobsByRegion => 'Orders by region';

  @override
  String get adminControlDistrictsHint => 'Districts (users, top)';

  @override
  String get adminControlAuctionsTouched => 'Auctions touched';

  @override
  String get adminControlAvgBids => 'Avg bid count';

  @override
  String get adminControlAvgDiscount => 'Avg price drop (currency units)';

  @override
  String get adminControlCompletedDeliveries => 'Completed deliveries';

  @override
  String get adminControlActiveTracking => 'Active delivery tracking';

  @override
  String get adminOrderFilterComplaint => 'Complaint';

  @override
  String get adminOrderFilterAuctionBids => 'Had bids';

  @override
  String get adminOrderFilterRecent30 => 'Last 30 days';

  @override
  String get adminUserFilterLowRating => 'Low rating';

  @override
  String get adminUserRegionAll => 'All regions';

  @override
  String get adminUserRegionFilterHint => 'Region filter';

  @override
  String get adminFeedbackSectionTitle => 'Feedback & complaints';

  @override
  String get adminFeedbackTabComplaints => 'Complaints';

  @override
  String get adminFeedbackTabAll => 'All';

  @override
  String get adminFeedbackLowRating => 'Low rating (≤2)';

  @override
  String get adminFeedbackSenderToCourier => 'Sender → courier';

  @override
  String get adminComplaintReview => 'Review';

  @override
  String get adminComplaintStatusLabel => 'Status';

  @override
  String get adminComplaintNoteLabel => 'Admin note';

  @override
  String get adminComplaintSave => 'Save';

  @override
  String get adminComplaintStatusNew => 'New';

  @override
  String get adminComplaintStatusReviewed => 'Reviewed';

  @override
  String get adminComplaintStatusResolved => 'Resolved';

  @override
  String get adminRegionsSectionTitle => 'Regional analytics';

  @override
  String get adminRegionsCompleted => 'Completed orders';

  @override
  String get adminRegionsOrders => 'Orders';

  @override
  String get adminRegionsSenders => 'Senders';

  @override
  String get adminRegionsCouriers => 'Couriers';

  @override
  String get adminRegionsComplaints => 'Complaints (user)';

  @override
  String get adminRegionsSelectRegion => 'Region detail';

  @override
  String get adminHeaderSettings => 'Settings';

  @override
  String get adminMetaFrom => 'From';

  @override
  String get adminMetaTo => 'To';
}
