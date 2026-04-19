import 'package:flutter/material.dart';
import 'package:soberania/features/game/models/tech_tree_model.dart';

class TechTreeData {
  const TechTreeData._();

  static const Size canvasSize = Size(1200, 790);

  // Dataset cargado desde el PDF "Arbol tecnologico".
  static const List<TechNodeModel> nodes = <TechNodeModel>[
    // Rama: Guerra Biologica
    TechNodeModel(
      id: 'gripe_aviar',
      name: 'NIVEL 1: GRIPE AVIAR',
      description:
          'Infeccion persistente. Al inicio del refuerzo del afectado resta 1 tropa por turno durante 3 rondas. Puede neutralizar el territorio.',
      tier: 1,
      cost: 500,
      branch: TechBranch.biologica,
      icon: Icons.coronavirus_outlined,
      position: Offset(120, 190),
    ),
    TechNodeModel(
      id: 'vacuna_universal',
      name: 'NIVEL 2A: VACUNA UNIVERSAL',
      description:
          'Defensa sanitaria sobre territorio propio. Elimina Gripe Aviar, Coronavirus y Fatiga en la red de territorios propios conectados.',
      tier: 2,
      cost: 1000,
      branch: TechBranch.biologica,
      icon: Icons.shield_outlined,
      position: Offset(40, 420),
      prerequisites: <String>['gripe_aviar'],
    ),
    TechNodeModel(
      id: 'fatiga',
      name: 'NIVEL 2B: FATIGA',
      description:
          'Sabotaje tactico de hasta 3 saltos. Bloquea trabajo e investigacion del territorio durante 2 rondas. No se acumula sobre fatiga activa.',
      tier: 2,
      cost: 1500,
      branch: TechBranch.biologica,
      icon: Icons.hourglass_bottom,
      position: Offset(230, 420),
      prerequisites: <String>['gripe_aviar'],
    ),
    TechNodeModel(
      id: 'coronavirus',
      name: 'NIVEL 3: CORONAVIRUS',
      description:
          'Impacto inicial del 40% y daño recurrente del 10% al inicio del refuerzo del afectado. Se expande a vecinos con 25% por vecino al final de ronda. Duracion base: 2 rondas por jugador.',
      tier: 3,
      cost: 2500,
      branch: TechBranch.biologica,
      icon: Icons.bubble_chart,
      position: Offset(130, 650),
      prerequisites: <String>['vacuna_universal', 'fatiga'],
    ),

    // Rama: Operaciones y Logistica
    TechNodeModel(
      id: 'academia_militar',
      name: 'NIVEL 1: ACADEMIA MILITAR',
      description:
          'Pasiva permanente. Multiplica por 1.5 (redondeo hacia arriba) los refuerzos al inicio del turno. Se aplica antes de propaganda y no aplica con sanciones.',
      tier: 1,
      cost: 500,
      branch: TechBranch.operaciones,
      icon: Icons.account_balance,
      position: Offset(500, 190),
    ),
    TechNodeModel(
      id: 'inhibidor_senal',
      name: 'NIVEL 2A: INHIBIDOR DE SENAL',
      description:
          'Control tactico de zona de hasta 2 saltos. Bloquea los ataques convencionales desde el territorio afectado durante 1 turno.',
      tier: 2,
      cost: 1000,
      branch: TechBranch.operaciones,
      icon: Icons.settings_input_antenna,
      position: Offset(420, 420),
      prerequisites: <String>['academia_militar'],
    ),
    TechNodeModel(
      id: 'propaganda_subversiva',
      name: 'NIVEL 2B: PROPAGANDA SUBVERSIVA',
      description:
          'Sabotaje sobre jugador enemigo. Roba el 50% de sus refuerzos calculados y los transfiere al atacante. Dura 2 turnos de la victima.',
      tier: 2,
      cost: 1500,
      branch: TechBranch.operaciones,
      icon: Icons.campaign_outlined,
      position: Offset(610, 420),
      prerequisites: <String>['academia_militar'],
    ),
    TechNodeModel(
      id: 'muro_fronterizo',
      name: 'NIVEL 3A: MURO FRONTERIZO',
      description:
          'Defensa fronteriza de rango exacto 1 salto. Sella la frontera en ambos sentidos durante 1 turno, sin bloquear fortificacion.',
      tier: 3,
      cost: 1500,
      branch: TechBranch.operaciones,
      icon: Icons.fence,
      position: Offset(420, 650),
      prerequisites: <String>['inhibidor_senal'],
    ),
    TechNodeModel(
      id: 'sanciones_internacionales',
      name: 'NIVEL 3B: SANCIONES INTERNACIONALES',
      description:
          'Ataque economico sobre jugador enemigo. Su siguiente refuerzo pasa a 0 tropas con prioridad sobre academia y propaganda. Duracion: 1 turno.',
      tier: 3,
      cost: 2500,
      branch: TechBranch.operaciones,
      icon: Icons.public_off,
      position: Offset(610, 650),
      prerequisites: <String>['propaganda_subversiva'],
    ),

    // Rama: Artilleria
    TechNodeModel(
      id: 'mortero_tactico',
      name: 'NIVEL 1: MORTERO TACTICO',
      description:
          'Artilleria ligera de rango exacto 2 saltos. Inflige entre 1 y 4 bajas fijas aleatorias en el territorio objetivo.',
      tier: 1,
      cost: 500,
      branch: TechBranch.artilleria,
      icon: Icons.construction,
      position: Offset(920, 190),
    ),
    TechNodeModel(
      id: 'misil_crucero',
      name: 'NIVEL 2: MISIL DE CRUCERO',
      description:
          'Ataque de precision de hasta 3 saltos. Inflige un 30% de bajas sobre las tropas del territorio objetivo.',
      tier: 2,
      cost: 1500,
      branch: TechBranch.artilleria,
      icon: Icons.rocket_launch_outlined,
      position: Offset(920, 420),
      prerequisites: <String>['mortero_tactico'],
    ),
    TechNodeModel(
      id: 'cabeza_nuclear',
      name: 'NIVEL 3: OPCION A - CABEZA NUCLEAR',
      description:
          'Destruccion masiva unitaria de hasta 3 saltos. Inflige daño fijo elevado al territorio objetivo.',
      tier: 3,
      cost: 3000,
      branch: TechBranch.artilleria,
      icon: Icons.cloud,
      position: Offset(820, 650),
      prerequisites: <String>['misil_crucero'],
    ),
    TechNodeModel(
      id: 'bomba_racimo',
      name: 'NIVEL 3: OPCION B - BOMBA DE RACIMO',
      description:
          'Daño de area de hasta 3 saltos. Inflige daño fijo al objetivo principal y daño porcentual a todos los territorios colindantes.',
      tier: 3,
      cost: 2000,
      branch: TechBranch.artilleria,
      icon: Icons.auto_awesome_motion,
      position: Offset(1020, 650),
      prerequisites: <String>['misil_crucero'],
    ),
  ];
}
