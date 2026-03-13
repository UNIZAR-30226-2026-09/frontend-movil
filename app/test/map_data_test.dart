import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:soberania/features/map/config/map_data.dart';

void main() {
  group('Validación de Integridad T56 - Grafo de Aragón', () {
    late Map<String, dynamic> mapJson;
    late Map<String, dynamic> comarcas;

    setUpAll(() {
      // Cargamos el JSON físicamente para el test
      final file = File('assets/json/map_aragon.json');
      mapJson = jsonDecode(file.readAsStringSync());
      comarcas = mapJson['comarcas'];
    });

    test('Sincronización JSON vs MapPaths (IDs correctos)', () {
      final idsEnJson = comarcas.keys.toSet();
      final idsEnDart = MapPaths.data.keys.toSet();

      // Comprobar si falta algo en Dart que esté en el JSON
      final faltanEnDart = idsEnJson.difference(idsEnDart);
      expect(faltanEnDart, isEmpty, 
        reason: 'Los siguientes IDs están en el JSON pero no tienen Path en MapPaths.data: $faltanEnDart');

      // Comprobar si sobra algo en Dart (IDs huérfanos)
      final faltanEnJson = idsEnDart.difference(idsEnJson);
      expect(faltanEnJson, isEmpty, 
        reason: 'Los siguientes IDs tienen Path en Dart pero no existen en el JSON: $faltanEnJson');
    });

    test('Simetría de Adyacencias (Si A toca a B, B debe tocar a A)', () {
      comarcas.forEach((id, data) {
        final List vecinos = data['adjacent_to'];
        for (String vecinoId in vecinos) {
          // El vecino debe existir
          expect(comarcas.containsKey(vecinoId), true, 
            reason: 'La comarca $id referencia a un vecino inexistente: $vecinoId');

          // Verificamos simetría
          final List vecinosDelVecino = comarcas[vecinoId]['adjacent_to'];
          expect(vecinosDelVecino.contains(id), true, 
            reason: 'Error de simetría: $id es vecino de $vecinoId, pero $vecinoId no tiene a $id en su lista.');
        }
      });
    });

    test('Detección de "Comarcas Isla" (Sin conexiones)', () {
      comarcas.forEach((id, data) {
        final List vecinos = data['adjacent_to'];
        expect(vecinos, isNotEmpty, 
          reason: 'La comarca $id no tiene vecinos definidos (es una isla).');
      });
    });
  });
}