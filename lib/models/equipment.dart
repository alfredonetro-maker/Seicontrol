class Equipment {
  final String type,
      material,
      serial,
      id,
      description,
      systemStatus,
      location,
      maker,
      installedAt,
      calibration,
      calibrationStatus;
  const Equipment({
    required this.type,
    required this.material,
    required this.serial,
    required this.id,
    required this.description,
    required this.systemStatus,
    required this.location,
    required this.maker,
    required this.installedAt,
    required this.calibration,
    required this.calibrationStatus,
  });

  bool get isMounted => systemStatus.toUpperCase().contains('MONT');
  bool get isAvailable => systemStatus.toUpperCase().contains('DISP');

  /// Returns true if calibration date is older than 1 year or empty/invalid
  bool get isExpired {
    final status = computedCalibrationStatus.toUpperCase();
    return status.contains('VENC');
  }

  String get displayStatus =>
      systemStatus.trim().isEmpty ? 'SIN ESTADO' : systemStatus;
  String get displayCalibration =>
      calibration.trim().isEmpty ? 'Pendiente' : calibration;

  /// Calculates whether calibration is VIGENTE (<= 1 year from today) or VENCIDA (> 1 year or empty)
  String get computedCalibrationStatus {
    if (calibration.trim().isEmpty) return 'VENCIDA';
    try {
      final parts = calibration.trim().split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        final calDate = DateTime(year, month, day);
        final now = DateTime.now();
        final oneYearAgo = DateTime(now.year - 1, now.month, now.day);
        if (calDate.isAfter(oneYearAgo) || calDate.isAtSameMomentAs(oneYearAgo)) {
          return 'VIGENTE';
        }
      }
    } catch (_) {}
    return 'VENCIDA';
  }
}
