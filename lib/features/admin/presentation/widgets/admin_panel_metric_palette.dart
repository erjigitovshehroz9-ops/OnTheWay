import 'package:flutter/material.dart';

/// Admin boshqaruv: metrikalar uchun bir-biri bilan uyg‘un (teal → indigo → violet spektri).
abstract final class AdminPanelMetricPalette {
  static const usersTotal = Color(0xFF4F46E5);
  static const senders = Color(0xFF7C3AED);
  static const couriers = Color(0xFF0F766E);
  static const ordersTotal = Color(0xFF2563EB);
  static const posted = Color(0xFF0369A1);
  static const auctionLive = Color(0xFFD97706);
  static const assigned = Color(0xFF0891B2);
  static const pickedUp = Color(0xFFEA580C);
  static const delivered = Color(0xFF059669);
  static const completed = Color(0xFF16A34A);
  static const cancelled = Color(0xFFE11D48);
  static const blocked = Color(0xFFDC2626);
}
