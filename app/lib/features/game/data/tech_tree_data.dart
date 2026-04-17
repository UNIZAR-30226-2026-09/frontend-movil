import 'package:flutter/material.dart';
import 'package:soberania/features/game/models/tech_tree_model.dart';

class TechTreeData {
  const TechTreeData._();

  static const Size canvasSize = Size(1200, 790);

  // Dataset cargado desde el PDF "Arbol tecnologico".
  static const List<TechNodeModel> nodes = <TechNodeModel>[
    // Rama: Guerra Biologica
    TechNodeModel(
      id: 'bio_n1',
      name: 'NIVEL 1: GRIPE AVIAR',
      description:
          'Danio progresivo. El territorio objetivo pierde 1 tropa al final de cada turno durante 3 turnos.',
      tier: 1,
      cost: 1,
      branch: TechBranch.biologica,
      icon: Icons.coronavirus_outlined,
      position: Offset(120, 190),
    ),
    TechNodeModel(
      id: 'bio_n2a',
      name: 'NIVEL 2A: VACUNA UNIVERSAL',
      description:
          'Defensa sanitaria. Elimina inmediatamente cualquier efecto de enfermedad activo en territorio propio.',
      tier: 2,
      cost: 2,
      branch: TechBranch.biologica,
      icon: Icons.shield_outlined,
      position: Offset(40, 420),
      prerequisites: <String>['bio_n1'],
    ),
    TechNodeModel(
      id: 'bio_n2b',
      name: 'NIVEL 2B: FATIGA',
      description:
          'Sabotaje tactico. Aplica agotamiento y bloquea investigacion y generacion de dinero durante 2 turnos.',
      tier: 2,
      cost: 2,
      branch: TechBranch.biologica,
      icon: Icons.hourglass_bottom,
      position: Offset(230, 420),
      prerequisites: <String>['bio_n1'],
    ),
    TechNodeModel(
      id: 'bio_n3',
      name: 'NIVEL 3: CORONAVIRUS',
      description:
          'Expansion viral. Reduce tropas y tiene 25% de probabilidad de expandirse a territorios vecinos durante 2 rondas.',
      tier: 3,
      cost: 3,
      branch: TechBranch.biologica,
      icon: Icons.bubble_chart,
      position: Offset(130, 650),
      prerequisites: <String>['bio_n2a', 'bio_n2b'],
    ),

    // Rama: Operaciones y Logistica
    TechNodeModel(
      id: 'ops_n1',
      name: 'NIVEL 1: ACADEMIA MILITAR',
      description:
          'Mejora economica pasiva. Recibes 50% extra de tropas base en fase de refuerzos.',
      tier: 1,
      cost: 1,
      branch: TechBranch.operaciones,
      icon: Icons.account_balance,
      position: Offset(500, 190),
    ),
    TechNodeModel(
      id: 'ops_n2a',
      name: 'NIVEL 2A: INHIBIDOR DE SENAL',
      description:
          'Guerra electronica. Apaga un territorio enemigo durante un turno e impide dar ordenes a sus tropas.',
      tier: 2,
      cost: 2,
      branch: TechBranch.operaciones,
      icon: Icons.settings_input_antenna,
      position: Offset(420, 420),
      prerequisites: <String>['ops_n1'],
    ),
    TechNodeModel(
      id: 'ops_n2b',
      name: 'NIVEL 2B: PROPAGANDA SUBVERSIVA',
      description:
          'Conversion de unidades. El 50% de los refuerzos enemigos en ese territorio deserta o desaparece.',
      tier: 2,
      cost: 2,
      branch: TechBranch.operaciones,
      icon: Icons.campaign_outlined,
      position: Offset(610, 420),
      prerequisites: <String>['ops_n1'],
    ),
    TechNodeModel(
      id: 'ops_n3a',
      name: 'NIVEL 3A: MURO FRONTERIZO',
      description:
          'Bloqueo fisico. Cierra la conexion entre dos territorios durante 1 turno.',
      tier: 3,
      cost: 3,
      branch: TechBranch.operaciones,
      icon: Icons.fence,
      position: Offset(420, 650),
      prerequisites: <String>['ops_n2a'],
    ),
    TechNodeModel(
      id: 'ops_n3b',
      name: 'NIVEL 3B: SANCIONES INTERNACIONALES',
      description:
          'Asfixia total. El jugador objetivo no recibe tropas en su siguiente turno de refuerzo.',
      tier: 3,
      cost: 3,
      branch: TechBranch.operaciones,
      icon: Icons.public_off,
      position: Offset(610, 650),
      prerequisites: <String>['ops_n2b'],
    ),

    // Rama: Artilleria
    TechNodeModel(
      id: 'art_n1',
      name: 'NIVEL 1: MORTERO TACTICO',
      description: 'Ataque ligero de rango 2. Elimina 1d4 tropas.',
      tier: 1,
      cost: 1,
      branch: TechBranch.artilleria,
      icon: Icons.construction,
      position: Offset(920, 190),
    ),
    TechNodeModel(
      id: 'art_n2',
      name: 'NIVEL 2: MISIL DE CRUCERO',
      description: 'Ataque de precision de rango 3. Elimina 30% fijo de tropas.',
      tier: 2,
      cost: 2,
      branch: TechBranch.artilleria,
      icon: Icons.rocket_launch_outlined,
      position: Offset(920, 420),
      prerequisites: <String>['art_n1'],
    ),
    TechNodeModel(
      id: 'art_n3a',
      name: 'NIVEL 3: OPCION A - CABEZA NUCLEAR',
      description:
          'Destruccion masiva unitaria. Rango 3. Elimina 70% de tropas del objetivo.',
      tier: 3,
      cost: 3,
      branch: TechBranch.artilleria,
      icon: Icons.cloud,
      position: Offset(820, 650),
      prerequisites: <String>['art_n2'],
    ),
    TechNodeModel(
      id: 'art_n3b',
      name: 'NIVEL 3: OPCION B - BOMBA DE RACIMO',
      description:
          'Danio de area. 50% en objetivo principal y 30% en territorios colindantes.',
      tier: 3,
      cost: 3,
      branch: TechBranch.artilleria,
      icon: Icons.auto_awesome_motion,
      position: Offset(1020, 650),
      prerequisites: <String>['art_n2'],
    ),
  ];
}
