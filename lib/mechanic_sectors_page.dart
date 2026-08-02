import 'package:flutter/material.dart';

import 'main.dart';
import 'models/mechanic_well.dart';
import 'services/google_sheets_service.dart';

const _navy = Color(0xff061b4d);
const _blue = Color(0xff0867f9);
const _muted = Color(0xff5c6f9b);
const _line = Color(0xffdce5f3);

enum _EquipmentType { gearReducer, electricMotor }

class _ComponentKey {
  final String sector;
  final String well;
  final _EquipmentType type;
  const _ComponentKey(this.sector, this.well, this.type);

  @override
  bool operator ==(Object other) =>
      other is _ComponentKey &&
      sector == other.sector &&
      well == other.well &&
      type == other.type;

  @override
  int get hashCode => Object.hash(sector, well, type);
}

class _AvailableEquipment {
  final _ComponentKey source;
  final MechanicComponent component;
  const _AvailableEquipment({required this.source, required this.component});
}

/// Holds equipment movements while the app is open. The source spreadsheet is
/// published read-only, so movements are intentionally kept on this device.
class _MechanicChanges {
  static final instance = _MechanicChanges._();
  _MechanicChanges._();

  final _overrides = <_ComponentKey, MechanicComponent>{};

  MechanicComponent componentOf(MechanicWell well, _EquipmentType type) =>
      _overrides[_ComponentKey(well.sector, well.well, type)] ??
      (type == _EquipmentType.gearReducer
          ? well.gearReducer
          : well.electricMotor);

  MechanicWell apply(MechanicWell well) => well.copyWith(
    gearReducer: componentOf(well, _EquipmentType.gearReducer),
    electricMotor: componentOf(well, _EquipmentType.electricMotor),
  );

  void dismount(MechanicWell well, _EquipmentType type) {
    final key = _ComponentKey(well.sector, well.well, type);
    _overrides[key] = componentOf(
      well,
      type,
    ).copyWith(systemStatus: 'DISPONIBLE');
  }

  void mountDirectly(MechanicWell well, _EquipmentType type) {
    final key = _ComponentKey(well.sector, well.well, type);
    _overrides[key] = componentOf(
      well,
      type,
    ).copyWith(systemStatus: 'MONTADO');
  }

  void mount(
    MechanicWell target,
    _EquipmentType targetType,
    _AvailableEquipment selected,
  ) {
    final targetKey = _ComponentKey(target.sector, target.well, targetType);
    _overrides[targetKey] = selected.component.copyWith(
      systemStatus: 'MONTADO',
    );
    if (selected.source != targetKey) {
      _overrides[selected.source] = const MechanicComponent.empty();
    }
  }
}

class MechanicSectorsPage extends StatelessWidget {
  const MechanicSectorsPage({super.key});

  @override
  Widget build(BuildContext context) => _MechanicFrame(
    child: Padding(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 24 : 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: 'Salir / Cerrar sesión',
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const Login()),
                    (_) => false,
                  ),
                  icon: const Icon(Icons.logout_rounded, color: _blue, size: 24),
                  style: IconButton.styleFrom(
                    side: const BorderSide(color: _line),
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ),
              const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Consulta mecánica',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _navy,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Seleccione un sector para consultar sus pozos',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _muted, fontSize: 17),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 34),
          Expanded(
            child: GridView.builder(
              itemCount: GoogleSheetsService.mechanicSectors.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.sizeOf(context).width < 600 ? 1 : 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: MediaQuery.sizeOf(context).width < 600
                    ? 3.3
                    : 2.8,
              ),
              itemBuilder: (context, index) {
                final sector = GoogleSheetsService.mechanicSectors[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MechanicWellsPage(sector: sector),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: const Color(0xfff6f9ff),
                      border: Border.all(color: _line),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: const Color(0xffe4eeff),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.location_on_outlined,
                            color: _blue,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Text(
                            sector,
                            style: const TextStyle(
                              color: _navy,
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: _muted),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );

  /* Moved to _MechanicWellsPageState. Kept here temporarily as reference.
  Future<void> _showWellEditor(MechanicWell well) async {
    final current = _changes.apply(well);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                well.well,
                style: const TextStyle(
                  color: _navy,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text('Seleccione el cambio de equipo.', style: TextStyle(color: _muted)),
              const SizedBox(height: 16),
              _equipmentAction(
                sheetContext,
                well,
                _EquipmentType.gearReducer,
                current.gearReducer,
              ),
              const SizedBox(height: 10),
              _equipmentAction(
                sheetContext,
                well,
                _EquipmentType.electricMotor,
                current.electricMotor,
              ),
            ],
          ),
        ),
      ),
    );
  }  Widget _equipmentAction(
    BuildContext sheetContext,
    MechanicWell well,
    _EquipmentType type,
    MechanicComponent component,
  ) {
    final name = type == _EquipmentType.gearReducer
        ? 'Motoreductor'
        : 'Motor eléctrico';
    final isMounted = component.isMounted;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: _navy, fontWeight: FontWeight.w800)),
                Text(
                  'Estado: ${component.systemStatus.isEmpty ? 'SIN EQUIPO' : component.systemStatus}',
                  style: const TextStyle(color: _muted, fontSize: 13),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(sheetContext);
              if (isMounted) {
                _dismountEquipment(well, type);
              } else {
                _mountEquipmentDirectly(well, type);
              }
            },
            icon: Icon(isMounted ? Icons.unarchive_outlined : Icons.build_circle_outlined),
            label: Text(isMounted ? 'Desmontar' : 'Montar'),
          ),
        ],
      ),
    );
  }

  Future<void> _dismountEquipment(MechanicWell well, _EquipmentType type) async {
    final equipmentParam = type == _EquipmentType.gearReducer ? 'gearReducer' : 'electricMotor';
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Guardando cambio en Google Sheets...')),
        );
      }
      await _service.dismountMechanicEquipment(
        sector: well.sector,
        well: well.well,
        equipment: equipmentParam,
      );
      _changes.dismount(well, type);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Equipo desmontado y guardado en Google Sheets.')),
        );
        setState(() => _future = _service.loadMechanicWells(widget.sector));
      }
    } catch (e) {
      _changes.dismount(well, type);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Actualizado localmente en el dispositivo.')),
        );
      }
    }
  Future<void> _mountEquipmentDirectly(MechanicWell well, _EquipmentType type) async {
    final equipmentParam = type == _EquipmentType.gearReducer ? 'gearReducer' : 'electricMotor';
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Guardando montaje en Google Sheets...')),
        );
      }
      await _service.mountMechanicEquipment(
        targetSector: well.sector,
        targetWell: well.well,
        sourceSector: well.sector,
        sourceWell: well.well,
        equipment: equipmentParam,
      );
      _changes.mountDirectly(well, type);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Equipo montado y guardado en Google Sheets.')),
        );
        setState(() => _future = _service.loadMechanicWells(widget.sector));
      }
    } catch (e) {
      _changes.mountDirectly(well, type);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Actualizado localmente en el dispositivo.')),
        );
      }
    }
  }

  Future<void> _mountEquipment(
    MechanicWell target,
    _EquipmentType type,
    _AvailableEquipment selected,
  ) async {
    final equipmentParam = type == _EquipmentType.gearReducer ? 'gearReducer' : 'electricMotor';
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Guardando montaje en Google Sheets...')),
        );
      }
      await _service.mountMechanicEquipment(
        targetSector: target.sector,
        targetWell: target.well,
        sourceSector: selected.source.sector,
        sourceWell: selected.source.well,
        equipment: equipmentParam,
      );
      _changes.mount(target, type, selected);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Equipo montado y guardado en Google Sheets.')),
        );
        setState(() => _future = _service.loadMechanicWells(widget.sector));
      }
    } catch (e) {
      _changes.mount(target, type, selected);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Actualizado localmente en el dispositivo.')),
        );
      }
    }
  }

  Future<List<_AvailableEquipment>> _availableEquipment(
    MechanicWell target,
    _EquipmentType type,
  ) async {
    final targetComponent = type == _EquipmentType.gearReducer
        ? target.gearReducer
        : target.electricMotor;
    final material = _searchKey(targetComponent.material);
    if (material.isEmpty) return [];
    final sectors = await Future.wait(
      GoogleSheetsService.mechanicSectors.map(_service.loadMechanicWells),
    );
    final available = <_AvailableEquipment>[];
    for (final wells in sectors) {
      for (final well in wells) {
        final component = _changes.componentOf(well, type);
        if (component.isAvailable && _searchKey(component.material) == material) {
          available.add(
            _AvailableEquipment(
              source: _ComponentKey(well.sector, well.well, type),
              component: component,
            ),
          );
        }
      }
    }
    return available;
  }

  Future<void> _showAvailableEquipment(
    MechanicWell target,
    _EquipmentType type,
  ) async {
    final title = type == _EquipmentType.gearReducer
        ? 'Motoreductores disponibles'
        : 'Motores eléctricos disponibles';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * .62,
          child: FutureBuilder<List<_AvailableEquipment>>(
            future: _availableEquipment(target, type),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final options = snapshot.data ?? [];
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
                    child: Text(title, style: const TextStyle(color: _navy, fontSize: 21, fontWeight: FontWeight.w800)),
                  ),
                  Expanded(
                    child: options.isEmpty
                        ? const Center(
                            child: Text(
                              'No hay equipos disponibles con el mismo número de material.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: _muted),
                            ),
                          )
                        : ListView.separated(
                            itemCount: options.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final option = options[index];
                              return ListTile(
                                leading: const Icon(Icons.inventory_2_outlined, color: _blue),
                                title: Text('${option.source.sector} · ${option.source.well}'),
                                subtitle: Text('Material ${option.component.material}\nSerie ${option.component.serial}'),
                                isThreeLine: true,
                                onTap: () {
                                  Navigator.pop(sheetContext);
                                  _mountEquipment(target, type, option);
                                },
                              );
                            },
                          ),
                  ),
                ],
              );
            },
        ),
      ),
    );
  }
  }
}
*/
}

class MechanicWellsPage extends StatefulWidget {
  final String sector;
  const MechanicWellsPage({super.key, required this.sector});

  @override
  State<MechanicWellsPage> createState() => _MechanicWellsPageState();
}

class _MechanicWellsPageState extends State<MechanicWellsPage> {
  final _service = GoogleSheetsService();
  final _changes = _MechanicChanges.instance;
  final _search = TextEditingController();
  late Future<List<MechanicWell>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.loadMechanicWells(widget.sector);
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _MechanicFrame(
    child: FutureBuilder<List<MechanicWell>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _LoadError(
            onRetry: () => setState(
              () => _future = _service.loadMechanicWells(widget.sector),
            ),
          );
        }
        final query = _searchKey(_search.text);
        final sourceWells = (snapshot.data ?? [])
            .where(
              (well) => query.isEmpty || _searchKey(well.well).contains(query),
            )
            .toList();
        final wells = sourceWells.map(_changes.apply).toList();
        final compact = MediaQuery.sizeOf(context).width < 600;
        return LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = !compact && constraints.maxWidth >= 760;
            final horizontalPadding = compact ? 20.0 : 38.0;
            return RefreshIndicator(
              onRefresh: () async => setState(
                () => _future = _service.loadMechanicWells(widget.sector),
              ),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      24,
                      horizontalPadding,
                      12,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                tooltip: 'Regresar a sectores',
                                onPressed: () =>
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const MechanicSectorsPage(),
                                      ),
                                    ),
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: _blue,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  widget.sector,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: _navy,
                                    fontSize: 29,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 48),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _search,
                            decoration: InputDecoration(
                              hintText: 'Buscar pozo',
                              prefixIcon: const Icon(
                                Icons.search,
                                color: _muted,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: _line),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${wells.length} pozos encontrados',
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  if (wells.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          'No hay pozos para esta búsqueda.',
                          style: TextStyle(color: _muted),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        0,
                        horizontalPadding,
                        24,
                      ),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                           (context, index) => _WellCard(
                             wells[index],
                            onEdit: _service.inventoryEditingConfigured
                                ? () => _showWellEditor(sourceWells[index])
                                : null,
                          ),
                          childCount: wells.length,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: twoColumns ? 2 : 1,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          // En pantalla amplia los dos equipos van lado a
                          // lado debajo del nombre del pozo.
                          mainAxisExtent: compact ? 650 : 460,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    ),
  );

  void _showWellEditor(MechanicWell well) {
    final current = _changes.apply(well);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              well.well,
              style: const TextStyle(
                color: _navy,
                fontSize: 23,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            _editorAction(
              sheetContext,
              well,
              _EquipmentType.gearReducer,
              current.gearReducer,
            ),
            _editorAction(
              sheetContext,
              well,
              _EquipmentType.electricMotor,
              current.electricMotor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _editorAction(
    BuildContext sheetContext,
    MechanicWell well,
    _EquipmentType type,
    MechanicComponent component,
  ) {
    final name = type == _EquipmentType.gearReducer
        ? 'Motoreductor'
        : 'Motor eléctrico';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        name,
        style: const TextStyle(color: _navy, fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        'Estado: ${component.systemStatus.isEmpty ? 'SIN EQUIPO' : component.systemStatus}',
      ),
      trailing: TextButton(
        child: Text(component.isMounted ? 'Desmontar' : 'Montar'),
        onPressed: () async {
          Navigator.pop(sheetContext);
          try {
            if (component.isMounted) {
              await _service.dismountMechanicEquipment(
                sector: well.sector,
                well: well.well,
                equipment: type.name,
              );
              if (mounted) {
                setState(() => _changes.dismount(well, type));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Equipo desmontado.')),
                );
              }
            } else {
              await _service.mountMechanicEquipment(
                targetSector: well.sector,
                targetWell: well.well,
                sourceSector: well.sector,
                sourceWell: well.well,
                equipment: type.name,
              );
              if (mounted) {
                setState(() => _changes.mountDirectly(well, type));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Equipo montado.')),
                );
              }
            }
          } catch (error) {
            if (mounted) _showInventoryError(error);
          }
        },
      ),
    );
  }



  void _showInventoryError(Object error) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text('$error')));
}

class _WellCard extends StatelessWidget {
  final MechanicWell well;
  final VoidCallback? onEdit;
  const _WellCard(this.well, {required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            well.well,
            style: const TextStyle(
              color: _navy,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Flex(
              direction: compact ? Axis.vertical : Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _ComponentCard(
                    title: 'Motoreductor',
                    icon: Icons.settings,
                    color: const Color(0xff147d9b),
                    component: well.gearReducer,
                  ),
                ),
                SizedBox(width: compact ? 0 : 14, height: compact ? 14 : 0),
                Expanded(
                  child: _ComponentCard(
                    title: 'Motor eléctrico',
                    icon: Icons.electric_bolt_outlined,
                    color: const Color(0xff5c6f9b),
                    component: well.electricMotor,
                  ),
                ),
              ],
            ),
          ),
          if (onEdit != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar equipo'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _searchKey(String value) => value
    .trim()
    .toUpperCase()
    .replaceAll('Á', 'A')
    .replaceAll('É', 'E')
    .replaceAll('Í', 'I')
    .replaceAll('Ó', 'O')
    .replaceAll('Ú', 'U')
    .replaceAll('Ñ', 'N')
    .replaceAll(RegExp(r'[^A-Z0-9]+'), '');

class _ComponentCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final MechanicComponent component;
  const _ComponentCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.component,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .06),
      border: Border.all(color: color.withValues(alpha: .28)),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const Divider(height: 18, color: _line),
        Text(
          'STATUS SISTEMA',
          style: const TextStyle(
            color: _muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Container(
          margin: const EdgeInsets.only(bottom: 5),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: component.isMounted
                ? const Color(0xffdaf5e6)
                : const Color(0xfffff0cd),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            component.systemStatus.isEmpty
                ? 'SIN EQUIPO'
                : component.systemStatus,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _value('No. material', component.material),
        _value('No. serie / SAP', component.serial),
        _value('Marca', component.maker),
        _value('HP', component.hp),
      ],
    ),
  );

  Widget _value(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: _muted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value.isEmpty ? 'Sin información' : value,
          style: const TextStyle(
            color: _navy,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _LoadError extends StatelessWidget {
  final VoidCallback onRetry;
  const _LoadError({required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cloud_off_outlined, color: _muted, size: 46),
        const SizedBox(height: 12),
        const Text(
          'No se pudieron cargar los datos publicados.',
          style: TextStyle(color: _muted),
        ),
        TextButton(onPressed: onRetry, child: const Text('Reintentar')),
      ],
    ),
  );
}

class _MechanicFrame extends StatelessWidget {
  final Widget child;
  const _MechanicFrame({required this.child});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xfff7faff),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1160),
          child: Container(
            margin: EdgeInsets.all(
              MediaQuery.sizeOf(context).width < 600 ? 0 : 16,
            ),
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.sizeOf(context).height -
                  (MediaQuery.sizeOf(context).width < 600 ? 0 : 32),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: _line),
              borderRadius: BorderRadius.circular(
                MediaQuery.sizeOf(context).width < 600 ? 0 : 36,
              ),
            ),
            child: child,
          ),
        ),
      ),
    ),
  );
}
