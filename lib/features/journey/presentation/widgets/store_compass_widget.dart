import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import '../../domain/value_objects.dart';
import '../../domain/entities.dart';
import '../../../../core/theme/smartcart_theme.dart';

class StoreCompassWidget extends StatelessWidget {
  final Coordinates userLocation;
  final StopPoint targetStop;

  const StoreCompassWidget({
    super.key,
    required this.userLocation,
    required this.targetStop,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate the bearing to the target
    final bearingToTarget = userLocation.bearingTo(targetStop.coordinates);

    if (kIsWeb) {
      // Compass sensors are not supported on web. Return a static fallback.
      return _buildStaticCompass(bearingToTarget);
    }

    return StreamBuilder<CompassEvent>(
      stream: FlutterCompass.events,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Icon(Icons.error);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        final double? deviceHeading = snapshot.data?.heading;

        if (deviceHeading == null) {
          return const Center(child: Text('Device does not have sensors'));
        }

        // Calculate rotation: target bearing minus device heading
        final rotation = bearingToTarget - deviceHeading;
        final rotationRadians = rotation * (math.pi / 180);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.rotate(
              angle: rotationRadians,
              child: const Icon(
                Icons.navigation,
                size: 64,
                color: SmartCartTheme.primaryColor, // Azul Tecnológico
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${targetStop.name}\n${userLocation.distanceTo(targetStop.coordinates).toStringAsFixed(0)}m',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStaticCompass(double bearing) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.rotate(
          angle: bearing * (math.pi / 180),
          child: const Icon(
            Icons.navigation,
            size: 64,
            color: SmartCartTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${targetStop.name}\n${userLocation.distanceTo(targetStop.coordinates).toStringAsFixed(0)}m\n(Modo Web: Sin Sensor)',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
