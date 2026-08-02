import 'dart:convert';

import 'package:http/http.dart' as http;
import '../models/app_user.dart';
import '../models/equipment.dart';
import '../models/mechanic_well.dart';

class GoogleSheetsService {
  static const mechanicSectors = [
    'Escudo Nacional',
    'Flores',
    'Corcovado',
    'D17',
    'Marland',
  ];
  static const _mechanicGids = {
    'Escudo Nacional': '578846757',
    'Flores': '1391752178',
    'Corcovado': '775837081',
    'D17': '1945532329',
    'Marland': '870275353',
  };
  static const _mechanicBaseUrl =
      'https://docs.google.com/spreadsheets/d/e/2PACX-1vSIcH6hYyoMiii2kEJOJb426XhJGOmI9tE7Nhur58RAmcDjLXJ6MnONnyRyIheV-RiaoP6mzr1B9hVh/pub?single=true&output=csv&gid=';
  static const _equipmentUrl =
      'https://docs.google.com/spreadsheets/d/e/2PACX-1vTZ1bBr_yf6hDi737g3dt7ct6ZyRNqjRy0jrIBefkPkIgtUyaIJoqOBlwZfRl0Scz4Gx3EKwjviqxBZ/pub?single=true&output=csv&gid=0';
  static const _usersUrl =
      'https://docs.google.com/spreadsheets/d/e/2PACX-1vTZ1bBr_yf6hDi737g3dt7ct6ZyRNqjRy0jrIBefkPkIgtUyaIJoqOBlwZfRl0Scz4Gx3EKwjviqxBZ/pub?single=true&output=csv&gid=1447319480';
  // API de mecánicos (motor reductor / motor eléctrico)
  static const _inventoryApiUrl = String.fromEnvironment(
    'SEI_INVENTORY_API_URL',
    defaultValue:
        'https://script.google.com/macros/s/AKfycbweoUVEVhlyORwQj_pLMihQPSyVEiCXkuRP9PHP3sHHoqojDnJm8cDmBoZJT7i5NpW0Rg/exec',
  );
  // API de PSV / válvulas (updateEquipment)
  static const _psvApiUrl = String.fromEnvironment(
    'SEI_PSV_API_URL',
    defaultValue:
        'https://script.google.com/macros/s/AKfycbweDqRODBhlfTtC_3M4Hnd9FuiMYGt1FL5ysqZVgTFPQ8y-9JNjRKa6sZqlSx7sgiIBGA/exec',
  );
  static const _inventoryApiToken = String.fromEnvironment(
    'SEI_INVENTORY_API_TOKEN',
    defaultValue: 'SEI-2026-7fK9mQ2xL8vR4nP6aT1wZ5cD',
  );

  bool get inventoryEditingConfigured => _inventoryApiToken.isNotEmpty;

  /// Updates editable fields of an equipment row in the Google Sheet.
  /// Fields: [status], [location] (estación), [installedAt], [calibration].
  Future<void> updateEquipment({
    required String serial,
    required String type,
    required String status,
    required String location,
    required String installedAt,
    required String calibration,
  }) => _postPsvApi({
    'action': 'updateEquipment',
    'serial': serial,
    'type': type,
    'status': status,
    'location': location,
    'installedAt': installedAt,
    'calibration': calibration,
  });

  /// Returns equipment that is DISPONIBLE (in systemStatus), then matching [material],
  /// excluding the item with [excludeSerial].
  Future<List<Equipment>> loadAvailableByMaterial({
    required String type,
    required String material,
    required String excludeSerial,
    Map<String, Equipment>? localOverrides,
  }) async {
    final rawAll = await load();
    final all = rawAll.map((e) {
      final key = e.serial.trim().toUpperCase();
      if (localOverrides != null && localOverrides.containsKey(key)) {
        return localOverrides[key]!;
      }
      return e;
    }).toList();

    // Si hay overrides locales de equipos disponibles que no estaban en la hoja aún, los agregamos
    if (localOverrides != null) {
      for (final override in localOverrides.values) {
        if (!all.any((e) => e.serial.trim().toUpperCase() == override.serial.trim().toUpperCase())) {
          all.add(override);
        }
      }
    }

    return all.where((e) {
      // 1. Debe estar DISPONIBLE en STATUS SISTEMA
      if (!e.isAvailable) {
        return false;
      }
      // 2. Excluir el equipo actual desinstalado
      if (e.serial.trim().toUpperCase() == excludeSerial.trim().toUpperCase()) {
        return false;
      }
      // 3. Coincidir con tipo de válvula
      if (type.trim().isNotEmpty &&
          e.type.trim().toUpperCase() != type.trim().toUpperCase()) {
        return false;
      }
      // 4. Coincidir con número de material
      if (material.trim().isNotEmpty &&
          e.material.trim().toUpperCase() != material.trim().toUpperCase()) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Loads unique values from "INSTALADO EN" column in Google Sheet
  Future<List<String>> loadInstalledAtOptions() async {
    try {
      final all = await load();
      final set = all
          .map((e) => e.installedAt.trim())
          .where((s) => s.isNotEmpty)
          .toSet();
      final list = set.toList()..sort();
      return list;
    } catch (_) {
      return [];
    }
  }

  /// Loads unique values from "UBICACION TECNICA" column in Google Sheet
  Future<List<String>> loadLocations() async {
    try {
      final all = await load();
      final set = all
          .map((e) => e.location.trim())
          .where((s) => s.isNotEmpty)
          .toSet();
      final list = set.toList()..sort();
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<void> dismountMechanicEquipment({
    required String sector,
    required String well,
    required String equipment,
  }) => _postInventoryApi({
    'action': 'dismount',
    'sector': sector,
    'well': well,
    'equipment': equipment,
  });

  Future<void> mountMechanicEquipment({
    required String targetSector,
    required String targetWell,
    required String sourceSector,
    required String sourceWell,
    required String equipment,
  }) => _postInventoryApi({
    'action': 'mount',
    'targetSector': targetSector,
    'targetWell': targetWell,
    'sourceSector': sourceSector,
    'sourceWell': sourceWell,
    'equipment': equipment,
  });

  Future<List<AvailableMechanicEquipment>> loadAvailableMechanicEquipment({
    required String equipment,
    required String material,
  }) async {
    final data = await _postInventoryApi({
      'action': 'available',
      'equipment': equipment,
      'material': material,
    });
    if (data is! List) return [];
    return data.whereType<Map>().map((item) {
      final map = Map<String, dynamic>.from(item);
      return AvailableMechanicEquipment(
        sector: '${map['sector'] ?? ''}',
        well: '${map['well'] ?? ''}',
        component: _componentFromApi(map),
      );
    }).toList();
  }

  Future<dynamic> _postInventoryApi(Map<String, String> payload) async {
    _requireInventoryToken();
    final fullPayload = {...payload, 'token': _inventoryApiToken};
    try {
      final response = await http.post(
        Uri.parse(_inventoryApiUrl),
        headers: const {'Content-Type': 'text/plain'},
        body: jsonEncode(fullPayload),
      );
      return _readInventoryResponse(response);
    } catch (_) {
      final getUri = Uri.parse(_inventoryApiUrl).replace(queryParameters: fullPayload);
      final getResponse = await http.get(getUri);
      return _readInventoryResponse(getResponse);
    }
  }

  Future<dynamic> _postPsvApi(Map<String, String> payload) async {
    _requireInventoryToken();
    final fullPayload = {...payload, 'token': _inventoryApiToken};
    try {
      final response = await http.post(
        Uri.parse(_psvApiUrl),
        headers: const {'Content-Type': 'text/plain'},
        body: jsonEncode(fullPayload),
      );
      return _readInventoryResponse(response);
    } catch (_) {
      final getUri = Uri.parse(_psvApiUrl).replace(queryParameters: fullPayload);
      final getResponse = await http.get(getUri);
      return _readInventoryResponse(getResponse);
    }
  }

  dynamic _readInventoryResponse(http.Response response) {
    if (response.statusCode != 200) {
      throw Exception('No se pudo comunicar con el inventario.');
    }
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is Map && data['error'] != null) {
      throw Exception('${data['error']}');
    }
    return data;
  }

  void _requireInventoryToken() {
    if (_inventoryApiToken.isEmpty) {
      throw StateError('Falta configurar la clave de edición de inventario.');
    }
  }

  MechanicComponent _componentFromApi(Map<String, dynamic> map) =>
      MechanicComponent(
        systemStatus: '${map['status'] ?? ''}',
        material: '${map['material'] ?? ''}',
        serial: '${map['serial'] ?? ''}',
        maker: '${map['maker'] ?? ''}',
        hp: '${map['hp'] ?? ''}',
      );

  MechanicWell _wellFromApi(Map<String, dynamic> map) {
    final gear = Map<String, dynamic>.from(map['gearReducer'] as Map);
    final motor = Map<String, dynamic>.from(map['electricMotor'] as Map);
    return MechanicWell(
      sector: '${map['sector'] ?? ''}',
      well: '${map['well'] ?? ''}',
      gearReducer: _componentFromApi(gear),
      electricMotor: _componentFromApi(motor),
    );
  }

  Future<List<Equipment>> load() async {
    final response = await http.get(Uri.parse(_equipmentUrl));
    if (response.statusCode != 200) {
      throw Exception('No se pudo consultar la hoja (${response.statusCode}).');
    }
    // Google Sheets may omit the charset in its CSV response. Decode the
    // bytes explicitly so accented headers such as "UBICACIÓN" are preserved.
    final rows = _parseCsv(utf8.decode(response.bodyBytes));
    if (rows.length < 2) return [];
    final headers = rows.first.map(_normaliseHeader).toList();
    String value(List<String> row, List<String> keys) {
      final i = _findHeader(headers, keys);
      return i >= 0 && i < row.length ? row[i].trim() : '';
    }

    return rows
        .skip(1)
        .where((r) => r.any((v) => v.trim().isNotEmpty))
        .map(
          (r) => Equipment(
            type: value(r, const ['TIPO']),
            material: value(r, const ['MATERIAL']),
            serial: value(r, const ['NUMERO DE SERIE', 'N SERIE']),
            id: value(r, const ['EQUIPO']),
            description: value(r, const [
              'DENOMINACION DE OBJETO',
              'DESCRIPCION',
            ]),
            systemStatus: value(r, const ['STATUS SISTEMA', 'ESTATUS SISTEMA']),
            location: value(r, const [
              'UBICACION TECNICA',
              'UBICACION TECNICA ACTUAL',
              'ESTACION',
            ]),
            maker: value(r, const ['FABRICANTE']),
            installedAt: value(r, const ['INSTALADO EN']),
            calibration: value(r, const ['FECHA CALIBRACION']),
            calibrationStatus: value(r, const ['ESTADO']),
          ),
        )
        .toList();
  }

  Future<List<MechanicWell>> loadMechanicWells(String sector) async {
    if (_inventoryApiToken.isNotEmpty) {
      try {
        final data = await _postInventoryApi({'action': 'snapshot'});
        if (data is List) {
          final apiWells = data
              .whereType<Map>()
              .map((item) => _wellFromApi(Map<String, dynamic>.from(item)))
              .where((well) => well.sector == sector)
              .toList();
          if (apiWells.isNotEmpty) {
            return apiWells;
          }
        }
      } catch (_) {
        // Browsers can block cross-origin Apps Script calls. Keep the
        // published list available for consultation in that case.
      }
    }
    final gid = _mechanicGids[sector];
    if (gid == null) throw ArgumentError('Sector no reconocido: $sector');
    final response = await http.get(Uri.parse('$_mechanicBaseUrl$gid'));
    if (response.statusCode != 200) {
      throw Exception('No se pudo consultar el sector ($sector).');
    }
    final rows = _parseCsv(utf8.decode(response.bodyBytes));
    var headerRow = rows.indexWhere(
      (row) => row.any(
        (cell) => _normaliseHeader(cell).replaceAll(' ', '') == 'POZO',
      ),
    );
    var wellIndex = -1;
    if (headerRow >= 0) {
      final headers = rows[headerRow].map(_normaliseHeader).toList();
      wellIndex = headers.indexWhere(
        (header) => header.replaceAll(' ', '') == 'POZO',
      );
    }
    // Respaldo para hojas publicadas que omiten o modifican la fila de
    // cabeceras: sus registros mantienen el formato Pozo + 8 campos.
    if (wellIndex < 0) {
      headerRow = -1;
      wellIndex = 1;
    }
    String at(List<String> row, int index) =>
        index < row.length ? row[index].trim() : '';

    // Después de "Pozo", ambas secciones incluyen primero el estatus del
    // sistema y luego los cuatro datos que mostramos. Algunas filas pueden
    // estar incompletas; el pozo debe seguir siendo visible y los campos que
    // falten se presentan como "Sin información" en la pantalla.
    return rows
        .skip(headerRow + 1)
        .where(
          (row) =>
              at(row, wellIndex).isNotEmpty &&
              _normaliseHeader(at(row, wellIndex)) != 'POZO',
        )
        .map(
          (row) => MechanicWell(
            sector: sector,
            well: at(row, wellIndex),
            gearReducer: MechanicComponent(
              systemStatus: at(row, wellIndex + 1),
              material: at(row, wellIndex + 2),
              serial: at(row, wellIndex + 3),
              maker: at(row, wellIndex + 4),
              hp: at(row, wellIndex + 5),
            ),
            electricMotor: MechanicComponent(
              systemStatus: at(row, wellIndex + 6),
              material: at(row, wellIndex + 7),
              serial: at(row, wellIndex + 8),
              maker: at(row, wellIndex + 9),
              hp: at(row, wellIndex + 10),
            ),
          ),
        )
        .toList();
  }

  /// Loads credentials from the published "usuarios" sheet.
  /// The current sheet has no header row, so the first two filled cells are
  /// treated as user and password. Header-based sheets are also supported.
  Future<List<AppUser>> loadUsers() async {
    final response = await http.get(Uri.parse(_usersUrl));
    if (response.statusCode != 200) {
      throw Exception('No se pudo consultar la hoja de usuarios.');
    }
    final rows = _parseCsv(
      utf8.decode(response.bodyBytes),
    ).where((row) => row.any((cell) => cell.trim().isNotEmpty)).toList();
    if (rows.isEmpty) return [];

    final headers = rows.first.map(_normaliseHeader).toList();
    final userIndex = _findHeader(headers, const [
      'USUARIO',
      'USER',
      'NOMBRE DE USUARIO',
    ]);
    final passwordIndex = _findHeader(headers, const [
      'CONTRASENA',
      'PASSWORD',
      'CLAVE',
    ]);
    final roleIndex = _findHeader(headers, const ['ROL', 'ROLE', 'PERFIL']);
    final hasHeaders = userIndex >= 0 && passwordIndex >= 0;
    final dataRows = hasHeaders ? rows.skip(1) : rows;

    return dataRows
        .map((row) {
          String at(int index) =>
              index >= 0 && index < row.length ? row[index].trim() : '';
          if (hasHeaders) {
            return AppUser(
              username: at(userIndex),
              password: at(passwordIndex),
              role: at(roleIndex),
            );
          }
          final values = row.where((cell) => cell.trim().isNotEmpty).toList();
          return AppUser(
            username: values.isNotEmpty ? values[0].trim() : '',
            password: values.length > 1 ? values[1].trim() : '',
            role: values.length > 2 ? values[2].trim() : '',
          );
        })
        .where(
          (account) =>
              account.username.isNotEmpty && account.password.isNotEmpty,
        )
        .toList();
  }

  String _normaliseHeader(String value) => value
      .trim()
      .toUpperCase()
      .replaceAll('\uFEFF', '')
      .replaceAll('Á', 'A')
      .replaceAll('É', 'E')
      .replaceAll('Í', 'I')
      .replaceAll('Ó', 'O')
      .replaceAll('Ú', 'U')
      .replaceAll('Ñ', 'N')
      .replaceAll(RegExp(r'[^A-Z0-9]+'), ' ')
      .trim();

  int _findHeader(List<String> headers, List<String> options) {
    for (final option in options) {
      final index = headers.indexOf(option);
      if (index >= 0) return index;
    }
    return -1;
  }

  List<List<String>> _parseCsv(String input) {
    final rows = <List<String>>[];
    var row = <String>[];
    var cell = StringBuffer();
    var quoted = false;
    for (var i = 0; i < input.length; i++) {
      final ch = input[i];
      if (ch == '"') {
        if (quoted && i + 1 < input.length && input[i + 1] == '"') {
          cell.write('"');
          i++;
        } else {
          quoted = !quoted;
        }
      } else if (ch == ',' && !quoted) {
        row.add(cell.toString());
        cell = StringBuffer();
      } else if ((ch == '\n' || ch == '\r') && !quoted) {
        if (ch == '\r' && i + 1 < input.length && input[i + 1] == '\n') i++;
        row.add(cell.toString());
        rows.add(row);
        row = <String>[];
        cell = StringBuffer();
      } else {
        cell.write(ch);
      }
    }
    if (cell.isNotEmpty || row.isNotEmpty) {
      row.add(cell.toString());
      rows.add(row);
    }
    return rows;
  }
}
