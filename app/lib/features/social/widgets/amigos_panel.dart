import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../models/amistad_model.dart';
import '../providers/amigos_provider.dart';

enum _SocialTab {
  aliados,
  solicitudes,
}

class AmigosPanel extends ConsumerStatefulWidget {
  const AmigosPanel({super.key});

  @override
  ConsumerState<AmigosPanel> createState() => _AmigosPanelState();
}

class _AmigosPanelState extends ConsumerState<AmigosPanel> {
  final TextEditingController _usernameController = TextEditingController();
  _SocialTab _selectedTab = _SocialTab.aliados;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _enviarSolicitud() async {
    final username = _usernameController.text.trim();

    if (username.isEmpty) {
      _showSnackBar('Introduce el nombre de un comandante.');
      return;
    }

    final ok = await ref.read(amigosProvider.notifier).enviarSolicitud(username);

    if (!mounted) return;

    if (ok) {
      _usernameController.clear();
      _showSnackBar('Solicitud de alianza enviada.');
      setState(() {
        _selectedTab = _SocialTab.solicitudes;
      });
    } else {
      final error = ref.read(amigosProvider).errorMessage;
      _showSnackBar(error ?? 'No se pudo enviar la solicitud.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.surface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(amigosProvider);
    final notifier = ref.read(amigosProvider.notifier);

    final solicitudesRecibidas = notifier.solicitudesRecibidas;
    final solicitudesEnviadas = notifier.solicitudesEnviadas;

    return LayoutBuilder(
      builder: (context, constraints) {
        final panelWidth = constraints.maxWidth > 760.0
            ? 760.0
            : constraints.maxWidth;

        return SizedBox(
          width: panelWidth,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.panelOverlay,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppTheme.borderGold,
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.45),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
              child: Column(
                children: [
                  const _PanelHeader(),

                  const SizedBox(height: 18),

                  _RecruitRow(
                    controller: _usernameController,
                    isLoading: state.isSendingRequest,
                    onSubmit: _enviarSolicitud,
                  ),

                  const SizedBox(height: 24),

                  _TabsRow(
                    selectedTab: _selectedTab,
                    receivedCount: solicitudesRecibidas.length,
                    onChanged: (tab) {
                      setState(() {
                        _selectedTab = tab;
                      });
                    },
                  ),

                  const SizedBox(height: 18),

                  if (state.errorMessage != null)
                    _ErrorBox(
                      message: state.errorMessage!,
                      onClose: () {
                        ref.read(amigosProvider.notifier).limpiarError();
                      },
                    ),

                  if (state.errorMessage != null)
                    const SizedBox(height: 12),

                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: state.isLoading
                          ? const _LoadingState()
                          : _selectedTab == _SocialTab.aliados
                              ? _AlliesList(
                                  amigos: state.amigos,
                                  usuarioActual: notifier.usuarioActual,
                                  onDelete: (amistadId) {
                                    ref
                                        .read(amigosProvider.notifier)
                                        .eliminarAmigo(amistadId);
                                  },
                                )
                              : _RequestsList(
                                  usuarioActual: notifier.usuarioActual,
                                  recibidas: solicitudesRecibidas,
                                  enviadas: solicitudesEnviadas,
                                  onAccept: (solicitudId) {
                                    ref
                                        .read(amigosProvider.notifier)
                                        .aceptarSolicitud(solicitudId);
                                  },
                                  onReject: (solicitudId) {
                                    ref
                                        .read(amigosProvider.notifier)
                                        .rechazarSolicitud(solicitudId);
                                  },
                                ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'TRATADOS Y ALIANZAS',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.primary,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: 4,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.8),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 1,
          color: AppTheme.borderBronze.withOpacity(0.65),
        ),
      ],
    );
  }
}

class _RecruitRow extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSubmit;

  const _RecruitRow({
    required this.controller,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            enabled: !isLoading,
            style: const TextStyle(
              color: AppTheme.text,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
            cursorColor: AppTheme.primary,
            onSubmitted: (_) => onSubmit(),
            decoration: InputDecoration(
              hintText: 'Buscar comandante por nombre...',
              hintStyle: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
              filled: true,
              fillColor: Colors.black.withOpacity(0.42),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 15,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(0),
                borderSide: BorderSide(
                  color: AppTheme.borderBronze.withOpacity(0.85),
                ),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(
                  color: AppTheme.borderGoldVivo,
                  width: 1.2,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(0),
                borderSide: BorderSide(
                  color: AppTheme.disabled.withOpacity(0.7),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 52,
          child: OutlinedButton(
            onPressed: isLoading ? null : onSubmit,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              disabledForegroundColor: AppTheme.disabled,
              side: BorderSide(
                color: isLoading ? AppTheme.disabled : AppTheme.borderGold,
                width: 1.2,
              ),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 22),
              backgroundColor: AppTheme.surface.withOpacity(0.45),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primary,
                    ),
                  )
                : const Text(
                    'RECLUTAR',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _TabsRow extends StatelessWidget {
  final _SocialTab selectedTab;
  final int receivedCount;
  final ValueChanged<_SocialTab> onChanged;

  const _TabsRow({
    required this.selectedTab,
    required this.receivedCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SocialTabButton(
          label: 'ALIADOS',
          selected: selectedTab == _SocialTab.aliados,
          onTap: () => onChanged(_SocialTab.aliados),
        ),
        const SizedBox(width: 26),
        _SocialTabButton(
          label: receivedCount > 0
              ? 'PETICIONES PENDIENTES ($receivedCount)'
              : 'PETICIONES PENDIENTES',
          selected: selectedTab == _SocialTab.solicitudes,
          onTap: () => onChanged(_SocialTab.solicitudes),
        ),
      ],
    );
  }
}

class _SocialTabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SocialTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.text : AppTheme.textSecondary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
              ),
            ),
            const SizedBox(height: 7),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: selected ? 112 : 0,
              height: 2,
              color: AppTheme.borderGoldVivo,
            ),
          ],
        ),
      ),
    );
  }
}

class _AlliesList extends StatelessWidget {
  final List<AmistadModel> amigos;
  final String usuarioActual;
  final ValueChanged<int> onDelete;

  const _AlliesList({
    required this.amigos,
    required this.usuarioActual,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (amigos.isEmpty) {
      return const _EmptyState(
        message: 'No tienes aliados todavía.',
      );
    }

    return ListView.separated(
      itemCount: amigos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final amistad = amigos[index];
        final nombre = amistad.otroUsuario(usuarioActual);

        return _AllyCard(
          name: nombre,
          onDelete: () => onDelete(amistad.id),
        );
      },
    );
  }
}

class _RequestsList extends StatelessWidget {
  final String usuarioActual;
  final List<AmistadModel> recibidas;
  final List<AmistadModel> enviadas;
  final ValueChanged<int> onAccept;
  final ValueChanged<int> onReject;

  const _RequestsList({
    required this.usuarioActual,
    required this.recibidas,
    required this.enviadas,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    if (recibidas.isEmpty && enviadas.isEmpty) {
      return const _EmptyState(
        message: 'No hay tratados pendientes de firma.',
      );
    }

    return ListView(
      children: [
        if (recibidas.isNotEmpty) ...[
          const _SubsectionTitle('RECIBIDAS'),
          const SizedBox(height: 8),
          ...recibidas.map(
            (solicitud) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ReceivedRequestCard(
                name: solicitud.otroUsuario(usuarioActual),
                onAccept: () => onAccept(solicitud.id),
                onReject: () => onReject(solicitud.id),
              ),
            ),
          ),
        ],
        if (enviadas.isNotEmpty) ...[
          const SizedBox(height: 12),
          const _SubsectionTitle('ENVIADAS'),
          const SizedBox(height: 8),
          ...enviadas.map(
            (solicitud) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SentRequestCard(
                name: solicitud.otroUsuario(usuarioActual),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AllyCard extends StatelessWidget {
  final String name;
  final VoidCallback onDelete;

  const _AllyCard({
    required this.name,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseCommanderCard(
      name: name,
      subtitle: 'CONECTADO',
      leadingColor: AppTheme.success,
      trailing: _SquareIconButton(
        icon: Icons.close_rounded,
        tooltip: 'Eliminar aliado',
        onTap: onDelete,
      ),
    );
  }
}

class _ReceivedRequestCard extends StatelessWidget {
  final String name;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _ReceivedRequestCard({
    required this.name,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseCommanderCard(
      name: name,
      subtitle: 'SOLICITA UNA ALIANZA',
      leadingColor: AppTheme.primary,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SquareIconButton(
            icon: Icons.check_rounded,
            tooltip: 'Aceptar',
            color: AppTheme.success,
            onTap: onAccept,
          ),
          const SizedBox(width: 8),
          _SquareIconButton(
            icon: Icons.close_rounded,
            tooltip: 'Rechazar',
            color: AppTheme.error,
            onTap: onReject,
          ),
        ],
      ),
    );
  }
}

class _SentRequestCard extends StatelessWidget {
  final String name;

  const _SentRequestCard({
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseCommanderCard(
      name: name,
      subtitle: 'ESPERANDO RESPUESTA',
      leadingColor: AppTheme.textSecondary,
      trailing: const Text(
        'PENDIENTE',
        style: TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _BaseCommanderCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final Color leadingColor;
  final Widget trailing;

  const _BaseCommanderCard({
    required this.name,
    required this.subtitle,
    required this.leadingColor,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.24),
        border: Border(
          left: BorderSide(
            color: leadingColor,
            width: 4,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(18, 13, 18, 13),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.24),
              border: Border.all(
                color: AppTheme.borderBronze.withOpacity(0.8),
              ),
            ),
            child: Text(
              initial,
              style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                fontFamily: 'serif',
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: leadingColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: leadingColor.withOpacity(0.65),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        subtitle,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final Color color;

  const _SquareIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.color = AppTheme.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppTheme.surface.withOpacity(0.38),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(
            color: color.withOpacity(0.7),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class _SubsectionTitle extends StatelessWidget {
  final String text;

  const _SubsectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppTheme.primary.withOpacity(0.9),
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.6,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 16,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: AppTheme.primary,
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onClose;

  const _ErrorBox({
    required this.message,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.14),
        border: Border.all(
          color: AppTheme.error.withOpacity(0.65),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppTheme.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTheme.text,
                fontSize: 13,
              ),
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(
              Icons.close_rounded,
              color: AppTheme.textSecondary,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}