import 'dart:math' as math;

/// Start price at step 0; each accept lowers by 5% compound. Floor = 50% of start.
abstract final class AuctionMath {
  static int floorPriceCents(int startPriceCents) =>
      (startPriceCents * 0.5).round();

  /// Leading courier pays this at current [auctionStep] (not below floor).
  static int committedPriceCents(
    int startPriceCents,
    int auctionStep,
    int floorPriceCents,
  ) {
    final p = priceAtStepCents(startPriceCents, auctionStep);
    return math.max(p, floorPriceCents);
  }

  static int priceAtStepCents(int startPriceCents, int auctionStep) {
    final raw = startPriceCents * _pow95(auctionStep);
    return raw.round();
  }

  static bool canDecreaseStep(
    int startPriceCents,
    int currentStep,
    int floorPriceCents,
  ) {
    final next = priceAtStepCents(startPriceCents, currentStep + 1);
    return next >= floorPriceCents;
  }

  /// Server `start_or_step_auction` qadami: `(current * 95) ~/ 100`, keyin floor.
  static int nextPriceAfterServerStepCents(
    int currentPriceCents,
    int floorPriceCents,
  ) {
    final raw = (currentPriceCents * 95) ~/ 100;
    return math.max(raw, floorPriceCents);
  }

  /// Joriy narxdan yana bir qadam tushirish mumkinmi (floor dan yuqori).
  static bool canDecreaseFromCurrentPrice(
    int currentPriceCents,
    int floorPriceCents,
  ) {
    final next = nextPriceAfterServerStepCents(currentPriceCents, floorPriceCents);
    return next < currentPriceCents;
  }

  static double _pow95(int n) {
    if (n <= 0) return 1;
    var v = 1.0;
    for (var i = 0; i < n; i++) {
      v *= 0.95;
    }
    return v;
  }
}
