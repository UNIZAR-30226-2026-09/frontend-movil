import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import 'home_panel.dart';

class HomeRankingPanel extends StatelessWidget {
  const HomeRankingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    const ranking = [
      ('1', 'roldan', '4'),
      ('2', 'roldan1', '3'),
      ('3', 'jaime', '2'),
      ('4', 'lexis', '1'),
    ];

    return HomePanel(
      title: 'TOP GLOBAL',
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: ranking.length,
        separatorBuilder: (_, _) => const SizedBox(height: 2),
        itemBuilder: (context, index) {
          final item = ranking[index];

          return _RankingRow(
            position: item.$1,
            username: item.$2,
            score: item.$3,
            highlighted: item.$1 == '4',
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
    this.highlighted = false,
  });

  final String position;
  final String username;
  final String score;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}