import 'package:flutter/material.dart';

import 'models/equipment.dart';
import 'services/google_sheets_service.dart';

const _navy = Color(0xff061b4d);
const _blue = Color(0xff0867f9);
const _muted = Color(0xff5c6f9b);
const _line = Color(0xffdce5f3);

// ─── Opciones de dominio ────────────────────────────────────────────────────
const _statusOptions = [
  'MONTADO',
  'DISPONIBLE',
  'EN REPARACIÓN',
  'FUERA DE SERVICIO',
  'BAJA',
];

const _installedAtOptions = [
  'CABEZAL',
  'MANIFOLD',
  'TUBERIA',
  'SEPARADOR',
  'COMPRESOR',
  'CALENTADOR',
  'TANQUE',
];

// ─── Main page ──────────────────────────────────────────────────────────────
class EquipmentDetailPage extends StatefulWidget {
  final Equipment equipment;
  const EquipmentDetailPage(this.equipment, {super.key});

  @override
  State<EquipmentDetailPage> createState() => _EquipmentDetailPageState();
}

class _EquipmentDetailPageState extends State<EquipmentDetailPage> {
  late Equipment _equipment;
  final _service = GoogleSheetsService();

  @override
  void initState() {
    super.initState();
    _equipment = widget.equipment;
  }

  String get _image => switch (_equipment.type.toUpperCase()) {
    'PSV' => 'assets/images/psv.jpg',
    'VE' => 'assets/images/ve.png',
    'VPV' => 'assets/images/vpv.png',
    _ => 'assets/images/vrv.png',
  };

  String get _title => _equipment.id.isEmpty ? _equipment.type : _equipment.id;
  String get _subtitle => _equipment.description.isEmpty
      ? _typeName(_equipment.type)
      : _equipment.description;

  Future<void> _refreshFromSheet() async {
    try {
      final all = await _service.load();
      final updatedItem = all.firstWhere(
        (e) =>
            e.serial.trim().toUpperCase() ==
            _equipment.serial.trim().toUpperCase(),
        orElse: () => _equipment,
      );
      if (mounted) {
        setState(() => _equipment = updatedItem);
      }
    } catch (_) {}
  }

  Future<void> _openEditSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EquipmentEditSheet(
        equipment: _equipment,
        service: _service,
        onUpdated: (updated) {
          if (mounted) {
            setState(() => _equipment = updated);
          }
        },
      ),
    );
    // No recargamos el CSV aquí: la actualización optimista ya se aplicó en la lista.
  }

  @override
  Widget build(BuildContext context) {
    final inService = _equipment.isMounted;
    final statusColor = inService ? Colors.green : Colors.orange;
    return Scaffold(
      backgroundColor: const Color(0xfff7faff),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Container(
              margin: EdgeInsets.all(
                MediaQuery.sizeOf(context).width < 600 ? 0 : 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: _line),
                borderRadius: BorderRadius.circular(36),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(34),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 650;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context, _equipment),
                              icon: const Icon(Icons.arrow_back, color: _blue),
                              style: IconButton.styleFrom(
                                minimumSize: const Size(64, 64),
                                side: const BorderSide(color: _line),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _equipment.type,
                                    style: const TextStyle(
                                      color: _navy,
                                      fontSize: 38,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    _typeName(_equipment.type),
                                    style: const TextStyle(
                                      color: _muted,
                                      fontSize: 19,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _refreshFromSheet,
                              tooltip: 'Actualizar datos',
                              icon: const Icon(
                                Icons.refresh_rounded,
                                color: _blue,
                              ),
                              style: IconButton.styleFrom(
                                minimumSize: const Size(48, 48),
                                side: const BorderSide(color: _line),
                              ),
                            ),
                            const SizedBox(width: 12),
                            _Status(
                              label: _equipment.displayStatus,
                              color: statusColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xffedf5ff), Colors.white],
                            ),
                            border: Border.all(color: const Color(0xffc5dcff)),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Flex(
                            direction: compact
                                ? Axis.vertical
                                : Axis.horizontal,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: compact ? 0 : 5,
                                child: _HeroData(
                                  _equipment,
                                  title: _title,
                                  subtitle: _subtitle,
                                ),
                              ),
                              if (!compact) const SizedBox(width: 18),
                              Expanded(
                                flex: compact ? 0 : 4,
                                child: SizedBox(
                                  height: compact ? 260 : 360,
                                  width: double.infinity,
                                  child: Image.asset(
                                    _image,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _DetailsGrid(_equipment),
                        const SizedBox(height: 26),
                        SizedBox(
                          width: double.infinity,
                          height: 64,
                          child: FilledButton.icon(
                            onPressed: _openEditSheet,
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text(
                              'Actualizar información',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: _blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Edit Bottom Sheet ──────────────────────────────────────────────────────
class EquipmentEditSheet extends StatefulWidget {
  final Equipment equipment;
  final GoogleSheetsService service;
  final ValueChanged<Equipment> onUpdated;
  const EquipmentEditSheet({
    super.key,
    required this.equipment,
    required this.service,
    required this.onUpdated,
  });

  @override
  State<EquipmentEditSheet> createState() => _EquipmentEditSheetState();
}

class _EquipmentEditSheetState extends State<EquipmentEditSheet> {
  late String _status;
  late String _location;
  late String _installedAt;
  late String _calibration;
  bool _saving = false;
  // Reemplazos disponibles con mismo material
  List<Equipment> _replacements = [];
  bool _loadingReplacements = false;

  final _locationCtrl = TextEditingController();

  // Stations fetched from previous list (passed via Equipment.location isn't
  // enough here; we re-use a simple static approach with the known value and
  // let the user type freely).

  @override
  void initState() {
    super.initState();
    final e = widget.equipment;
    _status = _statusOptions.firstWhere(
      (s) => s.toUpperCase() == e.systemStatus.trim().toUpperCase(),
      orElse: () => e.systemStatus.trim().isEmpty
          ? _statusOptions[0]
          : e.systemStatus.trim().toUpperCase(),
    );
    _location = e.location.trim();
    _locationCtrl.text = _location;
    _installedAt = _installedAtOptions.firstWhere(
      (s) => s.toUpperCase() == e.installedAt.trim().toUpperCase(),
      orElse: () => e.installedAt.trim().isEmpty
          ? ''
          : e.installedAt.trim().toUpperCase(),
    );
    _calibration = e.calibration.trim();
    // Si ya comienza en DISPONIBLE carga reemplazos al abrir
    if (_isGoingToWorkshop(_status)) _loadReplacements();
  }

  bool _isGoingToWorkshop(String s) =>
      s.toUpperCase().contains('DISP') ||
      s.toUpperCase().contains('TALLER') ||
      s.toUpperCase().contains('ALM');

  Future<void> _loadReplacements() async {
    if (widget.equipment.material.trim().isEmpty) return;
    setState(() => _loadingReplacements = true);
    try {
      final list = await widget.service.loadAvailableByMaterial(
        type: widget.equipment.type,
        material: widget.equipment.material.trim(),
        excludeSerial: widget.equipment.serial.trim(),
      );
      if (mounted) setState(() => _replacements = list);
    } catch (_) {
      if (mounted) setState(() => _replacements = []);
    } finally {
      if (mounted) setState(() => _loadingReplacements = false);
    }
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    DateTime? initial;
    // Try to parse existing calibration date
    try {
      final parts = _calibration.split('/');
      if (parts.length == 3) {
        initial = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    } catch (_) {}
    initial ??= DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Última fecha de calibración',
      builder: (ctx, child) => Theme(
        data: Theme.of(
          ctx,
        ).copyWith(colorScheme: const ColorScheme.light(primary: _blue)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _calibration =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final isGoingToWorkshop =
        _status.toUpperCase().contains('DISP') ||
        _status.toUpperCase().contains('TALLER') ||
        _status.toUpperCase().contains('ALM');

    // Si pasa a DISPONIBLE / TALLER, su ubicacion tecnica, instalado en y fecha de calibracion quedan EN BLANCO
    final finalLocation = isGoingToWorkshop ? '' : _location;
    final finalInstalledAt = isGoingToWorkshop ? '' : _installedAt;
    final finalCalibration = isGoingToWorkshop ? '' : _calibration;

    try {
      await widget.service.updateEquipment(
        serial: widget.equipment.serial,
        type: widget.equipment.type,
        status: _status,
        location: finalLocation,
        installedAt: finalInstalledAt,
        calibration: finalCalibration,
      );

      // Build updated local Equipment object
      final updated = Equipment(
        type: widget.equipment.type,
        material: widget.equipment.material,
        serial: widget.equipment.serial,
        id: widget.equipment.id,
        description: widget.equipment.description,
        systemStatus: _status,
        location: finalLocation,
        maker: widget.equipment.maker,
        installedAt: finalInstalledAt,
        calibration: finalCalibration,
        calibrationStatus: isGoingToWorkshop
            ? ''
            : widget.equipment.calibrationStatus,
      );
      widget.onUpdated(updated);

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Información actualizada correctamente.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.sizeOf(context).height * .12),
      padding: EdgeInsets.fromLTRB(24, 0, 24, bottom + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 14),
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: _line,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const Text(
              'Editar válvula',
              style: TextStyle(
                color: _navy,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.equipment.id.isEmpty
                  ? widget.equipment.serial
                  : '${widget.equipment.id} · ${widget.equipment.serial}',
              style: const TextStyle(color: _muted, fontSize: 15),
            ),
            const SizedBox(height: 28),

            // ── Estado del equipo ──
            _label('Estado del equipo'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _statusOptions.contains(_status) ? _status : null,
              isExpanded: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.toggle_on_outlined,
                  color: _blue,
                  size: 22,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _blue, width: 2),
                ),
              ),
              items: _statusOptions
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  final wasWorkshop = _isGoingToWorkshop(_status);
                  setState(() => _status = v);
                  final isNowWorkshop = _isGoingToWorkshop(v);
                  if (isNowWorkshop && !wasWorkshop) {
                    _replacements = [];
                    _loadReplacements();
                  } else if (!isNowWorkshop) {
                    setState(() => _replacements = []);
                  }
                }
              },
            ),

            // ── Si el estado es MONTADO (o cualquier estado en sitio), permitimos editar ubicación, instalado en y calibración ──
            if (!_status.toUpperCase().contains('DISP') &&
                !_status.toUpperCase().contains('TALLER') &&
                !_status.toUpperCase().contains('ALM')) ...[
              const SizedBox(height: 20),

              // ── Ubicación técnica (estación) ──
              _label('Ubicación técnica (Estación)'),
              const SizedBox(height: 8),
              _LocationSelector(
                initialValue: _location,
                service: widget.service,
                onChanged: (val) => setState(() => _location = val),
              ),
              const SizedBox(height: 20),

              // ── Instalado en ──
              _label('Instalado en'),
              const SizedBox(height: 8),
              _InstalledAtSelector(
                initialValue: _installedAt,
                service: widget.service,
                onChanged: (val) => setState(() => _installedAt = val),
              ),
              const SizedBox(height: 20),

              // ── Última fecha de calibración ──
              _label('Última fecha de calibración'),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: _line),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_outlined,
                        color: _blue,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _calibration.isEmpty
                              ? 'Seleccionar fecha'
                              : _calibration,
                          style: TextStyle(
                            color: _calibration.isEmpty ? _muted : _navy,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: _muted),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            const SizedBox(height: 12),

            // ── Sugerencias de reemplazo cuando pasa a DISPONIBLE ──
            if (_isGoingToWorkshop(_status)) ...[
              const Divider(height: 32, color: Color(0xffdce5f3)),
              Row(
                children: [
                  const Icon(Icons.swap_horiz_rounded, color: Color(0xff0867f9), size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Montar reemplazo en la misma instalación',
                      style: TextStyle(
                        color: Color(0xff061b4d),
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Material ${widget.equipment.material} · DISPONIBLES',
                style: const TextStyle(color: Color(0xff5c6f9b), fontSize: 13),
              ),
              const SizedBox(height: 12),
              if (_loadingReplacements)
                const Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ))
              else if (_replacements.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xfff6f9ff),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xffdce5f3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xff5c6f9b), size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No hay válvulas disponibles con el mismo número de material.',
                          style: TextStyle(color: Color(0xff5c6f9b), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ..._replacements.map((r) => _ReplacementTile(
                  originalEquipment: widget.equipment,
                  replacement: r,
                  targetLocation: _location,
                  targetInstalledAt: _installedAt,
                  service: widget.service,
                  onMounted: (mounted) {
                    widget.onUpdated(mounted);
                  },
                )),
              const SizedBox(height: 16),
            ],

            // ── Botón guardar ──
            SizedBox(
              width: double.infinity,
              height: 58,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(
                  _saving ? 'Guardando...' : 'Guardar cambios',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      color: _navy,
      fontSize: 14,
      fontWeight: FontWeight.w700,
    ),
  );
}

// ─── Replacement Tile ──────────────────────────────────────────────────────
class _ReplacementTile extends StatelessWidget {
  final Equipment originalEquipment;
  final Equipment replacement;
  final String targetLocation;
  final String targetInstalledAt;
  final GoogleSheetsService service;
  final ValueChanged<Equipment> onMounted;

  const _ReplacementTile({
    required this.originalEquipment,
    required this.replacement,
    required this.targetLocation,
    required this.targetInstalledAt,
    required this.service,
    required this.onMounted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xfff6f9ff),
        border: Border.all(color: const Color(0xffc3d8ff)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xffe4eeff),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.swap_horiz_rounded, color: Color(0xff0867f9), size: 22),
        ),
        title: Text(
          replacement.id.isEmpty ? replacement.serial : '${replacement.id} · ${replacement.serial}',
          style: const TextStyle(
            color: Color(0xff061b4d),
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          'Serie ${replacement.serial}  •  Material ${replacement.material}',
          style: const TextStyle(color: Color(0xff5c6f9b), fontSize: 12),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xff0867f9), size: 16),
        onTap: () async {
          // 1. Guardar automáticamente el equipo desinstalado original como DISPONIBLE en Google Sheets
          final dismountedOriginal = Equipment(
            type: originalEquipment.type,
            material: originalEquipment.material,
            serial: originalEquipment.serial,
            id: originalEquipment.id,
            description: originalEquipment.description,
            systemStatus: 'DISPONIBLE',
            location: '',
            maker: originalEquipment.maker,
            installedAt: '',
            calibration: '',
            calibrationStatus: '',
          );

          try {
            await service.updateEquipment(
              serial: originalEquipment.serial,
              type: originalEquipment.type,
              status: 'DISPONIBLE',
              location: '',
              installedAt: '',
              calibration: '',
            );
          } catch (_) {}

          // Notificar actualización del equipo desinstalado para que la UI local sepa de inmediato que ya está DISPONIBLE
          onMounted(dismountedOriginal);

          // Abrir el editor del reemplazo pre-llenado con la misma ubicación
          final prefilledReplacement = Equipment(
            type: replacement.type,
            material: replacement.material,
            serial: replacement.serial,
            id: replacement.id,
            description: replacement.description,
            systemStatus: 'MONTADO',
            location: targetLocation,
            maker: replacement.maker,
            installedAt: targetInstalledAt,
            calibration: replacement.calibration,
            calibrationStatus: replacement.calibrationStatus,
          );
          // Cerrar la hoja actual antes de abrir la del reemplazo
          Navigator.pop(context);

          await showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (ctx) => EquipmentEditSheet(
              equipment: prefilledReplacement,
              service: service,
              onUpdated: onMounted,
            ),
          );
        },
      ),
    );
  }
}

// ─── Mount Configuration Bottom Sheet ─────────────────────────────────────────
class _MountConfigSheet extends StatefulWidget {
  final Equipment equipment;
  final String targetLocation;
  final String targetInstalledAt;
  final GoogleSheetsService service;

  const _MountConfigSheet({
    required this.equipment,
    required this.targetLocation,
    required this.targetInstalledAt,
    required this.service,
  });

  @override
  State<_MountConfigSheet> createState() => _MountConfigSheetState();
}

class _MountConfigSheetState extends State<_MountConfigSheet> {
  late String _location;
  late String _installedAt;
  late String _calibration;
  bool _saving = false;

  final _locationCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _location = widget.targetLocation;
    _locationCtrl.text = _location;
    _installedAt = widget.targetInstalledAt.isNotEmpty
        ? widget.targetInstalledAt
        : (_installedAtOptions.contains(widget.equipment.installedAt)
              ? widget.equipment.installedAt
              : _installedAtOptions[0]);
    _calibration = widget.equipment.calibration;
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    DateTime? initial;
    try {
      final parts = _calibration.split('/');
      if (parts.length == 3) {
        initial = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    } catch (_) {}
    initial ??= DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Última fecha de calibración',
      builder: (ctx, child) => Theme(
        data: Theme.of(
          ctx,
        ).copyWith(colorScheme: const ColorScheme.light(primary: _blue)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _calibration =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  /// Calculates dynamic status for display: VIGENTE (<= 1 year) or VENCIDA (> 1 year or empty)
  String get _calculatedCalibrationStatus {
    if (_calibration.trim().isEmpty) return 'VENCIDA';
    try {
      final parts = _calibration.trim().split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        final calDate = DateTime(year, month, day);
        final now = DateTime.now();
        final oneYearAgo = DateTime(now.year - 1, now.month, now.day);
        if (calDate.isAfter(oneYearAgo) ||
            calDate.isAtSameMomentAs(oneYearAgo)) {
          return 'VIGENTE';
        }
      }
    } catch (_) {}
    return 'VENCIDA';
  }

  Future<void> _mountEquipment() async {
    setState(() => _saving = true);
    try {
      await widget.service.updateEquipment(
        serial: widget.equipment.serial,
        type: widget.equipment.type,
        status: 'MONTADO',
        location: _location,
        installedAt: _installedAt,
        calibration: _calibration,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Válvula ${widget.equipment.id.isEmpty ? widget.equipment.serial : widget.equipment.id} '
              'montada exitosamente en $_location ($_calculatedCalibrationStatus).',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al guardar montaje: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final calStatus = _calculatedCalibrationStatus;
    final isVigente = calStatus == 'VIGENTE';

    return Container(
      margin: EdgeInsets.only(top: MediaQuery.sizeOf(context).height * .10),
      padding: EdgeInsets.fromLTRB(24, 0, 24, bottom + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 14),
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: _line,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Montar nuevo equipo',
                        style: TextStyle(
                          color: _navy,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Válvula: ${widget.equipment.id.isEmpty ? widget.equipment.serial : widget.equipment.id}',
                        style: const TextStyle(color: _muted, fontSize: 15),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isVigente
                        ? Colors.green.withValues(alpha: .12)
                        : Colors.red.withValues(alpha: .12),
                    border: Border.all(
                      color: isVigente ? Colors.green : Colors.red,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    calStatus,
                    style: TextStyle(
                      color: isVigente ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Ubicación técnica ──
            _label('Ubicación técnica (Estación)'),
            const SizedBox(height: 8),
            _LocationSelector(
              initialValue: _location,
              service: widget.service,
              onChanged: (val) => setState(() => _location = val),
            ),
            const SizedBox(height: 20),

            // ── Instalado en ──
            _label('Instalado en'),
            const SizedBox(height: 8),
            _InstalledAtSelector(
              initialValue: _installedAt,
              service: widget.service,
              onChanged: (val) => setState(() => _installedAt = val),
            ),
            const SizedBox(height: 20),

            // ── Fecha de calibración ──
            _label('Última fecha de calibración'),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: _line),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_outlined,
                      color: _blue,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _calibration.isEmpty
                            ? 'Seleccionar fecha'
                            : _calibration,
                        style: TextStyle(
                          color: _calibration.isEmpty ? _muted : _navy,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: _muted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Indicar lógica de estado de calibración
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isVigente
                    ? const Color(0xfff0fbf4)
                    : const Color(0xfffff4f4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isVigente
                      ? Colors.green.withValues(alpha: .3)
                      : Colors.red.withValues(alpha: .3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isVigente
                        ? Icons.verified_user
                        : Icons.warning_amber_rounded,
                    color: isVigente ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isVigente
                          ? 'Calibración VIGENTE (con menos de 1 año).'
                          : 'Calibración VENCIDA (más de 1 año o sin fecha).',
                      style: TextStyle(
                        color: isVigente ? Colors.green[800] : Colors.red[800],
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Botón Confirmar Montaje ──
            SizedBox(
              width: double.infinity,
              height: 58,
              child: FilledButton.icon(
                onPressed: _saving ? null : _mountEquipment,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  _saving
                      ? 'Guardando montaje...'
                      : 'Confirmar y montar equipo',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      color: _navy,
      fontSize: 14,
      fontWeight: FontWeight.w700,
    ),
  );
}

// ─── Location (Station) Selector Widget ───────────────────────────────────────
class _LocationSelector extends StatefulWidget {
  final String initialValue;
  final GoogleSheetsService service;
  final ValueChanged<String> onChanged;

  const _LocationSelector({
    required this.initialValue,
    required this.service,
    required this.onChanged,
  });

  @override
  State<_LocationSelector> createState() => _LocationSelectorState();
}

class _LocationSelectorState extends State<_LocationSelector> {
  late String _currentValue;
  bool _isCustom = false;
  List<String> _options = [];
  final _customCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue.trim();
    _customCtrl.text = _currentValue;
    _loadLocationsFromSheet();
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLocationsFromSheet() async {
    try {
      final sheetLocations = await widget.service.loadLocations();
      if (!mounted) return;
      final set = <String>{};
      if (_currentValue.isNotEmpty && _currentValue.toUpperCase() != 'OTRO') {
        set.add(_currentValue.toUpperCase());
      }
      for (final loc in sheetLocations) {
        final upper = loc.trim().toUpperCase();
        if (upper.isNotEmpty && upper != 'OTRO') {
          set.add(upper);
        }
      }
      final list = set.toList()..sort();
      if (_currentValue.isNotEmpty &&
          !list.contains(_currentValue.toUpperCase())) {
        _isCustom = true;
      }
      setState(() {
        _options = list;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final selectedOption = _isCustom
        ? 'OTRO'
        : (_options.contains(_currentValue.toUpperCase())
              ? _currentValue.toUpperCase()
              : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: selectedOption,
          isExpanded: true,
          hint: const Text('Seleccionar estación / ubicación técnica'),
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.location_on_outlined,
              color: _blue,
              size: 22,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _blue, width: 2),
            ),
          ),
          items: [
            ..._options.map((s) => DropdownMenuItem(value: s, child: Text(s))),
            const DropdownMenuItem(
              value: 'OTRO',
              child: Row(
                children: [
                  Icon(Icons.edit_location_alt_rounded, color: _blue, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Escribir otra ubicación...',
                    style: TextStyle(color: _blue, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
          onChanged: (val) {
            if (val == 'OTRO') {
              setState(() {
                _isCustom = true;
              });
              widget.onChanged(_customCtrl.text);
            } else if (val != null) {
              setState(() {
                _isCustom = false;
                _currentValue = val;
              });
              widget.onChanged(val);
            }
          },
        ),
        if (_isCustom) ...[
          const SizedBox(height: 10),
          TextField(
            controller: _customCtrl,
            onChanged: (val) => widget.onChanged(val),
            decoration: InputDecoration(
              hintText: 'Escribe el nombre de la estación o ubicación técnica',
              prefixIcon: const Icon(
                Icons.edit_location_outlined,
                color: _blue,
                size: 22,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _blue),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _blue),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _blue, width: 2),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Installed At Selector Widget ─────────────────────────────────────────────
class _InstalledAtSelector extends StatefulWidget {
  final String initialValue;
  final GoogleSheetsService service;
  final ValueChanged<String> onChanged;

  const _InstalledAtSelector({
    required this.initialValue,
    required this.service,
    required this.onChanged,
  });

  @override
  State<_InstalledAtSelector> createState() => _InstalledAtSelectorState();
}

class _InstalledAtSelectorState extends State<_InstalledAtSelector> {
  late String _currentValue;
  bool _isCustom = false;
  List<String> _options = List.from(_installedAtOptions);
  final _customCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue.trim();
    if (_currentValue.isNotEmpty &&
        !_options.contains(_currentValue.toUpperCase())) {
      _isCustom = true;
      _customCtrl.text = _currentValue;
    }
    _loadOptionsFromSheet();
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadOptionsFromSheet() async {
    try {
      final sheetValues = await widget.service.loadInstalledAtOptions();
      if (!mounted) return;
      final set = <String>{};
      for (final opt in _installedAtOptions) {
        final upper = opt.toUpperCase();
        if (upper != 'OTRO') set.add(upper);
      }
      for (final val in sheetValues) {
        final upper = val.trim().toUpperCase();
        if (upper.isNotEmpty && upper != 'OTRO') {
          set.add(upper);
        }
      }
      setState(() {
        _options = set.toList()..sort();
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final selectedOption = _isCustom
        ? 'OTRO'
        : (_options.contains(_currentValue.toUpperCase())
              ? _currentValue.toUpperCase()
              : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: selectedOption,
          isExpanded: true,
          hint: const Text('Seleccionar ubicación'),
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.build_outlined,
              color: _blue,
              size: 22,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _blue, width: 2),
            ),
          ),
          items: [
            ..._options.map((s) => DropdownMenuItem(value: s, child: Text(s))),
            const DropdownMenuItem(
              value: 'OTRO',
              child: Row(
                children: [
                  Icon(Icons.edit_note_rounded, color: _blue, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Escribir otro lugar...',
                    style: TextStyle(color: _blue, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
          onChanged: (val) {
            if (val == 'OTRO') {
              setState(() {
                _isCustom = true;
              });
              widget.onChanged(_customCtrl.text);
            } else if (val != null) {
              setState(() {
                _isCustom = false;
                _currentValue = val;
              });
              widget.onChanged(val);
            }
          },
        ),
        if (_isCustom) ...[
          const SizedBox(height: 10),
          TextField(
            controller: _customCtrl,
            onChanged: (val) => widget.onChanged(val),
            decoration: InputDecoration(
              hintText: 'Escribe la ubicación específica',
              prefixIcon: const Icon(
                Icons.edit_outlined,
                color: _blue,
                size: 22,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _blue),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _blue),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _blue, width: 2),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Resto de widgets ────────────────────────────────────────────────────────
class _HeroData extends StatelessWidget {
  final Equipment equipment;
  final String title;
  final String subtitle;
  const _HeroData(
    this.equipment, {
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: _navy,
          fontSize: 34,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 4),
      Text(subtitle, style: const TextStyle(color: _muted, fontSize: 19)),
      const SizedBox(height: 28),
      _heroItem('FABRICANTE', equipment.maker),
      _heroItem('MATERIAL', equipment.material),
      _heroItem('UBICACIÓN ACTUAL', equipment.location),
      _heroItem('INSTALADO EN', equipment.installedAt),
    ],
  );

  Widget _heroItem(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _muted,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.isEmpty ? 'Sin información' : value,
          style: const TextStyle(
            color: _navy,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _DetailsGrid extends StatelessWidget {
  final Equipment equipment;
  const _DetailsGrid(this.equipment);

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.sell_outlined, 'TIPO', _typeName(equipment.type)),
      (Icons.layers_outlined, 'MATERIAL', equipment.material),
      (Icons.tag_outlined, 'NÚMERO DE SERIE', equipment.serial),
      (Icons.inventory_2_outlined, 'EQUIPO', equipment.id),
      (
        Icons.description_outlined,
        'DENOMINACIÓN DE OBJETO',
        equipment.description,
      ),
      (Icons.remove_circle_outline, 'STATUS SISTEMA', equipment.displayStatus),
      (Icons.location_on_outlined, 'UBICACIÓN TÉCNICA', equipment.location),
      (Icons.factory_outlined, 'FABRICANTE', equipment.maker),
      (Icons.build_outlined, 'INSTALADO EN', equipment.installedAt),
      (
        Icons.calendar_month_outlined,
        'FECHA CALIBRACIÓN',
        equipment.displayCalibration,
      ),
      (Icons.verified_user_outlined, 'ESTADO', equipment.calibrationStatus),
    ];

    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      final left = items[i];
      final right = (i + 1 < items.length) ? items[i + 1] : null;

      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _DetailItem(
                  icon: left.$1,
                  label: left.$2,
                  value: left.$3,
                  showRightBorder: true,
                ),
              ),
              Expanded(
                child: right != null
                    ? _DetailItem(
                        icon: right.$1,
                        label: right.$2,
                        value: right.$3,
                        showRightBorder: false,
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(22),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: rows,
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool showRightBorder;
  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
    this.showRightBorder = false,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    decoration: BoxDecoration(
      border: Border(
        bottom: const BorderSide(color: _line),
        right: showRightBorder ? const BorderSide(color: _line) : BorderSide.none,
      ),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xfff1f6ff),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _blue, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value.isEmpty ? 'Sin información' : value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _navy,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Status extends StatelessWidget {
  final String label;
  final Color color;
  const _Status({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      border: Border.all(color: color.withValues(alpha: .35)),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, color: color, size: 14),
        const SizedBox(width: 9),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

String _typeName(String type) => switch (type.toUpperCase()) {
  'PSV' => 'Válvula de Seguridad',
  'VE' => 'Ventila de Emergencia',
  'VPV' || 'VRV' => 'Válvula de Presión-Vacío',
  _ => 'Equipo',
};
