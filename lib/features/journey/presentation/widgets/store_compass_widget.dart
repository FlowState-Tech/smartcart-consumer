import 'package:flutter/material.dart';
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
    final bearingToTarget = userLocation.bearingTo(targetStop.coordinates);

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
          return const Center(child: Text('El dispositivo no tiene brújula'));
        }

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
                color: SmartCartTheme.primaryColor,
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
}
