/// Confirmed Laundry Statuses for TESS Clothes Organizer.
/// Exactly five operational statuses: CLEAN, WORN, WASHING, DRYING, STORED.
/// For unassigned or initial migration items, status may be null (unset/unknown).
enum LaundryStatus {
  clean('CLEAN', 'Clean & Ready'),
  worn('WORN', 'Worn / In Hamper'),
  washing('WASHING', 'In Wash Cycle'),
  drying('DRYING', 'Drying'),
  stored('STORED', 'Stored / Off-Season');

  final String value;
  final String label;

  const LaundryStatus(this.value, this.label);

  static LaundryStatus? fromString(String? val) {
    if (val == null || val.trim().isEmpty) return null;
    final normalized = val.trim().toUpperCase();
    for (final status in LaundryStatus.values) {
      if (status.value == normalized || status.name.toUpperCase() == normalized) {
        return status;
      }
    }
    return null;
  }
}
