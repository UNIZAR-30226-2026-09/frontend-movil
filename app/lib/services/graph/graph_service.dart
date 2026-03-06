import 'dart:collection';
import '../../models/territory_model.dart';

class GraphService {
  // Usamos un Map donde la clave es el ID de la comarca y el valor es su lista de vecinos
  final Map<String, List<String>> _grafo = {};

  /// Constructor que ingesta los datos y construye el grafo
  GraphService(List<Comarca> comarcas) {
    _construirGrafo(comarcas);
  }

  /// Traduce la lista de modelos al formato de adyacencias
  void _construirGrafo(List<Comarca> comarcas) {
    for (var comarca in comarcas) {
      _grafo[comarca.id] = List.from(comarca.adjacentTo);
    }
  }

  /// ALGORITMO BFS (Búsqueda en Anchura)
  Set<String> obtenerComarcasEnRango(String origenId, int rangoMaximo) {
    // Verificamos si la comarca existe para evitar errores
    if (!_grafo.containsKey(origenId)) return {};

    // Conjunto para evitar ciclos y repetir comarcas 
    final Set<String> visitados = {origenId};
    
    // Si el rango es 0, solo devolvemos el origen
    if (rangoMaximo <= 0) return visitados;

    // Cola para el BFS: guarda [ID de comarca, distancia actual]
    final Queue<List<dynamic>> cola = Queue();
    cola.add([origenId, 0]);

    while (cola.isNotEmpty) {
      final actual = cola.removeFirst();
      final String idActual = actual[0];
      final int distanciaAcumulada = actual[1];

      // Exploramos los vecinos de la comarca actual
      final vecinos = _grafo[idActual] ?? [];
      
      for (final vecinoId in vecinos) {
        if (!visitados.contains(vecinoId)) {
          visitados.add(vecinoId);
          final int nuevaDistancia = distanciaAcumulada + 1;

          // Si aún no hemos llegado al límite del rango, seguimos explorando
          if (nuevaDistancia < rangoMaximo) {
            cola.add([vecinoId, nuevaDistancia]);
          }
        }
      }
    }

    // Siguiendo la lógica de la web: No se puede atacar a uno mismo
    visitados.remove(origenId);
    
    return visitados;
  }
}