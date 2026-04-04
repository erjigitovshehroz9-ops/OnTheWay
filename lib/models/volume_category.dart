/// Hajm kategoriyasi — DB `product_volume_l` uchun vakillik litr qiymati.
enum VolumeCategory {
  small,
  medium,
  large,
  veryLarge;

  double get representativeLiters {
    switch (this) {
      case VolumeCategory.small:
        return 10;
      case VolumeCategory.medium:
        return 50;
      case VolumeCategory.large:
        return 150;
      case VolumeCategory.veryLarge:
        return 500;
    }
  }

  /// Faqat **Katta** va **Juda katta** uchun razmer (mm) majburiy.
  bool get dimensionsRequired =>
      this == VolumeCategory.large || this == VolumeCategory.veryLarge;

  /// Supabase / SQLite uchun barqaror kalit.
  String get storageKey => switch (this) {
        VolumeCategory.small => 'small',
        VolumeCategory.medium => 'medium',
        VolumeCategory.large => 'large',
        VolumeCategory.veryLarge => 'very_large',
      };

  static VolumeCategory? tryFromStorageKey(String? raw) {
    final t = raw?.trim().toLowerCase() ?? '';
    if (t.isEmpty) return null;
    switch (t) {
      case 'small':
        return VolumeCategory.small;
      case 'medium':
        return VolumeCategory.medium;
      case 'large':
        return VolumeCategory.large;
      case 'verylarge':
      case 'very_large':
        return VolumeCategory.veryLarge;
      default:
        return null;
    }
  }
}
