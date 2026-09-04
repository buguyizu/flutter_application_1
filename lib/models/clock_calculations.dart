class ClockCalculations {
  const ClockCalculations._();

  static const historicalEraStartYear = -67046;
  static const yearsPerShi = 30;
  static const yearsPerYun = 12 * yearsPerShi;
  static const yearsPerHui = 30 * yearsPerYun;

  static int huiIndex(DateTime time) {
    return (huiNumber(time) - 1).remainder(12);
  }

  static int shiIndex(DateTime time) {
    return (shiNumber(time) - 1).remainder(12);
  }

  static int yearCycleStart(int year) {
    return historicalEraStartYear +
        (year - historicalEraStartYear) ~/ yearsPerShi * yearsPerShi;
  }

  static int yunIndex(DateTime time) {
    return (yunNumber(time) - 1).remainder(30);
  }

  static int huiNumber(DateTime time) {
    return (time.year - historicalEraStartYear) ~/ yearsPerHui + 1;
  }

  static int yunNumber(DateTime time) {
    return yunNumberForYear(time.year);
  }

  static int yunNumberForYear(int year) {
    return (year - historicalEraStartYear) ~/ yearsPerYun + 1;
  }

  static int shiNumber(DateTime time) {
    return (time.year - historicalEraStartYear) ~/ yearsPerShi + 1;
  }
}
