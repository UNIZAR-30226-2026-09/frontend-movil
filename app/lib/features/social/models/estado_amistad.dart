enum EstadoAmistad {
  pendiente,
  aceptada,
  rechazada,
}

EstadoAmistad estadoAmistadFromJson(String value) {
  switch (value.toUpperCase()) {
    case 'PENDIENTE':
      return EstadoAmistad.pendiente;
    case 'ACEPTADA':
      return EstadoAmistad.aceptada;
    case 'RECHAZADA':
      return EstadoAmistad.rechazada;
    default:
      return EstadoAmistad.pendiente;
  }
}

String estadoAmistadToJson(EstadoAmistad estado) {
  switch (estado) {
    case EstadoAmistad.pendiente:
      return 'PENDIENTE';
    case EstadoAmistad.aceptada:
      return 'ACEPTADA';
    case EstadoAmistad.rechazada:
      return 'RECHAZADA';
  }
}