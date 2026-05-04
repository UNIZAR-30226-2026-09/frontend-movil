import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:soberania/app/theme/app_theme.dart';
import 'package:soberania/features/auth/providers/auth_provider.dart';
import 'package:soberania/features/game/providers/websocket_provider.dart';
import 'package:soberania/shared/api/dio_provider.dart';

class ReaccionesButton extends ConsumerStatefulWidget {
  const ReaccionesButton({super.key});

  @override
  ConsumerState<ReaccionesButton> createState() => _ReaccionesButtonState();
}

class _ReaccionesButtonState extends ConsumerState<ReaccionesButton> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  Future<Map<String, dynamic>>? _opcionesFuture;

  static const String _reactionAssetsBaseUrl =
      'http://192.168.1.35:8000/static/reacciones/';

  Future<Map<String, dynamic>> _fetchOpciones(WidgetRef ref) async {
    final response = await ref.read(dioProvider).get('http://192.168.1.35:8000/api/v1/usuarios/opciones');

    if (response.statusCode == 200 && response.data is Map) {
      return Map<String, dynamic>.from(response.data as Map);
    }

    return <String, dynamic>{};
  }

  String _reactionImageUrl(String fileName) {
    final normalized = fileName.trim();
    if (normalized.startsWith('http://') ||
        normalized.startsWith('https://')) {
      return normalized;
    }

    if (normalized.startsWith('/')) {
      return 'http://192.168.1.35:8000$normalized';
    }

    return '$_reactionAssetsBaseUrl$normalized';
  }

  void _emitirOpcion(WidgetRef ref, String selected) {
    final separatorIndex = selected.indexOf(':');
    if (separatorIndex <= 0 || separatorIndex == selected.length - 1) return;

    final tipo = selected.substring(0, separatorIndex);
    final contenido = selected.substring(separatorIndex + 1);
    final username = ref.read(authProvider).user?.username;

    ref.read(webSocketProvider.notifier).emitirEvento('CHAT', {
      'accion': 'enviar_chat',
      'tipo': tipo,
      'contenido': contenido,
      if (tipo == 'reaccion') 'archivo': contenido,
      if (tipo == 'mensaje') 'mensaje': contenido,
      if (username != null && username.isNotEmpty) 'jugador': username,
    });
  }

  void _cerrarPanel() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _togglePanel() {
    if (_overlayEntry != null) {
      _cerrarPanel();
      return;
    }

    _opcionesFuture ??= _fetchOpciones(ref);
    _overlayEntry = OverlayEntry(
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        final screenSize = mediaQuery.size;
        final safeTop = mediaQuery.padding.top + 8;
        final panelWidth = (screenSize.width * 0.31).clamp(300.0, 330.0);
        final panelHeight = screenSize.height - safeTop - 10;
        final panelLeft = screenSize.width - panelWidth - 80;

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _cerrarPanel,
              ),
            ),
            Positioned(
              left: panelLeft,
              top: safeTop,
              width: panelWidth,
              height: panelHeight,
              child: Material(
                color: Colors.transparent,
                child: _ReaccionesPanel(
                  futureOpciones: _opcionesFuture!,
                  imageUrlBuilder: _reactionImageUrl,
                  onSelected: (selected) {
                    _cerrarPanel();
                    _emitirOpcion(ref, selected);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  void dispose() {
    _cerrarPanel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.panelBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.goldMain, width: 1.5),
        ),
        child: IconButton(
          tooltip: 'Reacciones',
          padding: EdgeInsets.zero,
          onPressed: _togglePanel,
          icon: const Icon(
            Icons.add_reaction_outlined,
            color: AppTheme.goldMain,
            size: 28,
          ),
        ),
      ),
    );
  }
}

class _ReaccionesPanel extends ConsumerWidget {
  const _ReaccionesPanel({
    required this.futureOpciones,
    required this.imageUrlBuilder,
    required this.onSelected,
  });

  final Future<Map<String, dynamic>> futureOpciones;
  final String Function(String fileName) imageUrlBuilder;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.panelBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.goldMain.withValues(alpha: 0.9),
          width: 2,
        ),
      ),
      child: FutureBuilder<Map<String, dynamic>>(
        future: futureOpciones,
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
          final reacciones = _parseStringOptions(data['reacciones']);
          final mensajes = _parseStringOptions(data['mensajes']);

          return Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (reacciones.isNotEmpty)
                  _ReactionGrid(
                    reacciones: reacciones,
                    imageUrlBuilder: imageUrlBuilder,
                    ref: ref,
                  ),
                if (mensajes.isNotEmpty) ...[
                  if (reacciones.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: AppTheme.goldMain.withValues(alpha: 0.3),
                      ),
                    ),
                  for (var i = 0; i < mensajes.length; i++) ...[
                    InkWell(
                      onTap: () {
                        final mensaje = mensajes[i];
                        debugPrint('🚀 ENVIANDO MENSAJE: $mensaje');
                        ref.read(webSocketProvider.notifier).emitirEvento('CHAT', {
                          'tipo_chat': 'mensaje',
                          'contenido': mensaje,
                        });
                        Future.delayed(Duration.zero, () {
                          if (context.mounted && Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        });
                      },
                      child: SizedBox(
                        width: double.infinity,
                        height: 28,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            mensajes[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFB59A63),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (i < mensajes.length - 1)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: AppTheme.goldMain.withValues(alpha: 0.18),
                      ),
                  ],
                ],
                if (reacciones.isEmpty && mensajes.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(
                        'No hay opciones disponibles.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  static List<String> _parseStringOptions(dynamic raw) {
    final output = <String>[];
    if (raw is! List) return output;

    for (final item in raw) {
      if (item is String) {
        output.add(item);
      } else if (item is Map && item['file'] != null) {
        output.add(item['file'].toString());
      } else if (item is Map && item['nombre'] != null) {
        output.add(item['nombre'].toString());
      } else if (item is Map && item['texto'] != null) {
        output.add(item['texto'].toString());
      }
    }

    return output;
  }
}

class _ReactionGrid extends ConsumerWidget {
  const _ReactionGrid({
    required this.reacciones,
    required this.imageUrlBuilder,
    required this.ref,
  });

  final List<String> reacciones;
  final String Function(String fileName) imageUrlBuilder;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef refWidget) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 6.0;
        final tileSize = (constraints.maxWidth - spacing * 2) / 3;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final fileName in reacciones)
              SizedBox(
                width: tileSize,
                height: tileSize,
                child: GestureDetector(
                  onTap: () {
                    debugPrint('🚀 ENVIANDO STICKER: $fileName');
                    ref.read(webSocketProvider.notifier).emitirEvento('CHAT', {
                      'tipo_chat': 'reaccion',
                      'contenido': fileName,
                    });
                    Future.delayed(Duration.zero, () {
                      if (context.mounted && Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    });
                  },
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF17161B),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.goldMain.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Image.network(
                          imageUrlBuilder(fileName),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: const Color(0xFF1F1F1F),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.broken_image_outlined,
                              color: Colors.white24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
