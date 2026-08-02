import 'package:flutter/material.dart';
import 'equipment_detail_page.dart';
import 'models/equipment.dart';
import 'services/google_sheets_service.dart';

const _navy = Color(0xff061b4d),
    _blue = Color(0xff0867f9),
    _muted = Color(0xff5c6f9b),
    _line = Color(0xffdce5f3);

class DataListPage extends StatefulWidget {
  final String type;
  final String? initialStation;
  const DataListPage(this.type, {super.key, this.initialStation});
  @override
  State<DataListPage> createState() => _DataListPageState();
}

class _DataListPageState extends State<DataListPage> {
  final _service = GoogleSheetsService(), _search = TextEditingController();
  late Future<List<Equipment>> _future;
  String _filter = 'Todos';
  late String _station;
  // Cambios locales optimistas: serial -> Equipment actualizado
  final Map<String, Equipment> _localOverrides = {};

  void _reload() {
    final newFuture = _service.load();
    setState(() {
      _future = newFuture;
    });
  }

  @override
  void initState() {
    super.initState();
    _station = widget.initialStation ?? '';
    _future = _service.load();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Equipment> _filterRows(List<Equipment> rows) {
    final q = _search.text.trim().toUpperCase();
    final isAllTypes =
        widget.type.trim().isEmpty ||
        widget.type.trim().toUpperCase() == 'TODOS' ||
        widget.type.trim().toUpperCase() == 'ALL';

    return rows.where((e) {
      if (!isAllTypes &&
          e.type.trim().toUpperCase() != widget.type.trim().toUpperCase()) {
        return false;
      }
      if (_filter == 'Montados' && !e.isMounted) {
        return false;
      }
      if (_filter == 'Disponibles' && !e.isAvailable) {
        return false;
      }
      if (_filter == 'Vencidos' && !e.isExpired) {
        return false;
      }
      // Dropdown/chip station filter
      if (_station.isNotEmpty &&
          e.location.trim().toUpperCase() != _station.trim().toUpperCase()) {
        return false;
      }
      // Text search: filter by station/location text or details
      return q.isEmpty ||
          e.location.trim().toUpperCase().contains(q) ||
          '${e.type} ${e.serial} ${e.id} ${e.description}'
              .toUpperCase()
              .contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isAllTypes =
        widget.type.trim().isEmpty ||
        widget.type.trim().toUpperCase() == 'TODOS' ||
        widget.type.trim().toUpperCase() == 'ALL';
    final titleText = isAllTypes ? 'ESTACIÓN' : widget.type;
    final sub = isAllTypes
        ? (_station.isEmpty ? 'Todos los equipos' : 'Equipos de $_station')
        : ({
                'PSV': 'Válvulas de Seguridad',
                'VE': 'Ventila de Emergencia',
                'VPV': 'Válvulas de Presión-Vacío',
                'VRV': 'Válvulas Rompedora de Vacio',
              }[widget.type] ??
              'Equipos');

    return _Frame(
      child: FutureBuilder<List<Equipment>>(
        future: _future,
        builder: (context, snapshot) {
          final compact = MediaQuery.sizeOf(context).width < 600;
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _Error(
              message: 'No se pudieron cargar los datos publicados.',
              retry: _reload,
            );
          }
          final rawSource = snapshot.data ?? [];
          // Aplicar overrides locales para reflejar cambios al instante
          final source = rawSource.map((e) {
            final override = _localOverrides[e.serial.trim().toUpperCase()];
            return override ?? e;
          }).toList();
          final rows = _filterRows(source),
              stations =
                  source
                      .where(
                        (e) =>
                            (isAllTypes ||
                                e.type.trim().toUpperCase() ==
                                    widget.type.trim().toUpperCase()) &&
                            e.location.trim().isNotEmpty,
                      )
                       .map((e) => e.location.trim())
                       .toSet()
                       .toList()
                     ..sort();
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 20 : 38,
                  28,
                  compact ? 20 : 38,
                  0,
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back, color: _blue),
                            style: IconButton.styleFrom(
                              side: const BorderSide(color: _line),
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              titleText,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: _navy,
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              sub,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 17,
                              ),
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            onPressed: _reload,
                            tooltip: 'Actualizar datos',
                            icon: const Icon(
                              Icons.refresh_rounded,
                              color: _blue,
                            ),
                            style: IconButton.styleFrom(
                              side: const BorderSide(color: _line),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // ─── 4 Botones de Filtro ─────────────────────────
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          'Todos',
                          'Montados',
                          'Disponibles',
                          'Vencidos',
                        ].map((f) {
                          final selected = _filter == f;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                f.toUpperCase(),
                                style: TextStyle(
                                  color: selected ? Colors.white : _navy,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  letterSpacing: .3,
                                ),
                              ),
                              selected: selected,
                              selectedColor: _blue,
                              backgroundColor: const Color(0xfff0f4fb),
                              showCheckmark: false,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: selected ? _blue : _line,
                                  width: 1.5,
                                ),
                              ),
                              onSelected: (_) => setState(() => _filter = f),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _search,
                      decoration: InputDecoration(
                        hintText: 'Buscar por estación',
                        hintStyle: const TextStyle(color: _muted, fontSize: 16),
                        prefixIcon: const Icon(
                          Icons.location_on_outlined,
                          color: _blue,
                          size: 24,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: Color(0xff7c4dff),
                            width: 1.8,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: Color(0xff7c4dff),
                            width: 1.8,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: _blue, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      key: ValueKey(_station),
                      initialValue: _station.isEmpty ? null : _station,
                      isExpanded: true,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.location_on_outlined,
                          color: _blue,
                          size: 24,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: Color(0xff7c4dff),
                            width: 1.8,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: Color(0xff7c4dff),
                            width: 1.8,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: _blue, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      hint: Text(
                        stations.isEmpty
                            ? 'No hay estaciones registradas'
                            : 'Todas las estaciones (${stations.length})',
                        style: const TextStyle(color: _muted, fontSize: 16),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: Text('Todas las estaciones'),
                        ),
                        ...stations.map(
                          (s) => DropdownMenuItem(value: s, child: Text(s)),
                        ),
                      ],
                      onChanged: (v) => setState(() => _station = v ?? ''),
                    ),
                    if (stations.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Estaciones disponibles (${stations.length})',
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 42,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: stations.length,
                          separatorBuilder: (_, index) =>
                              const SizedBox(width: 8),
                          itemBuilder: (_, index) {
                            final station = stations[index];
                            return ChoiceChip(
                              label: Text(station),
                              selected: _station == station,
                              selectedColor: _blue,
                              labelStyle: TextStyle(
                                color: _station == station
                                    ? Colors.white
                                    : _muted,
                              ),
                              onSelected: (_) => setState(
                                () => _station = _station == station
                                    ? ''
                                    : station,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    _reload();
                    await _future;
                  },
                  child: rows.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 100),
                            const Center(
                              child: Text(
                                'No hay equipos para estos filtros.',
                                style: TextStyle(color: _muted),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(
                            compact ? 20 : 38,
                            0,
                            compact ? 20 : 38,
                            22,
                          ),
                          itemCount: rows.length,
                          separatorBuilder: (_, i) =>
                              const SizedBox(height: 13),
                          itemBuilder: (_, i) => _EquipmentCard(
                            rows[i],
                            onUpdated: (updated) {
                              if (updated != null) {
                                setState(() {
                                  _localOverrides[
                                    updated.serial.trim().toUpperCase()
                                  ] = updated;
                                });
                              }
                            },
                          ),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Frame extends StatelessWidget {
  final Widget child;
  const _Frame({required this.child});
  @override
  Widget build(BuildContext c) => Scaffold(
    backgroundColor: const Color(0xfff7faff),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1160),
          child: Container(
            margin: EdgeInsets.all(MediaQuery.sizeOf(c).width < 600 ? 0 : 16),
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.sizeOf(c).height -
                  (MediaQuery.sizeOf(c).width < 600 ? 0 : 32),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                MediaQuery.sizeOf(c).width < 600 ? 0 : 36,
              ),
              border: Border.all(color: _line),
            ),
            child: child,
          ),
        ),
      ),
    ),
  );
}

class _Error extends StatelessWidget {
  final String message;
  final VoidCallback retry;
  const _Error({required this.message, required this.retry});
  @override
  Widget build(BuildContext c) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cloud_off_outlined, color: _muted, size: 46),
        const SizedBox(height: 12),
        Text(message, style: const TextStyle(color: _muted)),
        TextButton(onPressed: retry, child: const Text('Reintentar')),
      ],
    ),
  );
}

class _EquipmentCard extends StatelessWidget {
  final Equipment e;
  final void Function(Equipment? updated)? onUpdated;
  const _EquipmentCard(this.e, {this.onUpdated});

  static final _service = GoogleSheetsService();

  @override
  Widget build(BuildContext c) => InkWell(
    onTap: () async {
      Equipment? result;
      await showModalBottomSheet<void>(
        context: c,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => EquipmentEditSheet(
          equipment: e,
          service: _service,
          onUpdated: (updated) => result = updated,
        ),
      );
      onUpdated?.call(result);
    },
    borderRadius: BorderRadius.circular(18),
    child: Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _data('EQUIPO', e.id),
              const Spacer(),
              _data('N° SERIE', e.serial),
              const SizedBox(width: 18),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _tag(
                    e.displayStatus,
                    e.isMounted
                        ? Colors.green
                        : e.isAvailable
                        ? Colors.orange
                        : _muted,
                  ),
                  const SizedBox(height: 5),
                  _tag(
                    e.isExpired
                        ? 'VENCIDA'
                        : e.calibration.isEmpty
                        ? 'SIN FECHA'
                        : e.calibrationStatus,
                    e.isExpired ? Colors.red : Colors.orange,
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 24, color: _line),
          Wrap(
            spacing: 28,
            runSpacing: 10,
            children: [
              _data('FABRICANTE', e.maker),
              _data('MATERIAL', e.material),
              _data(
                'ÚLTIMA CALIBRACIÓN',
                e.displayCalibration,
                Icons.calendar_month_outlined,
              ),
              _data(
                'UBICACIÓN ACTUAL',
                e.location.isEmpty ? 'Sin ubicación' : e.location,
                Icons.location_on_outlined,
                Colors.deepOrange,
              ),
            ],
          ),
          if (e.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                e.description,
                style: const TextStyle(
                  color: _muted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

Widget _data(String label, String value, [IconData? icon, Color? color]) =>
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: color ?? _muted),
              const SizedBox(width: 6),
            ],
            Text(
              value.isEmpty ? '—' : value,
              style: TextStyle(
                color: color ?? _navy,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
Widget _tag(String text, Color color) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
  decoration: BoxDecoration(
    border: Border.all(color: color.withValues(alpha: .6)),
    borderRadius: BorderRadius.circular(6),
  ),
  child: Text(
    text.isEmpty ? 'SIN FECHA' : text,
    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
  ),
);
