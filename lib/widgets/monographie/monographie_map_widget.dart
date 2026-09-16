import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geojson_vi/geojson_vi.dart';

class MonographieMapWidget extends StatefulWidget {
  final String? types;
  final String? id;
  final double height;
  final double heightDiv;
  final Future<dynamic> Function(String? id) getTerritoryByFormattedId;
  final String? territoireName;

  const MonographieMapWidget({
    super.key,
    this.types,
    this.id,
    this.height = 400.0,
    this.heightDiv = 300.0,
    required this.getTerritoryByFormattedId,
    this.territoireName,
  });

  @override
  State<MonographieMapWidget> createState() => _MonographieMapWidgetState();
}

class _MonographieMapWidgetState extends State<MonographieMapWidget> {
  dynamic _territory;
  bool _loading = false;
  final MapController _mapController = MapController();
  GeoJSONGeometry? _geometry;

  @override
  void initState() {
    super.initState();
    _fetchTerritory();
  }

  @override
  void didUpdateWidget(MonographieMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id || oldWidget.types != widget.types) {
      _fetchTerritory();
    }
  }

  Future<void> _fetchTerritory() async {
    if (widget.id == null) return;
    setState(() {
      _loading = true;
    });

    try {
      final d = await widget.getTerritoryByFormattedId(widget.id);
      if (!mounted) return;
      bool isCommune = widget.types?.contains("commune") == true;

      dynamic territoryData;
      if (d is Map) {
        territoryData = isCommune
            ? (d['commune'] ?? d['district'] ?? d['data'] ?? d)
            : (d['district'] ?? d['commune'] ?? d['data'] ?? d);
      } else {
        territoryData = d;
      }

      if (!mounted) return;
      setState(() {
        _territory = territoryData;
        _geometry = null;
      });

      if (_territory != null) {
        dynamic rawForm = _territory['form'] ??
            _territory['geometry'] ??
            _territory['geojson'] ??
            _territory['shape'] ??
            _territory['geo_shape'];

        if (rawForm != null) {
          try {
            Map<String, dynamic>? mapObj;
            if (rawForm is String) {
              mapObj = Map<String, dynamic>.from(json.decode(rawForm));
            } else if (rawForm is Map) {
              mapObj = Map<String, dynamic>.from(rawForm);
            }
            if (mapObj != null && mounted) {
              setState(() {
                _geometry = GeoJSONGeometry.fromMap(mapObj!);
              });
            }
          } catch (e) {
            debugPrint("Erreur parsing GeoJSON: $e");
          }
        }
      }

      // Recentrer la carte après chargement des polygones
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final polys = _buildPolygons();
        if (polys.isNotEmpty) {
          final center = _getCenter(polys);
          final double zoomLevel = isCommune ? 10.5 : 9.0;
          try {
            _mapController.move(center, zoomLevel);
          } catch (e) {
            debugPrint("Erreur move mapController: $e");
          }
        }
      });

    } catch (e) {
      debugPrint("Erreur récupération territoire: $e");
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  List<Polygon> _buildPolygons() {
    if (_geometry == null) return [];
    
    List<Polygon> polygons = [];
    if (_geometry is GeoJSONPolygon) {
      final poly = _geometry as GeoJSONPolygon;
      for (var ring in poly.coordinates) {
        List<LatLng> points = ring.map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble())).toList();
        polygons.add(
          Polygon(
            points: points,
            color: Colors.lightBlue.withValues(alpha: 0.3),
            borderColor: Colors.blue,
            borderStrokeWidth: 2,
          ),
        );
      }
    } else if (_geometry is GeoJSONMultiPolygon) {
      final multiPoly = _geometry as GeoJSONMultiPolygon;
      for (var polygonCoords in multiPoly.coordinates) {
        for (var ring in polygonCoords) {
          List<LatLng> points = ring.map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble())).toList();
          polygons.add(
            Polygon(
              points: points,
              color: Colors.lightBlue.withValues(alpha: 0.3),
              borderColor: Colors.blue,
              borderStrokeWidth: 2,
            ),
          );
        }
      }
    }
    return polygons;
  }

  LatLng _getCenter(List<Polygon> polygons) {
    if (polygons.isEmpty) return const LatLng(-18.8792, 47.5079);
    double minLat = 90.0, maxLat = -90.0;
    double minLng = 180.0, maxLng = -180.0;
    for (var poly in polygons) {
      for (var pt in poly.points) {
        if (pt.latitude < minLat) minLat = pt.latitude;
        if (pt.latitude > maxLat) maxLat = pt.latitude;
        if (pt.longitude < minLng) minLng = pt.longitude;
        if (pt.longitude > maxLng) maxLng = pt.longitude;
      }
    }
    return LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
  }

  @override
  Widget build(BuildContext context) {
    final polygons = _buildPolygons();
    final center = _getCenter(polygons);
    final bool hasPolygon = polygons.isNotEmpty;
    final String label = widget.territoireName ?? '';

    return SizedBox(
      height: widget.heightDiv,
      width: double.infinity,
      child: Stack(
        children: [
          SizedBox(
            height: widget.height,
            width: double.infinity,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: hasPolygon ? 9.5 : 6.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'mg.gov.itantsoroka',
                ),
                if (hasPolygon)
                  PolygonLayer(
                    polygons: polygons.map((p) => Polygon(
                      points: p.points,
                      color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                      borderColor: const Color(0xFF2563EB),
                      borderStrokeWidth: 2.5,
                    )).toList(),
                  ),
                // Marker nom du territoire au centre
                if (hasPolygon && label.isNotEmpty)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: center,
                        width: 160,
                        height: 40,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF098E00),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.location_on, color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (_loading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF098E00),
                ),
              ),
            ),
        ],
      ),
    );
  }
}