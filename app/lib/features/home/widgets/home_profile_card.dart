import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_routes.dart';

class HomeProfileCard extends StatelessWidget {
  const HomeProfileCard({
    super.key,
    required this.username,
  });

  final String username;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          context.push(AppRoutes.perfil);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF252530).withOpacity(0.92),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFC5A059),
              width: 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFF1A1A24),
                child: Icon(
                  Icons.person,
                  color: Color(0xFFC5A059),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                username,
                style: const TextStyle(
                  color: Color(0xFFF0F0F5),
                  fontSize: 16,
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