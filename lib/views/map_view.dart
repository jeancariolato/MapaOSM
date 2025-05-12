import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../viewmodels/location_viewmodel.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  //Controllers
  final MapController _mapController = MapController();
  LatLng? _ultimaPosicao;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final viewModel = context.read<LocationViewModel>();
    viewModel.addListener(_onLocationChanged);
  }

  void _onLocationChanged() {
    final viewModel = context.read<LocationViewModel>();
    final loc = viewModel.location;
    if (loc != null) {
      final novaPosicao = LatLng(loc.latitude, loc.longitude);
      if (_ultimaPosicao == null || _ultimaPosicao != novaPosicao) {
        _mapController.move(novaPosicao, _mapController.camera.zoom);
        _ultimaPosicao = novaPosicao;
      }
    }
  }

  @override
  void dispose() {
    context.read<LocationViewModel>().removeListener(_onLocationChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<LatLng?> _buscarEndereco(String query) async {
    final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1');
    final response = await http.get(url, headers: {
      'User-Agent': 'mapa-osm-app/1.0 (email@exemplo.com)',
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data.isNotEmpty) {
        final lat = double.parse(data[0]['lat']);
        final lon = double.parse(data[0]['lon']);
        return LatLng(lat, lon);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading || viewModel.location == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final location = viewModel.location!;
        final posicao = LatLng(location.latitude, location.longitude);

        return Column(
          children: [
            Container(
              color: Colors.blue[900], // Fundo azul escuro atrás da barra
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar endereço...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white, // Fundo da barra branco
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
                  ),
                ),
                onSubmitted: (query) async {
                  final latLng = await _buscarEndereco(query);
                  if (latLng != null) {
                    _mapController.move(latLng, 16);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Endereço não encontrado.')),
                    );
                  }
                },
              ),
            ),
            Expanded(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: posicao,
                  initialZoom: 16,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                    userAgentPackageName: 'br.edu.ifsul.flutter_mapas_osm',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: posicao,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
