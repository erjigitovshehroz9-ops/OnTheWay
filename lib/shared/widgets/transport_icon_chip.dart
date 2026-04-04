import 'package:flutter/material.dart';

/// Kuryer profilidagi transport tanlash chip bilan bir xil ko‘rinish.
/// [dense] — buyurtma formasi uchun pastroq variant; [enabled] — false bo‘lsa bosilmaydi.
/// [interactive] — false bo‘lsa ichida [InkWell] bo‘lmaydi (tashqi [InkWell] / gesture ishlatish uchun).
class TransportIconChip extends StatelessWidget {
  const TransportIconChip({
    super.key,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.enabled = true,
    this.dense = false,
    this.interactive = true,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool enabled;
  final bool dense;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    final outerV = dense ? 4.0 : 11.0;
    final innerV = dense ? 3.0 : 7.0;
    final iconSize = dense ? 17.0 : 22.0;
    final rOuter = dense ? 9.0 : 12.0;
    final rInner = dense ? 8.0 : 10.0;

    final borderSelected = const Color(0xFF2563EB);
    final borderIdle = const Color(0xFFD6E2FA);
    final borderDisabled = const Color(0xFFE8EEF4);

    final bgSelected = const Color(0xFFDBEAFE);
    final bgIdle = const Color(0xFFF8FBFF);
    final bgDisabled = const Color(0xFFF1F5F9);

    final iconSelected = const Color(0xFF1D4ED8);
    final iconIdle = const Color(0xFF64748B);
    final iconDisabled = const Color(0xFF94A3B8);

    final matTop = selected ? const Color(0xFFE8F0FF) : const Color(0xFFF5F9FF);
    final matTopDisabled = const Color(0xFFF8FAFC);

    final core = Padding(
      padding: EdgeInsets.symmetric(vertical: outerV),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(rInner),
          border: Border.all(
            color: !enabled
                ? borderDisabled
                : (selected ? borderSelected : borderIdle),
            width: selected ? 1.6 : 1.1,
          ),
          color: !enabled
              ? bgDisabled
              : (selected ? bgSelected : bgIdle),
        ),
        padding: EdgeInsets.symmetric(vertical: innerV),
        child: Icon(
          icon,
          size: iconSize,
          color: !enabled
              ? iconDisabled
              : (selected ? iconSelected : iconIdle),
        ),
      ),
    );

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: enabled ? matTop : matTopDisabled,
        borderRadius: BorderRadius.circular(rOuter),
        clipBehavior: Clip.antiAlias,
        child: interactive
            ? InkWell(
                borderRadius: BorderRadius.circular(rOuter),
                onTap: enabled ? onTap : null,
                child: core,
              )
            : core,
      ),
    );
  }
}
