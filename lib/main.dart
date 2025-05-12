import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/location_viewmodel.dart';
import 'views/map_view.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create:
          (_) =>
              LocationViewModel()
                ..fetchLocation()
                ..startLocationUpdates(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mapa OSM',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.blue[900],
          title: Text('Mapa OSM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: const MapView(),
      ),
    );
  }
}
