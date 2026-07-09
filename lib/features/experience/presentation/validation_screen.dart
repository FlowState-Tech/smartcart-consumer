import 'package:flutter/material.dart';
import '../../../core/theme/smartcart_theme.dart';

class ValidationScreen extends StatelessWidget {
  const ValidationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Validación de Compra', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
              ),
              Container(
                decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!)),
                child: TabBar(
                  indicatorColor: SmartCartTheme.primaryColor,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: const BoxDecoration(color: SmartCartTheme.primaryColor),
                  tabs: [
                    Tab(
                      child: Builder(
                        builder: (ctx) {
                          final selected = DefaultTabController.of(ctx).index == 0;
                          return Text('Por producto', style: TextStyle(color: selected ? Colors.white : Colors.grey));
                        }
                      )
                    ),
                    Tab(
                      child: Builder(
                        builder: (ctx) {
                          final selected = DefaultTabController.of(ctx).index == 1;
                          return Text('Por ticket', style: TextStyle(color: selected ? Colors.white : Colors.grey));
                        }
                      )
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildProductTab(),
                    _buildTicketTab(),
                  ],
                ),
              )
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.lightGreenAccent.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('+15 pts', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildProductTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          TextField(
            style: const TextStyle(color: Colors.black),
            decoration: InputDecoration(
              hintText: 'Buscar producto...',
              hintStyle: const TextStyle(color: Colors.grey),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            width: 200, height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.camera_alt, size: 64, color: Colors.black54),
          ),
          const SizedBox(height: 32),
          _buildInfoRow('Producto', 'Leche Gloria 1L'),
          const SizedBox(height: 16),
          _buildInfoRow('Tienda', 'Plaza Vea Centro'),
          const SizedBox(height: 16),
          _buildInfoRow('Precio', 'S/ 4.50', isPrice: true),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                  label: const Text('Confirmar', style: TextStyle(color: Colors.white, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent.shade400,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                  child: const Text('Reportar', style: TextStyle(color: Colors.black54, fontSize: 16)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTicketTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          CustomPaint(
            painter: _DashedBorderPainter(),
            child: Container(
              height: 250,
              width: double.infinity,
              alignment: Alignment.center,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, size: 48, color: Colors.black54),
                  SizedBox(height: 16),
                  Text('Toca para escanear ticket', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildInfoRow('Producto 1', 'S/ 4.50'),
          const SizedBox(height: 16),
          _buildInfoRow('Producto 2', 'S/ 7.20'),
          const Divider(height: 32),
          _buildInfoRow('Total', 'S/ 11.70', isPrice: true),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent.shade400,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Validar ticket', style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isPrice = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 16)),
        Text(value, style: TextStyle(color: isPrice ? SmartCartTheme.primaryColor : Colors.black87, fontSize: 16, fontWeight: isPrice ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = SmartCartTheme.primaryColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(16)));

    // Dashed effect manually
    final metric = path.computeMetrics().first;
    double dashWidth = 8, dashSpace = 8, distance = 0;
    while (distance < metric.length) {
      canvas.drawPath(metric.extractPath(distance, distance + dashWidth), paint);
      distance += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
