import 'package:flutter/material.dart';
import 'data_list_page.dart';
import 'mechanic_sectors_page.dart';
import 'models/app_user.dart';
import 'services/google_sheets_service.dart';

const navy = Color(0xff061b4d),
    blue = Color(0xff0867f9),
    muted = Color(0xff5c6f9b),
    line = Color(0xffdce5f3);
void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext c) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Seicontrol',
    theme: ThemeData(
      useMaterial3: true,
      fontFamily: 'Arial',
      scaffoldBackgroundColor: const Color(0xfff7faff),
    ),
    home: const Login(),
  );
}

class Shell extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const Shell({super.key, required this.child, this.maxWidth = 1100});
  @override
  Widget build(BuildContext c) => LayoutBuilder(
    builder: (_, constraints) {
      final compact = constraints.maxWidth < 600;
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Container(
                margin: EdgeInsets.all(compact ? 0 : 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(compact ? 0 : 28),
                  border: Border.all(color: line),
                  boxShadow: const [
                    BoxShadow(color: Color(0x120c3778), blurRadius: 24, offset: Offset(0, 8)),
                  ],
                ),
                child: child,
              ),
            ),
          ),
        ),
      );
    },
  );
}

class Brand extends StatelessWidget {
  final bool emphasized;
  const Brand({super.key, this.emphasized = false});
  @override
  Widget build(BuildContext c) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        'Seicontrol',
        style: TextStyle(
          color: navy,
          fontSize: emphasized ? 42 : 32,
          fontWeight: FontWeight.w800,
          height: 1.1,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'Base de datos de equipos',
        style: TextStyle(color: muted, fontSize: emphasized ? 18 : 15, fontWeight: FontWeight.w500),
      ),
    ],
  );
}

class Login extends StatefulWidget {
  const Login({super.key});
  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final user = TextEditingController();
  final password = TextEditingController();
  final _sheets = GoogleSheetsService();
  bool hide = true;
  bool _isLoggingIn = false;

  @override
  void dispose() {
    user.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (user.text.trim().isEmpty || password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa tu usuario y contraseña.')),
      );
      return;
    }
    setState(() => _isLoggingIn = true);
    try {
      final accounts = await _sheets.loadUsers();
      final AppUser? account = accounts.cast<AppUser?>().firstWhere(
        (candidate) => candidate!.matches(user.text, password.text),
        orElse: () => null,
      );
      if (!mounted) return;
      if (account == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario o contraseña incorrectos.')),
        );
        return;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => account.isMechanic ? const Mechanic() : const Home(),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo validar el acceso. Intenta de nuevo.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  @override
  Widget build(BuildContext c) => Shell(
    maxWidth: 640,
    child: LayoutBuilder(
      builder: (_, constraints) {
        final compact = constraints.maxWidth < 600;
        final horizontalPadding = compact ? 24.0 : 44.0;
        final imageHeight = compact ? 220.0 : 270.0;
        return Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: compact ? 24 : 36,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Brand(emphasized: true),
                  SizedBox(height: compact ? 16 : 22),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: imageHeight),
                    child: Image.asset(
                      'assets/images/psv.jpg',
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: compact ? 20 : 26),
                  Field('USUARIO', Icons.person_outline, user),
                  const SizedBox(height: 14),
                  Field(
                    'CONTRASEÑA',
                    Icons.lock_outline,
                    password,
                    hide: hide,
                    suffix: IconButton(
                      iconSize: 22,
                      icon: Icon(
                        hide
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(() => hide = !hide),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _isLoggingIn ? null : _login,
                      icon: _isLoggingIn
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.login, size: 22),
                      label: Text(
                        _isLoggingIn ? 'Validando...' : 'Ingresar',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        c,
                        MaterialPageRoute(builder: (_) => const Mechanic()),
                      ),
                      icon: const Icon(Icons.build_outlined, size: 20),
                      label: const Text(
                        'Acceso de prueba: Mecánico',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: blue,
                        side: const BorderSide(color: blue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      '¿Olvidaste tu contraseña?',
                      style: TextStyle(color: muted, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

class Field extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController? control;
  final bool hide;
  final Widget? suffix;
  const Field(
    this.label,
    this.icon,
    this.control, {
    super.key,
    this.hide = false,
    this.suffix,
  });
  @override
  Widget build(BuildContext c) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xffeaf2ff),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: blue, size: 20),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: navy,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: .3,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xffccd9ef)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0d0c3778),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: control,
          obscureText: hide,
          style: const TextStyle(
            color: navy,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: label == 'USUARIO'
                ? 'Ingresa tu usuario'
                : 'Ingresa tu contraseña',
            hintStyle: const TextStyle(color: Color(0xff9aa9c3), fontSize: 15),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 8, right: 10),
              child: Icon(icon, color: const Color(0xff7591bf), size: 22),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 46),
            suffixIcon: suffix == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: suffix,
                  ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    ],
  );
}

class Header extends StatelessWidget {
  final bool back;
  const Header({super.key, this.back = false});

  void _openMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * .42,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 6, 24, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Menú',
                  style: TextStyle(
                    color: navy,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xfff5f8ff),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: Color(0xffe3edff),
                      child: Icon(Icons.person_outline, color: blue, size: 27),
                    ),
                    title: Text(
                      'Sesión activa',
                      style: TextStyle(
                        color: navy,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      'Consulta y gestión de equipos',
                      style: TextStyle(color: muted, fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  minVerticalPadding: 14,
                  leading: const Icon(Icons.notifications_none, color: blue),
                  title: const Text('Notificaciones'),
                  trailing: const Icon(Icons.chevron_right, color: muted),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showNotifications(context);
                  },
                ),
                const Divider(color: line),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  minVerticalPadding: 14,
                  leading: const Icon(Icons.logout, color: blue),
                  title: const Text('Cerrar sesión'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const Login()),
                      (_) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.notifications_none, color: blue, size: 34),
        title: const Text('Notificaciones'),
        content: const Text('No tienes notificaciones pendientes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext c) => Stack(
    alignment: Alignment.center,
    children: [
      Align(
        alignment: Alignment.centerLeft,
        child: back
            ? IconButton(
                onPressed: () => Navigator.pop(c),
                icon: const Icon(Icons.arrow_back, color: blue),
                style: IconButton.styleFrom(
                  side: const BorderSide(color: line),
                ),
              )
            : IconButton(
                tooltip: 'Menú',
                onPressed: () => _openMenu(c),
                icon: const Icon(Icons.menu, color: blue, size: 34),
              ),
      ),
      const Brand(),
      if (!back)
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            tooltip: 'Notificaciones',
            onPressed: () => _showNotifications(c),
            icon: const Icon(Icons.notifications_none, color: muted, size: 32),
          ),
        ),
    ],
  );
}

class Home extends StatelessWidget {
  const Home({super.key});
  @override
  Widget build(BuildContext c) => Shell(
    child: LayoutBuilder(
      builder: (_, constraints) {
        final compact = constraints.maxWidth < 600;
        final padding = EdgeInsets.symmetric(
          horizontal: compact ? 24 : 58,
          vertical: compact ? 30 : 42,
        );
        const modules = [
          Module(' PSV', 'PSV'),
          Module(' VE', 'VE'),
          Module(' VPV', 'VPV'),
          Module(' VRV', 'VRV'),
        ];

        if (compact) {
          return SingleChildScrollView(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Header(),
                const SizedBox(height: 46),
                const _HomeTitle(),
                const SizedBox(height: 28),
                GridView.count(
                  crossAxisCount: 1,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 20,
                  childAspectRatio: 1.16,
                  children: modules,
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        }

        return Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Header(),
              const SizedBox(height: 42),
              const _HomeTitle(),
              const SizedBox(height: 26),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: LayoutBuilder(
                      builder: (_, grid) {
                        final cellWidth = (grid.maxWidth - 28) / 2;
                        final cellHeight = (grid.maxHeight - 24) / 2;
                        return GridView.count(
                          crossAxisCount: 2,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 24,
                          crossAxisSpacing: 28,
                          childAspectRatio: cellWidth / cellHeight,
                          children: modules,
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const _HomeStationSearch(),
            ],
          ),
        );
      },
    ),
  );
}

class _HomeStationSearch extends StatefulWidget {
  const _HomeStationSearch();

  @override
  State<_HomeStationSearch> createState() => _HomeStationSearchState();
}

class _HomeStationSearchState extends State<_HomeStationSearch> {
  final _service = GoogleSheetsService();
  String _selectedStation = '';
  List<String> _stations = [];

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  Future<void> _loadStations() async {
    try {
      final data = await _service.load();
      final set = data
          .map((e) => e.location.trim())
          .where((l) => l.isNotEmpty)
          .toSet();
      if (mounted) {
        setState(() {
          _stations = set.toList()..sort();
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final count = _stations.isEmpty ? 28 : _stations.length;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xff7c4dff), width: 1.8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedStation.isEmpty ? null : _selectedStation,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xff555555)),
          hint: Row(
            children: [
              const Icon(Icons.location_on_outlined, color: blue, size: 22),
              const SizedBox(width: 12),
              Text(
                'Todas las estaciones ($count)',
                style: const TextStyle(
                  color: Color(0xff666666),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          items: [
            DropdownMenuItem(
              value: '',
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, color: blue, size: 22),
                  const SizedBox(width: 12),
                  Text('Todas las estaciones ($count)'),
                ],
              ),
            ),
            ..._stations.map(
              (s) => DropdownMenuItem(
                value: s,
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: blue,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(s),
                  ],
                ),
              ),
            ),
          ],
          onChanged: (v) {
            final station = v ?? '';
            setState(() => _selectedStation = station);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DataListPage('TODOS', initialStation: station),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HomeTitle extends StatelessWidget {
  const _HomeTitle();

  @override
  Widget build(BuildContext c) => const Text(
    'Levantamiento físico y ubicación de:',
    style: TextStyle(color: navy, fontWeight: FontWeight.w800, fontSize: 32),
  );
}

class Module extends StatelessWidget {
  final String label, type;
  const Module(this.label, this.type, {super.key});
  String get image => switch (type) {
    'PSV' => 'assets/images/psv.jpg',
    'VE' => 'assets/images/ve.png',
    'VPV' => 'assets/images/vpv.png',
    _ => 'assets/images/vrv.png',
  };
  @override
  Widget build(BuildContext c) => InkWell(
    onTap: () => Navigator.push(
      c,
      MaterialPageRoute(builder: (_) => DataListPage(type)),
    ),
    borderRadius: BorderRadius.circular(28),
    child: Container(
      decoration: BoxDecoration(
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Image.asset(image, fit: BoxFit.contain),
                ),
              ),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: navy,
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}

class Mechanic extends MechanicSectorsPage {
  const Mechanic({super.key});
}

class ComponentPendingPage extends StatelessWidget {
  final String component;
  final IconData icon;
  const ComponentPendingPage({
    super.key,
    required this.component,
    required this.icon,
  });

  @override
  Widget build(BuildContext c) => Shell(
    child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Column(
        children: [
          const Header(back: true),
          const SizedBox(height: 70),
          Container(
            width: 112,
            height: 112,
            decoration: const BoxDecoration(
              color: Color(0xffeaf2ff),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 56, color: blue),
          ),
          const SizedBox(height: 28),
          Text(
            component,
            style: const TextStyle(
              color: navy,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Información en proceso',
            style: TextStyle(
              color: navy,
              fontSize: 23,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Aún no hay información disponible para este componente.\n'
            'Estamos preparando su base de datos.',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontSize: 18, height: 1.5),
          ),
          const SizedBox(height: 34),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(c),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Volver a componentes'),
          ),
        ],
      ),
    ),
  );
}

class User extends StatelessWidget {
  final String role;
  const User({super.key, required this.role});
  @override
  Widget build(BuildContext c) => Container(
    margin: const EdgeInsets.only(top: 22),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      border: Border.all(color: line),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      children: [
        const CircleAvatar(
          radius: 27,
          backgroundColor: Color(0xffe8f1ff),
          child: Icon(Icons.person_outline, color: blue, size: 34),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Usuario',
                style: TextStyle(
                  color: navy,
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(role, style: const TextStyle(color: muted, fontSize: 18)),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: () => Navigator.pushAndRemoveUntil(
            c,
            MaterialPageRoute(builder: (_) => const Login()),
            (_) => false,
          ),
          icon: const Icon(Icons.logout, color: blue),
          label: const Text(
            'Cerrar sesión',
            style: TextStyle(color: blue, fontSize: 20),
          ),
        ),
      ],
    ),
  );
}

class ListPage extends StatefulWidget {
  final String type;
  const ListPage(this.type, {super.key});
  @override
  State<ListPage> createState() => _ListState();
}

class _ListState extends State<ListPage> {
  String selected = 'Todos';
  @override
  Widget build(BuildContext c) {
    final sub = {
      'PSV': 'Válvulas de Seguridad',
      'VE': 'Ventila de Emergencia',
      'VPV': 'Válvulas de Presión-Vacío',
      'VRV': 'Válvulas Rompedora de Vacio',
    }[widget.type]!;
    return Shell(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(38, 28, 38, 0),
            child: Column(
              children: [
                const Header(back: true),
                Text(
                  widget.type,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(sub, style: const TextStyle(color: muted, fontSize: 18)),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Buscar por Serie, Fabricante...',
                          prefixIcon: const Icon(Icons.search, color: muted),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: line),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.tune, color: blue),
                      style: IconButton.styleFrom(
                        side: const BorderSide(color: line),
                        minimumSize: const Size(60, 60),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 14,
                  children: ['Todos', 'Montados', 'Disponibles', 'Vencidos']
                      .map(
                        (x) => ChoiceChip(
                          label: Text(x),
                          selected: selected == x,
                          onSelected: (_) => setState(() => selected = x),
                          selectedColor: blue,
                          labelStyle: TextStyle(
                            color: selected == x ? Colors.white : muted,
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                const Station(),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(38, 0, 38, 22),
              itemCount: 6,
              separatorBuilder: (_, index) => const SizedBox(height: 13),
              itemBuilder: (_, i) => CardRow(type: widget.type, i: i),
            ),
          ),
        ],
      ),
    );
  }
}

class Station extends StatelessWidget {
  const Station({super.key});
  @override
  Widget build(BuildContext c) => Container(
    height: 68,
    padding: const EdgeInsets.symmetric(horizontal: 18),
    decoration: BoxDecoration(
      border: Border.all(color: line),
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Row(
      children: [
        Icon(Icons.location_on_outlined, color: blue),
        SizedBox(width: 16),
        Text(
          'Todas las estaciones',
          style: TextStyle(color: muted, fontSize: 19),
        ),
        Spacer(),
        Icon(Icons.keyboard_arrow_down, color: muted),
      ],
    ),
  );
}

class CardRow extends StatelessWidget {
  final String type;
  final int i;
  const CardRow({super.key, required this.type, required this.i});
  @override
  Widget build(BuildContext c) {
    final serial = type == 'PSV'
        ? '1000${2933 + i * 89}'
        : type == 'VRV'
        ? 'VRV-00${i + 2}'
        : type == 'VE'
        ? 'VEM0${32 + i}'
        : 'VA0${66 + i}';
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              d('EQUIPO', '1000${6207 + i}'),
              const Spacer(),
              d('N° SERIE', serial),
              const SizedBox(width: 18),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  tag(
                    i == 0
                        ? 'MONTADA'
                        : i == 1
                        ? 'ÁREA'
                        : 'DISP',
                    Colors.green,
                  ),
                  const SizedBox(height: 5),
                  tag('SIN FECHA', Colors.orange),
                ],
              ),
            ],
          ),
          const Divider(height: 24, color: line),
          Wrap(
            spacing: 28,
            runSpacing: 10,
            children: [
              d('FABRICANTE', type == 'PSV' ? 'VARESA' : 'DOMINICIS'),
              d('MATERIAL', type == 'PSV' ? '11001589' : '11002950'),
              d(
                'ÚLTIMA CALIBRACIÓN',
                'Pendiente',
                Icons.calendar_month_outlined,
              ),
              d(
                'UBICACIÓN ACTUAL',
                i < 2 ? '${i + 1} SABALO' : 'Sin ubicación',
                Icons.location_on_outlined,
                Colors.deepOrange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget d(String a, String b, [IconData? icon, Color? color]) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        a,
        style: const TextStyle(
          color: muted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 6),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: color ?? muted),
            const SizedBox(width: 6),
          ],
          Text(
            b,
            style: TextStyle(
              color: color ?? navy,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ],
  );
  Widget tag(String t, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
      border: Border.all(color: color.withValues(alpha: .6)),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      t,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
    ),
  );
}
