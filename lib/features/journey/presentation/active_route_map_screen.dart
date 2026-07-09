import 'package:flutter/material.dart';
import '../../../core/theme/smartcart_theme.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/smartcart_theme.dart';
import '../../planning/application/basket_notifier.dart';
import '../application/route_notifier.dart';

class ActiveRouteMapScreen extends ConsumerWidget {
  const ActiveRouteMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeState = ref.watch(routeProvider);
    final basketState = ref.watch(basketProvider);
    final activeRoute = routeState.activeRoute;
    final items = basketState.shoppingList.items;

    String storeName = 'Buscando supermercado...';
    if (activeRoute != null && activeRoute.orderedStops.isNotEmpty) {
      storeName = activeRoute.orderedStops.first.name;
    }
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: SmartCartTheme.primaryColor,
        elevation: 0,
        title: const Text('Ruta de compra', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.more_horiz, color: Colors.white), onPressed: () {})
        ],
      ),
      body: Stack(
        children: [
          // Background Map (Placeholder)
          Container(
            color: Theme.of(context).colorScheme.background,
            width: double.infinity,
            height: double.infinity,
            child: CustomPaint(painter: _RoutePainter()),
          ),
          
          // Bottom Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
              ),
              child: Column(
                children: [
                  // Header Store
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: SmartCartTheme.primaryColor.withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(12),
                        color: Theme.of(context).colorScheme.surfaceVariant,
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8))),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(storeName, style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: const BoxDecoration(color: Colors.tealAccent, borderRadius: BorderRadius.all(Radius.circular(12))),
                                      child: const Text('Abierto', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                    )
                                  ],
                                ),
                                Text('Av. Arequipa 1234', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  // Checklist
                  Expanded(
                    child: items.isEmpty 
                      ? Center(child: Text('No hay productos en la ruta', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)))
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: items.length,
                          itemBuilder: (ctx, index) {
                            return Column(
                              children: [
                                _buildCheckItem(context, items[index].name),
                                const Divider(height: 1),
                              ],
                            );
                          },
                        ),
                  ),
                  // Buttons
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.tealAccent.shade400,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Llegué', style: TextStyle(color: Colors.white, fontSize: 16)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: null,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Finalizar', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCheckItem(BuildContext context, String title) {
    return ListTile(
      leading: Container(
        width: 24, height: 24,
        decoration: BoxDecoration(border: Border.all(color: SmartCartTheme.primaryColor, width: 2), borderRadius: BorderRadius.circular(4)),
      ),
      title: Text(title, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
    );
  }
}

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = SmartCartTheme.primaryColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    // Draw dashed line mock
    final p1 = Offset(size.width * 0.2, size.height * 0.6);
    final p2 = Offset(size.width * 0.5, size.height * 0.4);
    final p3 = Offset(size.width * 0.8, size.height * 0.2);

    _drawDashedLine(canvas, p1, p2, paint);
    _drawDashedLine(canvas, p2, p3, paint);

    _drawNode(canvas, p1, '1', false);
    _drawNode(canvas, p2, '2', false);
    _drawNode(canvas, p3, '3', true);
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    var distance = (p2 - p1).distance;
    var direction = (p2 - p1) / distance;
    double dashWidth = 8, dashSpace = 4;
    double startX = p1.dx;
    double startY = p1.dy;
    
    while (distance >= 0) {
      canvas.drawLine(Offset(startX, startY), Offset(startX + direction.dx * dashWidth, startY + direction.dy * dashWidth), paint);
      startX += direction.dx * (dashWidth + dashSpace);
      startY += direction.dy * (dashWidth + dashSpace);
      distance -= (dashWidth + dashSpace);
    }
  }

  void _drawNode(Canvas canvas, Offset pos, String text, bool isActive) {
    final fillPaint = Paint()..color = isActive ? Colors.black54 : SmartCartTheme.primaryColor;
    canvas.drawCircle(pos, 16, fillPaint);
    canvas.drawCircle(pos, 16, Paint()..color=Colors.white..style=PaintingStyle.stroke..strokeWidth=2);

    if (isActive) {
      canvas.drawCircle(pos + const Offset(20, -20), 24, Paint()..color=Colors.white..style=PaintingStyle.fill);
      canvas.drawArc(Rect.fromCircle(center: pos + const Offset(20, -20), radius: 16), 0, 4, false, Paint()..color=SmartCartTheme.primaryColor..style=PaintingStyle.stroke..strokeWidth=4);
    }

    final textSpan = TextSpan(text: text, style: const TextStyle(color: Colors.white, fontSize: 14));
    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(canvas, pos - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
