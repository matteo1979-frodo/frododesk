import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:html' as html;

void main() {
  runApp(const MaterialApp(
    home: FrodoHome(),
    debugShowCheckedModeBanner: false,
  ));
}

class FrodoHome extends StatelessWidget {
  const FrodoHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text("FrodoDesk v8.9.1 - STABILE"),
        backgroundColor: Colors.indigo[900],
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.calendar_today, size: 30),
          label: const Text("APRI PIANIFICATORE"),
          style: ElevatedButton.styleFrom(
              minimumSize: const Size(280, 80),
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => const FrodoCalendario()),
            );
          },
        ),
      ),
    );
  }
}

class FrodoCalendario extends StatefulWidget {
  const FrodoCalendario({super.key});

  @override
  State<FrodoCalendario> createState() => _FrodoCalendarioState();
}

class _FrodoCalendarioState extends State<FrodoCalendario> {
  final ScrollController _sc = ScrollController();
  DateTime _g = DateTime.now();
  int _m = DateTime.now().month;
  int _a = DateTime.now().year;
  Map<String, dynamic> _db = {};

  bool isTappedTile = false;
  Map<String, bool> iconTapped = {
    "mio": false,
    "chiara": false,
    "alice": false,
    "sandra": false,
  };

  final List<String> _mN = [
    "Gennaio",
    "Febbraio",
    "Marzo",
    "Aprile",
    "Maggio",
    "Giugno",
    "Luglio",
    "Agosto",
    "Settembre",
    "Ottobre",
    "Novembre",
    "Dicembre"
  ];
  final List<String> _gN = ["Dom", "Lun", "Mar", "Mer", "Gio", "Ven", "Sab"];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final s = html.window.localStorage['frodo_v87'];
    if (s != null) setState(() => _db = json.decode(s));
  }

 

  void _mostraDettaglio(String nome, Map dati) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text("$nome - ${_g.day}/${_g.month}/${_g.year}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Tipo: ${dati["tipo"] ?? "N/A"}"),
            if (dati["orario"] != null) Text("Orario: ${dati["orario"]}"),
            if (dati["orario2"] != null) Text("Orario 2: ${dati["orario2"]}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Chiudi"),
          )
        ],
      ),
    );
  }

  Widget _animatedIcon(String key, IconData icon, Color color, Map dati) {
    return GestureDetector(
      onTap: () => _mostraDettaglio(key, dati),
      onTapDown: (_) => setState(() => iconTapped[key] = true),
      onTapUp: (_) => setState(() => iconTapped[key] = false),
      onTapCancel: () => setState(() => iconTapped[key] = false),
      child: AnimatedScale(
        scale: iconTapped[key]! ? 1.3 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Icon(icon, size: 14, color: color.withOpacity(0.8)),
      ),
    );
  }

  bool _haBuco(DateTime d) {
    final k = "${d.year}-${d.month}-${d.day}", dt = _db[k]?["persone"] ?? {};
    if (dt["mio"]?["tipo"] == "F" || dt["chiara"]?["tipo"] == "F") return false;
    return false; // per ora semplificato
  }

  @override
  Widget build(BuildContext context) {
    final k = "${_g.year}-${_g.month}-${_g.day}", dt = _db[k]?["persone"] ?? {};
    return Scaffold(
      appBar: AppBar(title: const Text("Pianificatore Familiare")),
      body: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            DropdownButton<int>(
              value: _m,
              items: List.generate(
                  12, (i) => DropdownMenuItem(value: i + 1, child: Text(_mN[i]))),
              onChanged: (v) => setState(() {
                _m = v!;
                _g = DateTime(_a, _m, 1);
              }),
            ),
            const SizedBox(width: 20),
            DropdownButton<int>(
              value: _a,
              items: List.generate(6, (i) => 2025 + i)
                  .map((a) => DropdownMenuItem(value: a, child: Text("$a")))
                  .toList(),
              onChanged: (v) => setState(() {
                _a = v!;
                _g = DateTime(_a, _m, 1);
              }),
            ),
          ]),
          Container(
            height: 95,
            color: Colors.white,
            child: ListView.builder(
                controller: _sc,
                scrollDirection: Axis.horizontal,
                itemCount: DateTime(_a, _m + 1, 0).day,
                itemBuilder: (c, i) {
                  final d = DateTime(_a, _m, i + 1);
                  final isS = d.day == _g.day && d.month == _g.month;
                  final r = _haBuco(d);
                  return GestureDetector(
                    onTap: () => setState(() => _g = d),
                    child: Container(
                      width: 60,
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                      decoration: BoxDecoration(
                        color: isS ? Colors.indigo : (r ? Colors.red[50] : Colors.grey[100]),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: r ? Colors.red : (isS ? Colors.indigo : Colors.grey[300]!),
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 4,
                            left: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (dt["mio"] != null && dt["mio"]["tipo"] != "F")
                                  _animatedIcon("mio", Icons.person, Colors.orange, dt["mio"]),
                                if (dt["chiara"] != null && dt["chiara"]["tipo"] != "F")
                                  _animatedIcon("chiara", Icons.person, Colors.blue, dt["chiara"]),
                                if (dt["alice"] != null)
                                  _animatedIcon("alice", Icons.school, Colors.purple, dt["alice"]),
                                if (dt["sandra"] != null)
                                  _animatedIcon("sandra", Icons.person, Colors.green, dt["sandra"]),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _gN[d.weekday % 7],
                                style: TextStyle(
                                  color: r ? Colors.red : (isS ? Colors.white : Colors.grey[600]),
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                "${d.day}",
                                style: TextStyle(
                                  color: isS ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
          ),
        ],
      ),
    );
  }
}