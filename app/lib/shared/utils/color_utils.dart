import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

class ColorUtils {
  static Color getColorRegion(String regionId) {
    switch (regionId) {
      case 'frontera_pirenaica':
        return AppTheme.regionPirineosBase;
      case 'estepas_y_condados':
        return AppTheme.regionEstepasBase;
      case 'alto_ebro':
        return AppTheme.regionEbroBase;
      case 'campos_serrania':
        return AppTheme.regionCamposBase;
      case 'valles_matarrana':
        return AppTheme.regionVallesBase;
      case 'sierras_sur':
        return AppTheme.regionSierrasBase;
      default:
        return AppTheme.mapLandNeutral;
    }
  }

  static Color getPlayerColor(int numeroJugador) {
    switch (numeroJugador) {
      case 1:
        return AppTheme.player1;
      case 2:
        return AppTheme.player2;
      case 3:
        return AppTheme.player3;
      case 4:
        return AppTheme.player4;
      default:
        return AppTheme.mapLandNeutral;
    }
  }

  static const Color origenColor = AppTheme.mapSelectOrigin;
  static const Color resaltadoColor = AppTheme.mapSelectTarget;
  static const Color bordeColor = AppTheme.borderGoldVivo;
}
