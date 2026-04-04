import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/geo/pickup_admin_code_resolver.dart';
import '../../../core/input/dimensions_mm_input_formatter.dart';
import '../../../core/input/uz_phone_mask_formatter.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/phone_validator.dart';
import '../../../core/utils/route_distance_format.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../models/delivery_speed.dart';
import '../../../models/job_transport_type.dart';
import '../../../models/payment_type.dart';
import '../../../models/volume_category.dart';
import '../../../repositories/job_repository.dart';
import '../../../shared/widgets/order_transport_selector.dart';
import '../../map/presentation/map_location_page.dart';
import '../application/sender_jobs_provider.dart';
import 'order_image_path_exists_stub.dart'
    if (dart.library.io) 'order_image_path_exists_io.dart' as order_path;
import 'order_local_image_save_stub.dart'
    if (dart.library.io) 'order_local_image_save_io.dart' as order_local_image_save;
import 'widgets/create_job_confirm_panel.dart';
import 'widgets/create_job_image_preview.dart';
import 'widgets/create_job_wizard_ui.dart';
import 'widgets/required_field_label.dart';

/// Xarita tanlanmaguncha ko‘rsatiladigan qisqa izoh (keyinroq l10n ga ko‘chirilishi mumkin).
const _kMapPickHint = 'Xaritadan tanlang';

const int _kOrderCommentsMaxLength = 1000;

class CreateJobWizardPage extends ConsumerStatefulWidget {
  const CreateJobWizardPage({super.key});

  @override
  ConsumerState<CreateJobWizardPage> createState() =>
      _CreateJobWizardPageState();
}

class _CreateJobWizardPageState extends ConsumerState<CreateJobWizardPage> {
  final _page = PageController();
  int _step = 0;

  final _formProduct = GlobalKey<FormState>();
  final _formRecipient = GlobalKey<FormState>();

  final _scrollProduct = ScrollController();
  final _scrollAddresses = ScrollController();
  final _scrollRecipient = ScrollController();
  final _scrollReview = ScrollController();

  final _kProductName = GlobalKey();
  final _kProductType = GlobalKey();
  final _kWeight = GlobalKey();
  final _kVolumeCategory = GlobalKey();
  final _kTransport = GlobalKey();
  final _kDimensions = GlobalKey();
  final _kStartingPrice = GlobalKey();
  final _kDescription = GlobalKey();
  final _kOrderComments = GlobalKey();
  final _kDeliveryWindow = GlobalKey();
  final _kAddressesMap = GlobalKey();
  final _kProductPhoto = GlobalKey();
  final _kRecipientName = GlobalKey();
  final _kRecipientPhone = GlobalKey();

  final _name = TextEditingController();
  final _type = TextEditingController();
  final _weight = TextEditingController();
  final _dimensionsMm = TextEditingController();
  final _recipientName = TextEditingController();
  final _recipientPhone = TextEditingController();
  final _price = TextEditingController();
  final _desc = TextEditingController();
  final _orderComments = TextEditingController();
  final _window = TextEditingController();

  VolumeCategory _volumeCategory = VolumeCategory.medium;
  final Set<String> _selectedTransportKeys = {};

  String _pickupText = '';
  double? _pickupLat;
  double? _pickupLng;
  String? _pickupRegion;
  String? _pickupDistrictOrCity;
  String? _pickupRegionOriginal;
  String? _pickupDistrictOriginal;
  String _dropText = '';
  double? _dropLat;
  double? _dropLng;
  String? _dropoffRegion;
  String? _dropoffDistrictOrCity;
  double? _dropoffRouteKm;

  String _imagePath = '';
  Uint8List? _imageBytes;
  String? _imageContentType;
  DeliverySpeed _speed = DeliverySpeed.fast;
  PaymentType _pay = PaymentType.cash;
  bool _fragile = false;
  bool _cold = false;

  bool _showValidation = false;
  String? _pickupError;
  String? _dropoffError;
  String? _imageError;

  bool _busy = false;

  void _onOrderCommentsChanged() {
    if (kDebugMode) {
      debugPrint(
        '[order-comments] changed length=${_orderComments.text.length}',
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _orderComments.addListener(_onOrderCommentsChanged);
  }

  String _volumeCategoryTitle(AppLocalizations l10n) {
    switch (_volumeCategory) {
      case VolumeCategory.small:
        return l10n.volumeCatSmall;
      case VolumeCategory.medium:
        return l10n.volumeCatMedium;
      case VolumeCategory.large:
        return l10n.volumeCatLarge;
      case VolumeCategory.veryLarge:
        return l10n.volumeCatVeryLarge;
    }
  }

  String? _validateDimensions(AppLocalizations l10n, String? v) {
    if (!_volumeCategory.dimensionsRequired) return null;
    final t = (v ?? '').trim();
    if (t.isEmpty) return l10n.validationDimensionsRequired;
    if (!isValidDimensionsMm(t)) return l10n.validationDimensionsFormat;
    return null;
  }

  @override
  void dispose() {
    _orderComments.removeListener(_onOrderCommentsChanged);
    _page.dispose();
    _scrollProduct.dispose();
    _scrollAddresses.dispose();
    _scrollRecipient.dispose();
    _scrollReview.dispose();
    _name.dispose();
    _type.dispose();
    _weight.dispose();
    _dimensionsMm.dispose();
    _recipientName.dispose();
    _recipientPhone.dispose();
    _price.dispose();
    _desc.dispose();
    _orderComments.dispose();
    _window.dispose();
    super.dispose();
  }

  Future<void> _goToStep(int step) async {
    if (step == _step) return;
    setState(() => _step = step);
    await _page.animateToPage(
      step,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  Future<void> _scrollToKey(GlobalKey key) async {
    final ctx = key.currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      alignment: 0.12,
    );
  }

  String? _requiredText(String v, String message) {
    if (v.trim().isEmpty) return message;
    return null;
  }

  String? _requiredNumber(
    String v,
    String requiredMessage,
    String invalidMessage,
  ) {
    if (v.trim().isEmpty) return requiredMessage;
    final n = double.tryParse(v.replaceAll(',', '.'));
    if (n == null || n <= 0) return invalidMessage;
    return null;
  }

  String _recipientPhoneDigits() =>
      _recipientPhone.text.replaceAll(RegExp(r'\D'), '');

  String? _validateRecipientPhone(AppLocalizations l10n) {
    final d = _recipientPhoneDigits();
    if (d.isEmpty) return l10n.validationRequired;
    if (PhoneValidator.validateUzbekPhone('+998$d') == null) {
      return l10n.errorInvalidPhone;
    }
    return null;
  }

  bool _validCoord(double? lat, double? lng) {
    if (lat == null || lng == null) return false;
    if (lat.isNaN || lng.isNaN) return false;
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }

  Future<bool> _validateCurrentStep(
    AppLocalizations l10n, {
    int? forStep,
    bool scrollOnError = true,
  }) async {
    final step = forStep ?? _step;
    debugPrint('[create_job] validation started: step=$step (view=$_step)');
    setState(() => _showValidation = true);

    if (step == 0) {
      final nameErr = _requiredText(_name.text, l10n.validationRequired);
      if (nameErr != null) {
        _formProduct.currentState?.validate();
        if (scrollOnError) await _scrollToKey(_kProductName);
        return false;
      }
      final typeErr = _requiredText(_type.text, l10n.validationRequired);
      if (typeErr != null) {
        _formProduct.currentState?.validate();
        if (scrollOnError) await _scrollToKey(_kProductType);
        return false;
      }
      final weightErr = _requiredNumber(
        _weight.text,
        l10n.validationRequired,
        l10n.validationRequired,
      );
      if (weightErr != null) {
        _formProduct.currentState?.validate();
        if (scrollOnError) await _scrollToKey(_kWeight);
        return false;
      }
      final dimErr = _validateDimensions(l10n, _dimensionsMm.text);
      if (dimErr != null) {
        _formProduct.currentState?.validate();
        if (scrollOnError) await _scrollToKey(_kDimensions);
        return false;
      }
      if (_selectedTransportKeys.isEmpty) {
        _formProduct.currentState?.validate();
        if (scrollOnError) await _scrollToKey(_kTransport);
        return false;
      }
      final priceErr = _requiredNumber(
        _price.text,
        l10n.validationRequired,
        l10n.validationRequired,
      );
      if (priceErr != null) {
        _formProduct.currentState?.validate();
        if (scrollOnError) await _scrollToKey(_kStartingPrice);
        return false;
      }
      if (_speed == DeliverySpeed.custom && _window.text.trim().isEmpty) {
        _formProduct.currentState?.validate();
        if (scrollOnError) await _scrollToKey(_kDeliveryWindow);
        return false;
      }

      // Tasdiq sahifasidan scrollsiz tekshiruv: PageView boshqa sahifada bo‘lganda
      // Form.currentState / validate() ba’zan false yoki null — qo‘lda tekshiruv yetarli.
      if (!scrollOnError) {
        return true;
      }
      final ok = _formProduct.currentState?.validate() ?? false;
      return ok;
    }

    if (step == 1) {
      String? pickupErr;
      String? dropErr;
      if (_pickupText.trim().isEmpty) {
        pickupErr = l10n.validationRequired;
      } else if (!_validCoord(_pickupLat, _pickupLng)) {
        pickupErr = l10n.validationRequired;
      }
      if (_dropText.trim().isEmpty) {
        dropErr = l10n.validationRequired;
      } else if (!_validCoord(_dropLat, _dropLng)) {
        dropErr = l10n.validationRequired;
      }

      String? imageErr;
      if (pickupErr == null && dropErr == null) {
        final hasBytes = _imageBytes != null && _imageBytes!.isNotEmpty;
        final path = _imagePath.trim();
        final pathOk = path.isNotEmpty && await order_path.orderImagePathExists(path);
        if (!hasBytes && !pathOk) {
          imageErr = l10n.validationProductPhotoRequired;
        }
      }

      setState(() {
        _pickupError = pickupErr;
        _dropoffError = dropErr;
        _imageError = imageErr;
      });

      if (pickupErr != null || dropErr != null) {
        if (scrollOnError) await _scrollToKey(_kAddressesMap);
        return false;
      }
      if (imageErr != null) {
        if (scrollOnError) await _scrollToKey(_kProductPhoto);
        return false;
      }
      return true;
    }

    if (step == 2) {
      final nameErr = _requiredText(_recipientName.text, l10n.validationRequired);
      if (nameErr != null) {
        _formRecipient.currentState?.validate();
        if (scrollOnError) await _scrollToKey(_kRecipientName);
        return false;
      }
      final phoneErr = _validateRecipientPhone(l10n);
      if (phoneErr != null) {
        _formRecipient.currentState?.validate();
        if (scrollOnError) await _scrollToKey(_kRecipientPhone);
        return false;
      }

      if (!scrollOnError) {
        return true;
      }
      final ok = _formRecipient.currentState?.validate() ?? false;
      return ok;
    }

    return true;
  }

  /// Oxirgi bosqichdan yuborish: 0→1→2 ni ekranda aylantirmasdan tekshiradi
  /// (qabul qiluvchi sahifasi «chaqqan» bo‘lib turmasin).
  Future<bool> _validateAllAndFocusFirstInvalid(AppLocalizations l10n) async {
    for (var s = 0; s <= 2; s++) {
      final ok = await _validateCurrentStep(
        l10n,
        forStep: s,
        scrollOnError: false,
      );
      if (!ok) {
        await _goToStep(s);
        await _validateCurrentStep(l10n, forStep: s, scrollOnError: true);
        return false;
      }
    }
    return true;
  }

  Future<void> _pickImage(ImageSource source) async {
    final p = ImagePicker();
    final x = await p.pickImage(source: source, imageQuality: 85);
    if (x == null) return;
    final bytes = await x.readAsBytes();
    final mime = (x.mimeType ?? 'image/jpeg').trim().isEmpty
        ? 'image/jpeg'
        : x.mimeType!.trim();
    if (kDebugMode) {
      debugPrint(
        '[order-image] picked name=${x.name} size=${bytes.length} mime=$mime',
      );
    }
    var path = '';
    if (!kIsWeb) {
      path = await order_local_image_save.savePickedImageBytes(
        bytes,
        suggestedName: x.name,
      );
    }
    setState(() {
      _imageBytes = bytes;
      _imageContentType = mime;
      _imagePath = path;
      _imageError = null;
    });
  }

  String? _mimeFromPickerExtension(String? ext) {
    final e = (ext ?? '').toLowerCase().replaceAll('.', '');
    return switch (e) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'jpg' => 'image/jpeg',
      'jpeg' => 'image/jpeg',
      _ => null,
    };
  }

  Future<void> _pickFile() async {
    final r = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (r == null || r.files.isEmpty) return;
    final f = r.files.single;
    var bytes = f.bytes;
    if (bytes == null || bytes.isEmpty) {
      if (kDebugMode) {
        debugPrint('[order-image] pick file: no in-memory bytes');
      }
      return;
    }
    final mime = _mimeFromPickerExtension(f.extension) ?? 'image/jpeg';
    if (kDebugMode) {
      debugPrint(
        '[order-image] picked file name=${f.name} size=${bytes.length} mime=$mime',
      );
    }
    var path = '';
    if (!kIsWeb) {
      path = await order_local_image_save.savePickedImageBytes(
        bytes,
        suggestedName: f.name,
      );
    }
    setState(() {
      _imageBytes = bytes;
      _imageContentType = mime;
      _imagePath = path;
      _imageError = null;
    });
  }

  String? _districtLine(MapPickerResult r) {
    final parts = [r.city, r.district]
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final user = ref.read(authSessionProvider).valueOrNull;
    if (user == null) return;
    final valid = await _validateAllAndFocusFirstInvalid(l10n);
    if (!valid) return;

    final w = double.parse(_weight.text.replaceAll(',', '.'));
    final pr = double.parse(_price.text.replaceAll(',', '.'));
    final vol = _volumeCategory.representativeLiters;
    final dim = _volumeCategory.dimensionsRequired
        ? _dimensionsMm.text.trim()
        : '';

    final orderCommentsTrimmed = _orderComments.text.trim();
    if (kDebugMode) {
      debugPrint(
        '[order-comments] submit hasComments=${orderCommentsTrimmed.isNotEmpty}',
      );
    }

    setState(() => _busy = true);
    try {
      final repo = await ref.read(jobRepositoryProvider.future);
      final lang =
          ref.read(localeControllerProvider).valueOrNull?.languageCode ??
              'uz';

      final pickupResolveExtra = <String>[
        _pickupText.trim(),
        (_pickupRegionOriginal ?? '').trim(),
        (_pickupDistrictOriginal ?? '').trim(),
      ].where((s) => s.isNotEmpty).join(' ');

      final resolvedPickup = PickupAdminCodeResolver.resolve(
        pickupRegion: _pickupRegion,
        pickupDistrictOrCity: _pickupDistrictOrCity,
        pickupAddressExtra:
            pickupResolveExtra.isEmpty ? null : pickupResolveExtra,
        fallbackRegionCode: user.regionCode,
        fallbackDistrictCode: user.districtCode,
      );

      final payload = CreateJobInput(
        senderId: user.id,
        productName: _name.text.trim(),
        productType: _type.text.trim(),
        weightKg: w,
        volumeL: vol,
        dimensionsMm: dim,
        pickupText: _pickupText.trim(),
        dropoffText: _dropText.trim(),
        pickupRegion: _pickupRegion,
        pickupDistrictOrCity: _pickupDistrictOrCity,
        dropoffRegion: _dropoffRegion,
        dropoffDistrictOrCity: _dropoffDistrictOrCity,
        recipientName: _recipientName.text.trim(),
        recipientPhone: PhoneValidator.validateUzbekPhone(
          '+998${_recipientPhoneDigits()}',
        )!,
        imagePath: _imagePath.trim(),
        imageBytes: _imageBytes,
        imageContentType: _imageContentType,
        deliverySpeed: _speed,
        deliveryWindowStart: null,
        deliveryWindowEnd:
            _speed == DeliverySpeed.custom ? _window.text.trim() : null,
        volumeCategory: _volumeCategory,
        startPrice: pr,
        transportType:
            JobTransportType.encodeTransportTypesToStorage(_selectedTransportKeys),
        description: _desc.text.trim(),
        fragile: _fragile,
        coldChain: _cold,
        paymentType: _pay,
        regionCode: resolvedPickup.regionCode,
        districtCode: resolvedPickup.districtCode,
        pickupLat: _pickupLat,
        pickupLng: _pickupLng,
        dropoffLat: _dropLat,
        dropoffLng: _dropLng,
        pickupRegionOriginal: _pickupRegionOriginal,
        pickupDistrictOriginal: _pickupDistrictOriginal,
        sourceLanguageCode: lang,
        orderComments:
            orderCommentsTrimmed.isEmpty ? null : orderCommentsTrimmed,
      );

      await repo.createPostedJob(payload);
      if (mounted) {
        ref.invalidate(senderJobsProvider(user.id));
        // Kuryer tasmasi yangi buyurtmani darhol ko‘rsin (boshqa qurilmada ham keyingi o‘qishda).
        ref.invalidate(courierJobsProvider);
        context.pop();
      }
    } on OrderImageUploadException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } on OrderRemoteSyncException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorGeneric)),
        );
        debugPrint('[create_job] submit failed: $e');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final light = AppTheme.light();
    final scheme = light.colorScheme;
    final isConfirmStep = _step == 3;

    return Theme(
      data: light.copyWith(
        inputDecorationTheme: wizardInputDecorationTheme(scheme),
      ),
      child: Scaffold(
        backgroundColor: AppColors.lightBackground,
        appBar: isConfirmStep
            ? AppBar(
                automaticallyImplyLeading: false,
                elevation: 0,
                scrolledUnderElevation: 0,
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0F172A),
                surfaceTintColor: Colors.transparent,
                iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
                leadingWidth: 56,
                leading: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _goToStep(2),
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                title: Text(
                  l10n.createJobConfirmTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: Color(0xFF0F172A),
                  ),
                ),
                centerTitle: true,
              )
            : AppBar(
                title: Text(l10n.createOrderTitle),
                elevation: 0,
                scrolledUnderElevation: 0,
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0F172A),
                surfaceTintColor: Colors.transparent,
                iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
              ),
        body: Column(
          children: [
            if (!isConfirmStep) ...[
              Material(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  child: CreateJobWizardStepper(
                    currentStep: _step,
                    labels: [
                      l10n.stepProduct,
                      l10n.stepAddresses,
                      l10n.stepRecipient,
                      l10n.stepReview,
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
            ],
            Expanded(
              child: PageView(
                controller: _page,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _stepProduct(l10n),
                  _stepAddresses(l10n),
                  _stepRecipient(l10n),
                  _stepReview(l10n),
                ],
              ),
            ),
            WizardBottomBar(
              showBack: _step > 0,
              onBack: () => _goToStep(_step - 1),
              backLabel: l10n.back,
              primaryLabel: _step < 3 ? l10n.continueWord : l10n.createJobPlaceOrder,
              onPrimary: _step < 3
                  ? () async {
                      final ok = await _validateCurrentStep(l10n);
                      if (!ok) return;
                      if (!mounted) return;
                      await _goToStep(_step + 1);
                    }
                  : (_busy ? null : _submit),
              primaryLoading: _busy && _step == 3,
              isFinalStep: _step == 3,
              footerHint: isConfirmStep ? l10n.createJobAuctionHint : null,
              primaryBackground: isConfirmStep
                  ? const Color(0xFF1A2B5F)
                  : const Color(0xFF003A90),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepProduct(AppLocalizations l10n) {
    final autovalidate = _showValidation
        ? AutovalidateMode.always
        : AutovalidateMode.disabled;
    final dimRequired = _volumeCategory.dimensionsRequired;

    Widget segmentShell(Widget child) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      );
    }

    return Form(
      key: _formProduct,
      autovalidateMode: autovalidate,
      child: ListView(
        controller: _scrollProduct,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          KeyedSubtree(
            key: _kProductName,
            child: TextFormField(
              controller: _name,
              decoration: InputDecoration(
                label: RequiredFieldLabel(text: l10n.productNameLabel),
              ),
              textInputAction: TextInputAction.next,
              validator: (v) => _requiredText(v ?? '', l10n.validationRequired),
            ),
          ),
          const SizedBox(height: 14),
          KeyedSubtree(
            key: _kProductType,
            child: TextFormField(
              controller: _type,
              decoration: InputDecoration(
                label: RequiredFieldLabel(text: l10n.productTypeLabel),
              ),
              textInputAction: TextInputAction.next,
              validator: (v) => _requiredText(v ?? '', l10n.validationRequired),
            ),
          ),
          const SizedBox(height: 14),
          KeyedSubtree(
            key: _kWeight,
            child: TextFormField(
              controller: _weight,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                label: RequiredFieldLabel(text: l10n.weightKg),
              ),
              textInputAction: TextInputAction.next,
              validator: (v) => _requiredNumber(
                v ?? '',
                l10n.validationRequired,
                l10n.validationRequired,
              ),
            ),
          ),
          const SizedBox(height: 18),
          KeyedSubtree(
            key: _kVolumeCategory,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RequiredFieldLabel(text: l10n.volumeCategoryLabel),
                const SizedBox(height: 10),
                WizardVolumeSelector(
                  l10n: l10n,
                  selected: _volumeCategory,
                  onChanged: (c) {
                    setState(() {
                      _volumeCategory = c;
                      if (!c.dimensionsRequired) {
                        _dimensionsMm.clear();
                      }
                    });
                    if (_showValidation) {
                      _formProduct.currentState?.validate();
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          KeyedSubtree(
            key: _kTransport,
            child: OrderTransportSelector(
              l10n: l10n,
              singleSelect: false,
              selectedStorageKeys: _selectedTransportKeys,
              showValidationError: _showValidation,
              onToggle: (code) {
                setState(() {
                  if (_selectedTransportKeys.contains(code)) {
                    _selectedTransportKeys.remove(code);
                  } else {
                    _selectedTransportKeys.add(code);
                  }
                });
                if (_showValidation) {
                  _formProduct.currentState?.validate();
                }
              },
            ),
          ),
          if (dimRequired) ...[
            const SizedBox(height: 14),
            KeyedSubtree(
              key: _kDimensions,
              child: TextFormField(
                controller: _dimensionsMm,
                keyboardType: TextInputType.number,
                inputFormatters: [DimensionsMmInputFormatter()],
                decoration: InputDecoration(
                  label: RequiredFieldLabel(text: l10n.dimensionsMmLabel),
                  hintText: l10n.dimensionsMmHint,
                ),
                validator: (v) => _validateDimensions(l10n, v),
              ),
            ),
            const SizedBox(height: 14),
          ] else
            const SizedBox(height: 14),
          KeyedSubtree(
            key: _kStartingPrice,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryBlue.withValues(alpha: 0.12),
                    AppColors.primaryBlue.withValues(alpha: 0.03),
                  ],
                ),
                border: Border.all(
                  color: AppColors.primaryBlue.withValues(alpha: 0.22),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(10),
              child: TextFormField(
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.96),
                  label: RequiredFieldLabel(text: l10n.startingPrice),
                  prefixIcon: Icon(
                    Icons.payments_outlined,
                    color: AppColors.primaryBlue.withValues(alpha: 0.85),
                  ),
                ),
                textInputAction: TextInputAction.next,
                validator: (v) => _requiredNumber(
                  v ?? '',
                  l10n.validationRequired,
                  l10n.validationRequired,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          KeyedSubtree(
            key: _kDescription,
            child: TextFormField(
              controller: _desc,
              minLines: 4,
              maxLines: 8,
              decoration: InputDecoration(
                alignLabelWithHint: true,
                labelText:
                    '${l10n.jobDescriptionLabel} (${l10n.fieldOptionalHint})',
              ),
            ),
          ),
          const SizedBox(height: 14),
          KeyedSubtree(
            key: _kOrderComments,
            child: TextFormField(
              controller: _orderComments,
              minLines: 3,
              maxLines: 8,
              maxLength: _kOrderCommentsMaxLength,
              inputFormatters: [
                LengthLimitingTextInputFormatter(_kOrderCommentsMaxLength),
              ],
              decoration: InputDecoration(
                alignLabelWithHint: true,
                labelText:
                    '${l10n.orderCommentsLabel} (${l10n.fieldOptionalHint})',
                hintText: l10n.orderCommentsHint,
              ),
              buildCounter: (
                context, {
                required currentLength,
                required isFocused,
                maxLength,
              }) {
                final m = maxLength ?? _kOrderCommentsMaxLength;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l10n.orderCommentsCharCounter(currentLength, m),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          WizardFragileColdSwitchRow(
            fragileLabel: l10n.fragileItem,
            coldLabel: l10n.needsColdChain,
            fragile: _fragile,
            cold: _cold,
            onFragileChanged: (v) => setState(() => _fragile = v),
            onColdChanged: (v) => setState(() => _cold = v),
          ),
          const SizedBox(height: 8),
          WizardSectionTitle(l10n.paymentType),
          segmentShell(
            SegmentedButton<PaymentType>(
              segments: [
                ButtonSegment(value: PaymentType.cash, label: Text(l10n.paymentCash)),
                ButtonSegment(value: PaymentType.card, label: Text(l10n.paymentCard)),
                ButtonSegment(
                  value: PaymentType.prepaid,
                  label: Text(l10n.paymentPrepaid),
                ),
              ],
              selected: {_pay},
              onSelectionChanged: (s) => setState(() => _pay = s.first),
            ),
          ),
          const SizedBox(height: 14),
          WizardSectionTitle(l10n.deliveryTimeTitle),
          segmentShell(
            SegmentedButton<DeliverySpeed>(
              segments: [
                ButtonSegment(value: DeliverySpeed.fast, label: Text(l10n.deliveryFast)),
                ButtonSegment(
                  value: DeliverySpeed.relaxed,
                  label: Text(l10n.deliveryRelaxed),
                ),
                ButtonSegment(
                  value: DeliverySpeed.custom,
                  label: Text(l10n.deliveryCustom),
                ),
              ],
              selected: {_speed},
              onSelectionChanged: (s) {
                setState(() {
                  _speed = s.first;
                  if (_speed != DeliverySpeed.custom) _window.text = '';
                });
              },
            ),
          ),
          if (_speed == DeliverySpeed.custom) ...[
            const SizedBox(height: 10),
            KeyedSubtree(
              key: _kDeliveryWindow,
              child: TextFormField(
                controller: _window,
                decoration: InputDecoration(
                  label: RequiredFieldLabel(text: l10n.deliveryCustom),
                  hintText: l10n.deliveryUntilHint,
                ),
                validator: (v) {
                  if (_speed != DeliverySpeed.custom) return null;
                  if ((v ?? '').trim().isEmpty) {
                    return l10n.validationRequired;
                  }
                  return null;
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _dualAddressesSubtitle(AppLocalizations l10n) {
    final a = _pickupText.trim();
    final b = _dropText.trim();
    if (a.isEmpty && b.isEmpty) return '';
    final lines = <String>[];
    if (a.isNotEmpty) {
      lines.add('${l10n.pickupLocation}: $a');
    }
    if (b.isNotEmpty) {
      lines.add('${l10n.dropoffLocation}: $b');
    }
    return lines.join('\n');
  }

  String? _dualAddressesError() {
    if (!_showValidation) return null;
    final p = _pickupError;
    final d = _dropoffError;
    if (p != null && d != null) {
      if (p == d) return p;
      return '$p\n$d';
    }
    return p ?? d;
  }

  Widget _stepAddresses(AppLocalizations l10n) {
    return ListView(
      controller: _scrollAddresses,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        KeyedSubtree(
          key: _kAddressesMap,
          child: WizardLocationCard(
            title: l10n.mapDualFlowCardTitle,
            subtitle: _dualAddressesSubtitle(l10n),
            hintWhenEmpty: _kMapPickHint,
            errorText: _dualAddressesError(),
            leadingIcon: Icons.alt_route_rounded,
            onTap: () async {
              final r = await context.push<MapDualPickerResult>(
                '${AppRoutes.mapPicker}?kind=both',
              );
              if (r == null) return;
              setState(() {
                final p = r.pickup;
                _pickupText = p.label;
                _pickupLat = p.lat;
                _pickupLng = p.lng;
                _pickupRegion = p.region.isEmpty ? null : p.region;
                _pickupDistrictOrCity = _districtLine(p);
                _pickupRegionOriginal =
                    p.region.isEmpty ? null : p.region.trim();
                _pickupDistrictOriginal = () {
                  final raw = p.districtGeocoderRaw?.trim();
                  if (raw != null && raw.isNotEmpty) return raw;
                  return _districtLine(p);
                }();
                final d = r.dropoff;
                _dropText = d.label;
                _dropLat = d.lat;
                _dropLng = d.lng;
                _dropoffRegion = d.region.isEmpty ? null : d.region;
                _dropoffDistrictOrCity = _districtLine(d);
                _pickupError = null;
                _dropoffError = null;
                _dropoffRouteKm = d.routeDistanceKm;
              });
            },
          ),
        ),
        const SizedBox(height: 20),
        KeyedSubtree(
          key: _kProductPhoto,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WizardSectionTitle(l10n.productPhoto, required: true),
              Row(
                children: [
                  Expanded(
                    child: _wizardImageActionTile(
                      icon: Icons.photo_camera_rounded,
                      label: l10n.takePhoto,
                      onTap: () => _pickImage(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _wizardImageActionTile(
                      icon: Icons.folder_open_rounded,
                      label: l10n.chooseFile,
                      onTap: _pickFile,
                    ),
                  ),
                ],
              ),
              if (_showValidation && _imageError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _imageError!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ],
            ],
          ),
        ),
        if ((_imageBytes != null && _imageBytes!.isNotEmpty) ||
            (_imagePath.trim().isNotEmpty))
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8EEF4)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: createJobImagePreview(
                bytes: _imageBytes,
                filePath: _imagePath,
                height: 168,
              ),
            ),
          ),
      ],
    );
  }

  Widget _wizardImageActionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppColors.primaryBlue, size: 22),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF334155),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepRecipient(AppLocalizations l10n) {
    return Form(
      key: _formRecipient,
      autovalidateMode: _showValidation
          ? AutovalidateMode.always
          : AutovalidateMode.disabled,
      child: ListView(
        controller: _scrollRecipient,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(
            l10n.stepRecipient,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
          ),
          const SizedBox(height: 20),
          KeyedSubtree(
            key: _kRecipientName,
            child: TextFormField(
              controller: _recipientName,
              decoration: InputDecoration(
                label: RequiredFieldLabel(text: l10n.recipientNameLabel),
                prefixIcon: Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.primaryBlue.withValues(alpha: 0.75),
                ),
              ),
              textInputAction: TextInputAction.next,
              validator: (v) => _requiredText(v ?? '', l10n.validationRequired),
            ),
          ),
          const SizedBox(height: 16),
          KeyedSubtree(
            key: _kRecipientPhone,
            child: TextFormField(
              controller: _recipientPhone,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(9),
                const UzPhoneMaskFormatter(),
              ],
              decoration: InputDecoration(
                label: RequiredFieldLabel(text: l10n.recipientPhoneLabel),
                helperText: l10n.recipientPhoneHelper,
                helperMaxLines: 3,
                prefixIcon: Icon(
                  Icons.phone_outlined,
                  color: AppColors.primaryBlue.withValues(alpha: 0.75),
                ),
                prefixText: '+998 ',
                prefixStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryBlue.withValues(alpha: 0.9),
                    ),
                hintText: '__ ___ __ __',
              ),
              validator: (_) => _validateRecipientPhone(l10n),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepReview(AppLocalizations l10n) {
    final locale =
        ref.watch(localeControllerProvider).valueOrNull ?? const Locale('uz');
    final deliverySummary = _speed == DeliverySpeed.custom
        ? (_window.text.trim().isEmpty ? '—' : _window.text.trim())
        : (_speed == DeliverySpeed.fast ? l10n.deliveryFast : l10n.deliveryRelaxed);
    final pickupLine = deliverySummary;
    final deliveryLine = deliverySummary;

    final pr = double.tryParse(_price.text.replaceAll(',', '.')) ?? 0;
    final nf = NumberFormat.decimalPattern(locale.languageCode);
    final priceFormatted = '${nf.format(pr)} UZS';

    final desc = _desc.text.trim();
    final descDisplay = desc.isEmpty ? '—' : desc;
    final orderCommentsReview = _orderComments.text.trim();

    return CreateJobConfirmPanel(
      scrollController: _scrollReview,
      l10n: l10n,
      productName: _name.text.trim().isEmpty ? null : _name.text.trim(),
      pickupAddress: _pickupText,
      dropoffAddress: _dropText,
      distanceKmFormatted:
          _dropoffRouteKm != null ? formatRouteDistanceKm(_dropoffRouteKm!) : null,
      pickupTimeLine: pickupLine,
      deliveryTimeLine: deliveryLine,
      packageType: _type.text.trim().isEmpty ? '—' : _type.text.trim(),
      packageSize: _volumeCategoryTitle(l10n),
      packageWeight: _weight.text.trim().isEmpty ? '—' : '${_weight.text.trim()} kg',
      packageDescription: descDisplay,
      packageOrderComments:
          orderCommentsReview.isEmpty ? null : orderCommentsReview,
      priceFormatted: priceFormatted,
      imagePath: _imagePath.isEmpty ? null : _imagePath,
      imagePreviewBytes: _imageBytes,
    );
  }
}
