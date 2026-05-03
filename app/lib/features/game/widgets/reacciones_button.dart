import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:soberania/app/theme/app_theme.dart';

class ReaccionesButton extends StatelessWidget {
  const ReaccionesButton({super.key});

  Future<Map<String, dynamic>> _fetchOpciones() async {
    final response = await Dio().get(
      'https://soberania.dev/api/v1/usuarios/opciones',
    );

    if (response.statusCode == 200 && response.data is Map) {
      return Map<String, dynamic>.from(response.data as Map);
    }

    return <String, dynamic>{};
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTheme.panelBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.goldMain, width: 1.5),
      ),
      child: PopupMenuButton<String>(
        icon: const Icon(
          Icons.add_reaction_outlined,
          color: AppTheme.goldMain,
          size: 28,
        ),
        padding: EdgeInsets.zero,
        tooltip: 'Reacciones',
        offset: const Offset(0, 48),
        color: AppTheme.panelBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppTheme.goldMain.withValues(alpha: 0.2)),
        ),
        onSelected: (_) {},
        itemBuilder: (BuildContext context) => [
          PopupMenuItem<String>(
            enabled: false,
            padding: EdgeInsets.zero,
            child: SizedBox(
              width: 280,
              height: 450,
              child: FutureBuilder<Map<String, dynamic>>(
                future: _fetchOpciones(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  if (snapshot.hasError || snapshot.data == null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'No se pudieron cargar las opciones.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                    );
                  }

                  final data = snapshot.data!;
                  final reacciones = <String>[];
                  final mensajes = <String>[];

                  final rawReacciones = data['reacciones'];
                  if (rawReacciones is List) {
                    for (final item in rawReacciones) {
                      if (item is String) {
                        reacciones.add(item);
                      } else if (item is Map && item['file'] != null) {
                        reacciones.add(item['file'].toString());
                      } else if (item is Map && item['nombre'] != null) {
                        reacciones.add(item['nombre'].toString());
                      }
                    }
                  }

                  final rawMensajes = data['mensajes'];
                  if (rawMensajes is List) {
                    for (final item in rawMensajes) {
                      if (item is String) {
                        mensajes.add(item);
                      } else if (item is Map && item['texto'] != null) {
                        mensajes.add(item['texto'].toString());
                      }
                    }
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (reacciones.isNotEmpty) ...[
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: reacciones.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 1,
                            ),
                            itemBuilder: (context, index) {
                              final fileName = reacciones[index];
                              final imageUrl =
                                  'https://soberania.dev/storage/reacciones/$fileName';
                              // Añade esto para ver qué URL se está intentando cargar en la consola
                              print('DEBUG: Cargando imagen desde -> $imageUrl');
                              return GestureDetector(
                                onTap: () => Navigator.of(context).pop(
                                  'reaccion:$fileName',
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: const Color(0xFF1F1F1F),
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.broken_image_outlined,
                                        color: Colors.white24,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                        if (mensajes.isNotEmpty) ...[
                          if (reacciones.isNotEmpty) const SizedBox(height: 12),
                          ...mensajes.map(
                            (mensaje) => InkWell(
                              onTap: () => Navigator.of(context).pop(
                                'mensaje:$mensaje',
                              ),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Text(
                                  mensaje,
                                  style: const TextStyle(
                                    color: Color(0xFFB59A63),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (reacciones.isEmpty && mensajes.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              'No hay opciones disponibles.',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
