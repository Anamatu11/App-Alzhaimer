import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class DatasetGeneralScreen extends StatefulWidget {
  const DatasetGeneralScreen({super.key});

  @override
  State<DatasetGeneralScreen> createState() =>
      _DatasetGeneralScreenState();
}

class _DatasetGeneralScreenState extends State<DatasetGeneralScreen> {
  // ── Filtros ──────────────────────────────────────────────────────────────
  DateTime _desdeDate = DateTime.now().subtract(const Duration(hours: 10));
  TimeOfDay _desdeTime = const TimeOfDay(hour: 8, minute: 0);
  DateTime _hastaDate = DateTime.now();
  TimeOfDay _hastaTime = const TimeOfDay(hour: 18, minute: 0);

  // Rango activo (se aplica al presionar el botón)
  late DateTime _filtroDesde;
  late DateTime _filtroHasta;

  // ── Paginación ────────────────────────────────────────────────────────────
  static const int _porPagina = 10;
  int _paginaActual = 1;

  // ── Datos ─────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _todasLecturas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _filtroDesde = _combinar(_desdeDate, _desdeTime);
    _filtroHasta = _combinar(_hastaDate, _hastaTime);
    _cargarLecturas();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  DateTime _combinar(DateTime fecha, TimeOfDay hora) => DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
        hora.hour,
        hora.minute,
      );

  String _formatFecha(DateTime dt) => DateFormat('dd/MM/yyyy').format(dt);
  String _formatHora(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  // ── Firebase ──────────────────────────────────────────────────────────────
  Future<void> _cargarLecturas() async {
  setState(() => _cargando = true);

  try {
    List<Map<String, dynamic>> todas = [];

    final pacientes =
        await FirebaseFirestore.instance.collection('usuarios').get();

    for (var paciente in pacientes.docs) {
      final nombre = paciente.data()['nombre'] ?? 'Paciente';

      final lecturas = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(paciente.id)
          .collection('lecturas')
          .orderBy('timestamp', descending: false)
          .get();

      for (var lectura in lecturas.docs) {
        final data = lectura.data();

        data['nombrePaciente'] = nombre;
        data['pacienteId'] = paciente.id;

        todas.add(data);
      }
    }

    setState(() {
      _todasLecturas = todas;
      _cargando = false;
    });
  } catch (e) {
    print("Error cargando dataset general: $e");

    setState(() {
      _cargando = false;
    });
  }
}
  //── Exportar Excel ──────────────────────────────────────────────────────────────
  Future<void> _exportarExcel() async {
  try {
    final excel = Excel.createExcel();
    final sheet = excel['Lecturas'];

    sheet.appendRow([
      TextCellValue('Fecha'),
      TextCellValue('Hora'),
      TextCellValue('Paciente'),
      TextCellValue('Actividad'),
      TextCellValue('BPM'),
      TextCellValue('SpO2'),
      TextCellValue('AX'),
      TextCellValue('AY'),
      TextCellValue('AZ'),
      TextCellValue('GX'),
      TextCellValue('GY'),
      TextCellValue('GZ'),
      TextCellValue('Lat'),
      TextCellValue('Lng'),
    ]);

    for (var data in _lecturasFiltradas) {
      final fechaHora =
          (data['timestamp'] as Timestamp?)?.toDate();

      sheet.appendRow([
        TextCellValue(
          fechaHora != null
              ? DateFormat('dd/MM/yyyy').format(fechaHora)
              : '',
        ),

        TextCellValue(
          fechaHora != null
              ? DateFormat('HH:mm:ss').format(fechaHora)
              : '',
        ),
        TextCellValue(
          data['nombrePaciente']?.toString() ?? '',
        ),

        TextCellValue(
          data['actividad']?.toString() ?? '',
        ),

        IntCellValue(data['bpm'] ?? 0),

        IntCellValue(data['spo2'] ?? 0),

        DoubleCellValue(
          (data['ax'] ?? 0).toDouble(),
        ),

        DoubleCellValue(
          (data['ay'] ?? 0).toDouble(),
        ),

        DoubleCellValue(
          (data['az'] ?? 0).toDouble(),
        ),

        DoubleCellValue(
          (data['gx'] ?? 0).toDouble(),
        ),

        DoubleCellValue(
          (data['gy'] ?? 0).toDouble(),
        ),

        DoubleCellValue(
          (data['gz'] ?? 0).toDouble(),
        ),

        DoubleCellValue(
          (data['lat'] ?? 0).toDouble(),
        ),

        DoubleCellValue(
          (data['lng'] ?? 0).toDouble(),
        ),
      ]);
    }

    final dir =
        await getApplicationDocumentsDirectory();

    final file = File(
      '${dir.path}/Historial_${'Dataset General'}.xlsx',
    );

    await file.writeAsBytes(
      excel.encode()!,
      flush: true,
    );

    await Share.shareXFiles(
      [XFile(file.path)],
      text:
          'Historial de lecturas de ${'Dataset General'}',
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Error exportando Excel: $e',
        ),
      ),
    );
  }
}

  // ── Filtrado ──────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> get _lecturasFiltradas {
    return _todasLecturas.where((data) {
      try {
        final ts = (data['timestamp'] as Timestamp).toDate();
        return ts.isAfter(_filtroDesde.subtract(const Duration(seconds: 1))) &&
            ts.isBefore(_filtroHasta.add(const Duration(seconds: 1)));
      } catch (_) {
        return false;
      }
    }).toList();
  }

  List<Map<String, dynamic>> get _paginaActualItems {
    final filtradas = _lecturasFiltradas;
    final inicio = (_paginaActual - 1) * _porPagina;
    final fin = (inicio + _porPagina).clamp(0, filtradas.length);
    if (inicio >= filtradas.length) return [];
    return filtradas.sublist(inicio, fin);
  }

  int get _totalPaginas =>
      (_lecturasFiltradas.length / _porPagina).ceil().clamp(1, 999);

  void _aplicarFiltro() {
    setState(() {
      _filtroDesde = _combinar(_desdeDate, _desdeTime);
      _filtroHasta = _combinar(_hastaDate, _hastaTime);
      _paginaActual = 1;
    });
  }

  // ── Selectores de fecha/hora ───────────────────────────────────────────────
  Future<void> _seleccionarFecha({required bool esDesde}) async {
    final initial = esDesde ? _desdeDate : _hastaDate;
    final fecha = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2025),
      lastDate: DateTime(2035),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF1A237E)),
        ),
        child: child!,
      ),
    );
    if (fecha == null) return;
    setState(() {
      if (esDesde) {
        _desdeDate = fecha;
      } else {
        _hastaDate = fecha;
      }
    });
  }

  Future<void> _seleccionarHora({required bool esDesde}) async {
    final initial = esDesde ? _desdeTime : _hastaTime;
    final hora = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF1A237E)),
        ),
        child: child!,
      ),
    );
    if (hora == null) return;
    setState(() {
      if (esDesde) {
        _desdeTime = hora;
      } else {
        _hastaTime = hora;
      }
    });
  }

  // ── Dirección desde lat/lng ───────────────────────────────────────────────
  String _direccion(Map<String, dynamic> data) {
    final lat = (data['lat'] ?? 0.0) as num;
    final lng = (data['lng'] ?? 0.0) as num;
    if (lat == 0 && lng == 0) return 'Sin ubicación';
    // Si existe campo dirección guardado
    if (data['direccion'] != null &&
        (data['direccion'] as String).isNotEmpty) {
      return data['direccion'];
    }
    return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final filtradas = _lecturasFiltradas;
    final items = _paginaActualItems;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: _buildAppBar(),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildInfoCard(filtradas.length),
                _buildFiltros(),
                _buildBotonAplicar(),
                _buildTablaHeader(),
                Expanded(child: _buildTablaBody(items)),
                _buildPaginacion(filtradas.length),
                _buildFooter(),
              ],
            ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1A237E),
      foregroundColor: Colors.white,
      toolbarHeight: 72,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dataset General',
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Historial completo de pacientes',
            style: TextStyle(fontSize: 13, color: Colors.white70),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1A237E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onPressed: _exportarExcel,
            icon: const Icon(Icons.grid_on, size: 20),
            label: const Text(
              'Exportar Excel',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

 // ── Card total registros ──────────────────────────────────────────────────
Widget _buildInfoCard(int total) {
  final desde = _combinar(_desdeDate, _desdeTime);
  final hasta = _combinar(_hastaDate, _hastaTime);
  final fmt = DateFormat('dd/MM/yyyy HH:mm');

  return Container(
    margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.07),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFE8EAF6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.assignment,
            color: Color(0xFF1A237E),
            size: 28,
          ),
        ),

        const SizedBox(width: 14),

       Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Total registros: ',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    total.toString().replaceAllMapped(
                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                      (m) => '${m[1]}.',
                    ),
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 3),

              Text(
                'Mostrando del ${fmt.format(desde)} al ${fmt.format(hasta)}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
  // ── Filtros ───────────────────────────────────────────────────────────────
  Widget _buildFiltros() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(child: _buildGrupoFiltro(esDesde: true)),
          const SizedBox(width: 12),
          Expanded(child: _buildGrupoFiltro(esDesde: false)),
        ],
      ),
    );
  }

  Widget _buildGrupoFiltro({required bool esDesde}) {
    final label = esDesde ? 'Desde' : 'Hasta';
    final fecha = esDesde ? _desdeDate : _hastaDate;
    final hora = esDesde ? _desdeTime : _hastaTime;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black87)),
          const SizedBox(height: 8),
          // Selector de fecha
          _selectorBoton(
            icon: Icons.calendar_today,
            texto: _formatFecha(fecha),
            onTap: () => _seleccionarFecha(esDesde: esDesde),
          ),
          const SizedBox(height: 6),
          // Selector de hora
          _selectorBoton(
            icon: Icons.access_time,
            texto: _formatHora(hora),
            onTap: () => _seleccionarHora(esDesde: esDesde),
          ),
        ],
      ),
    );
  }

  Widget _selectorBoton({
    required IconData icon,
    required String texto,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF1A237E)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(texto,
                  style: const TextStyle(fontSize: 13)),
            ),
            const Icon(Icons.arrow_drop_down,
                size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // ── Botón aplicar filtro ───────────────────────────────────────────────────
  Widget _buildBotonAplicar() {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A237E),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: _aplicarFiltro,
          icon: const Icon(Icons.filter_alt, size: 18),
          label: const Text('Aplicar filtro',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  // ── Encabezado tabla ──────────────────────────────────────────────────────
  static const _colFecha = 100.0;
  static const _colHora = 90.0;
  static const _colPaciente = 180.0;
  static const _colBPM = 60.0;
  static const _colSpo2 = 70.0;
  static const _colActividad = 180.0;

  static const _colAx = 70.0;
  static const _colAy = 70.0;
  static const _colAz = 70.0;

  static const _colGx = 70.0;
  static const _colGy = 70.0;
  static const _colGz = 70.0;

  static const _colLat = 90.0;
  static const _colLng = 90.0;

  Widget _buildTablaHeader() {
    return Container(
      color: const Color(0xFF1A237E),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _headerCell('Fecha', _colFecha),
            _headerCell('Hora', _colHora),
            _headerCell('Paciente', _colPaciente),
            _headerCell('BPM', _colBPM),
            _headerCell('SpO₂', _colSpo2),
            _headerCell('Actividad', _colActividad),

            _headerCell('AX', _colAx),
            _headerCell('AY', _colAy),
            _headerCell('AZ', _colAz),

            _headerCell('GX', _colGx),
            _headerCell('GY', _colGy),
            _headerCell('GZ', _colGz),

            _headerCell('Lat', _colLat),
            _headerCell('Lng', _colLng),
          ],
        ),
      ),
    );
  }

  Widget _headerCell(String texto, double width) {
    return SizedBox(
      width: width,
      child: Text(
        texto,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  // ── Filas tabla ───────────────────────────────────────────────────────────
  Widget _buildTablaBody(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text('No hay registros en este rango.',
            style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final data = items[i];
        final DateTime? dt = _timestampToDate(data['timestamp']);
        final fecha = dt != null ? DateFormat('dd/MM/yyyy').format(dt) : '';
        final hora = dt != null ? DateFormat('HH:mm:ss').format(dt) : '';
        final paciente = data['nombrePaciente']?.toString() ?? '';
        final bpm = data['bpm']?.toString() ?? '-';
        final spo2 = data['spo2']?.toString() ?? '-';
        final actividad = data['actividad']?.toString() ?? '';
        final ax = data['ax']?.toString() ?? '-';
        final ay = data['ay']?.toString() ?? '-';
        final az = data['az']?.toString() ?? '-';

        final gx = data['gx']?.toString() ?? '-';
        final gy = data['gy']?.toString() ?? '-';
        final gz = data['gz']?.toString() ?? '-';

        final lat = data['lat']?.toString() ?? '-';
        final lng = data['lng']?.toString() ?? '-';

        final esImpar = i % 2 == 1;

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 13,
          ),

          decoration: BoxDecoration(
            color: esImpar
                ? const Color(0xFFF7F8FF)
                : Colors.white,

            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade200,
              ),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(
                  width: _colFecha,
                  child: Text(fecha,
                      style: const TextStyle(fontSize: 13)),
                ),
                SizedBox(
                  width: _colHora,
                  child: Text(hora,
                      style: const TextStyle(fontSize: 13)),
                ),
                SizedBox(
                  width: _colPaciente,
                  child: Text(paciente,
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis),
                ),
                SizedBox(
                  width: _colBPM,
                  child: Text(bpm,
                      style: const TextStyle(fontSize: 13)),
                ),
                SizedBox(
                  width: _colSpo2,
                  child: Text('$spo2 %',
                      style: const TextStyle(fontSize: 13)),
                ),
                SizedBox(
                  width: _colActividad,
                  child: Text(
                    actividad,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: _colAx,
                  child: Text(ax),
                ),

                SizedBox(
                  width: _colAy,
                  child: Text(ay),
                ),

                SizedBox(
                  width: _colAz,
                  child: Text(az),
                ),

                SizedBox(
                  width: _colGx,
                  child: Text(gx),
                ),

                SizedBox(
                  width: _colGy,
                  child: Text(gy),
                ),

                SizedBox(
                  width: _colGz,
                  child: Text(gz),
                ),

                SizedBox(
                  width: _colLat,
                  child: Text(lat),
                ),

                SizedBox(
                  width: _colLng,
                  child: Text(lng),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  DateTime? _timestampToDate(dynamic ts) {
    try {
      return (ts as Timestamp).toDate();
    } catch (_) {
      return null;
    }
  }

  // ── Paginación ────────────────────────────────────────────────────────────
  Widget _buildPaginacion(int total) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Botón anterior
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.shade300),
              foregroundColor: const Color(0xFF1A237E),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _paginaActual > 1
                ? () => setState(() => _paginaActual--)
                : null,
            icon: const Icon(Icons.chevron_left, size: 18),
            label: const Text('Anterior'),
          ),
          // Indicador
          Expanded(
            child: Center(
              child: Text(
                'Página $_paginaActual de $_totalPaginas',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
          // Botón siguiente
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _paginaActual < _totalPaginas
                ? () => setState(() => _paginaActual++)
                : null,
            icon: const Text('Siguiente'),
            label: const Icon(Icons.chevron_right, size: 18),
          ),
        ],
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 12),
      child: const Center(
        child: Text(
          'Mostrando 10 registros por página',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ),
    );
  }
}