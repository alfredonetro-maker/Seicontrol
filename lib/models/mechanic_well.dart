class MechanicComponent {
  final String systemStatus;
  final String material;
  final String serial;
  final String maker;
  final String hp;

  const MechanicComponent({
    required this.systemStatus,
    required this.material,
    required this.serial,
    required this.maker,
    required this.hp,
  });

  const MechanicComponent.empty()
    : systemStatus = 'SIN EQUIPO',
      material = '',
      serial = '',
      maker = '',
      hp = '';

  bool get isMounted => systemStatus.trim().toUpperCase() == 'MONTADO';

  bool get isAvailable => systemStatus.trim().toUpperCase() == 'DISPONIBLE';

  MechanicComponent copyWith({String? systemStatus}) => MechanicComponent(
    systemStatus: systemStatus ?? this.systemStatus,
    material: material,
    serial: serial,
    maker: maker,
    hp: hp,
  );
}

class MechanicWell {
  final String sector;
  final String well;
  final MechanicComponent gearReducer;
  final MechanicComponent electricMotor;

  const MechanicWell({
    required this.sector,
    required this.well,
    required this.gearReducer,
    required this.electricMotor,
  });

  MechanicWell copyWith({
    MechanicComponent? gearReducer,
    MechanicComponent? electricMotor,
  }) => MechanicWell(
    sector: sector,
    well: well,
    gearReducer: gearReducer ?? this.gearReducer,
    electricMotor: electricMotor ?? this.electricMotor,
  );
}

class AvailableMechanicEquipment {
  final String sector;
  final String well;
  final MechanicComponent component;

  const AvailableMechanicEquipment({
    required this.sector,
    required this.well,
    required this.component,
  });
}
