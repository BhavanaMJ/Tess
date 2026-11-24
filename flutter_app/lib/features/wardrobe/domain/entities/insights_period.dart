/// Time period options for Wardrobe Insights and Analytics.
enum AnalyticsPeriod {
  days7,
  days30,
  days90,
  months6,
  months12,
  allTime,
  custom,
}

extension AnalyticsPeriodExtension on AnalyticsPeriod {
  String get queryValue {
    switch (this) {
      case AnalyticsPeriod.days7:
        return '7d';
      case AnalyticsPeriod.days30:
        return '30d';
      case AnalyticsPeriod.days90:
        return '90d';
      case AnalyticsPeriod.months6:
        return '6m';
      case AnalyticsPeriod.months12:
        return '12m';
      case AnalyticsPeriod.allTime:
        return 'all';
      case AnalyticsPeriod.custom:
        return 'custom';
    }
  }

  String get label {
    switch (this) {
      case AnalyticsPeriod.days7:
        return '7 Days';
      case AnalyticsPeriod.days30:
        return '30 Days';
      case AnalyticsPeriod.days90:
        return '90 Days';
      case AnalyticsPeriod.months6:
        return '6 Months';
      case AnalyticsPeriod.months12:
        return '1 Year';
      case AnalyticsPeriod.allTime:
        return 'All Time';
      case AnalyticsPeriod.custom:
        return 'Custom';
    }
  }

  static AnalyticsPeriod fromString(String val) {
    switch (val) {
      case '7d':
        return AnalyticsPeriod.days7;
      case '30d':
        return AnalyticsPeriod.days30;
      case '90d':
        return AnalyticsPeriod.days90;
      case '6m':
        return AnalyticsPeriod.months6;
      case '12m':
        return AnalyticsPeriod.months12;
      case 'all':
        return AnalyticsPeriod.allTime;
      default:
        return AnalyticsPeriod.days30;
    }
  }
}

