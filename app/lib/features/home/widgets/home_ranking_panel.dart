import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import 'home_panel.dart';
import '../../social/providers/ranking_provider.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_routes.dart';

class HomeRankingPanel extends ConsumerWidget {
  const HomeRankingPanel({
    super.key,
    required this.currentUsername,  
  });

  final String currentUsername;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingAsync = ref.watch(rankingProvider);

    return HomePanel(
      title: 'TOP GLOBAL',
      child: rankingAsync.when(
        loading: () => const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (_, __) => const Center(
          child: Text(
            'No se pudo cargar el ranking',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        data: (ranking) {
          if (ranking.isEmpty) {
            return const Center(
              child: Text(
                'Sin datos todavía',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: ranking.length,
            separatorBuilder: (_, _) => const SizedBox(height: 2),
            itemBuilder: (context, index) {
              final item = ranking[index];

              return _RankingRow(
                position: '${index + 1}',
                username: item.nombreUser,
                score: '${item.numPartidasGanadas}',
                highlighted: item.nombreUser == currentUsername,
                onTap: () {
                  context.push(AppRoutes.perfilPublicoPath(item.nombreUser));
                }
              );
            },
          );
        },
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({
    required this.position,
    required this.username,
    required this.score,
    required this.onTap,
    this.highlighted = false,
  });

  final String position;
  final String username;
  final String score;
  final bool highlighted;
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
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: highlighted
                ? AppTheme.primary.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border(
              bottom: BorderSide(
                color: AppTheme.borderGold.withValues(alpha: 0.10),
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: highlighted
                        ? AppTheme.borderGoldVivo
                        : AppTheme.borderGold.withValues(alpha: 0.45),
                  ),
                ),
                child: Text(
                  position,
                  style: TextStyle(
                    color: highlighted ? AppTheme.borderGoldVivo : AppTheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
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
              Text(
                score,
                style: TextStyle(
                  color: AppTheme.textSecondary.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}