import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/app_avatar.dart';
import 'home_panel.dart';
import '../../social/providers/amigos_provider.dart';

class HomeAlliesPanel extends ConsumerWidget {
  const HomeAlliesPanel({
    super.key,
    required this.username,
    this.avatar,
  });

  final String username;
  final String? avatar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amigosState = ref.watch(amigosProvider);

    final amigosConectados = amigosState.amigos
        .where((amistad) => amistad.estaConectado)
        .toList();

    return HomePanel(
      title: 'AMIGOS',
      child: Column(
        children: [
          Expanded(
            child: amigosState.isLoading
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : amigosState.errorMessage != null
                    ? const Center(
                        child: Text(
                          'No se pudieron cargar los amigos',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : amigosConectados.isEmpty
                        ? const Center(
                            child: Text(
                              'No tienes amigos conectados en este momento',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: amigosConectados.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 6),
                            itemBuilder: (context, index) {
                              final amigo = amigosConectados[index];

                              final friendUsername = amigo.otroUsuario(username);
          
                              return _OnlineFriendRow(
                                username: friendUsername,
                                avatar: amigo.avatar,
                                estadoConexion: amigo.estadoConexion,
                                onTap: () {
                                  context.push(AppRoutes.perfilPublicoPath(friendUsername));
                                },
                              );
                            },
                          ),
          ),
          const SizedBox(height: 10),
          _AlliesActionButton(
            text: 'VER ALIANZAS',
            onPressed: () {
              context.push(AppRoutes.social);
            },
          ),
        ],
      ),
    );
  }
}

class _OnlineFriendRow extends StatelessWidget {
  const _OnlineFriendRow({
    required this.username,
    this.avatar,
    this.estadoConexion,
    required this.onTap,
  });

  final String username;
  final String? avatar;
  final String? estadoConexion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        splashColor: AppTheme.primary.withValues(alpha: 0.12),
        highlightColor: AppTheme.primary.withValues(alpha: 0.08),
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              AppAvatar(
                avatar: avatar,
                radius: 14,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppTheme.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                estadoConexion ?? 'Conectado',
                style: TextStyle(
                  color: AppTheme.textSecondary.withValues(alpha: 0.9),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _AlliesActionButton extends StatefulWidget {
  const _AlliesActionButton({
    required this.text,
    required this.onPressed,
  });

  final String text;
  final VoidCallback onPressed;

  @override
  State<_AlliesActionButton> createState() => _AlliesActionButtonState();
}

class _AlliesActionButtonState extends State<_AlliesActionButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;

    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          width: 160,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _pressed ? AppTheme.borderGoldVivo : AppTheme.primary,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _pressed ? 0.22 : 0.32),
                blurRadius: _pressed ? 8 : 10,
                offset: Offset(0, _pressed ? 3 : 5),
              ),
            ],
          ),
          child: Text(
            widget.text,
            style: const TextStyle(
              color: AppTheme.bg,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6,
            ),
          ),
        ),
      ),
    );
  }
}