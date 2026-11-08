# Arquitectura del juego

## Capas

- `src/core/`: versión, arranque, logging y servicios compartidos.
- `src/simulation/`: estado y reglas deterministas independientes de presentación.
- `src/platform/`: entrada, pantalla, ciclo de vida, almacenamiento y adaptadores por plataforma.
- `src/presentation/`, `src/ui/` y `src/audio/`: representación, interfaz y sonido.
- `src/network/`: transporte, serialización de protocolo y cliente/servidor.
- `resources/`, `scenes/` y `assets/`: datos de juego, escenas y contenido visual/sonoro.

## Dependencias

La simulación no accede a nodos de presentación, cámaras, audio ni controles de UI. Presentación consume estados de simulación y eventos; no modifica el estado autoritativo directamente. Las entradas de cliente y bots se convierten en `InputCommandFrame` por tick antes de entrar al mundo simulado.

## Tick y estado de entrada

La simulación avanza a 60 Hz mediante `SimulationClock` y `SimulationWorld.step_tick()`, invocados explícitamente para facilitar rollback y ejecución headless. `InputCommandFrame` contiene tick de 32 bits, dirección de -1000 a 1000, acelerador y freno de 0 a 1000, y máscara de botones. El frame de red ocupa 10 bytes: tick uint32, dirección int16, dos ejes normalizados a 8 bits y botones uint16.

## Autoridad de red

En multijugador, el servidor dedicado valida entradas, avanza la simulación autoritativa y distribuye snapshots. El cliente predice su propio kart y reconcilia el estado con snapshots del servidor. El protocolo y los esquemas de pista y guardado llevan versiones independientes en `VersionInfo`.

## Tick de conducción del kart

`KartSimBody.simulate_tick(command, delta)` procesa cada tick en este orden:

1. Actualiza el frame de entrada y el buffer de hop.
2. Consulta cinco sensores de suelo y aplica los metadatos de la superficie detectada.
3. Actualiza turbo, tiempos de contacto, hop, derrape y carga de mini-turbo.
4. Suaviza la dirección, ajusta el giro por velocidad y calcula rumbo.
5. Aplica aceleración, freno/reversa y agarre lateral según suelo/derrape/aire.
6. Aplica gravedad y conserva la velocidad tangencial al avanzar por pendientes.
7. Mueve el cuerpo físico, resuelve contactos, actualiza `KartSimState` y emite eventos de aterrizaje/choque.

`KartSimState` contiene el estado serializable, sin referencias a nodos de escena. `KartCollisionResolver` resuelve pares de estados ordenados por slot. `KartVisualNode` interpola transforms y anima suspensión/ruedas/chasis; `KartCamera3D` consume el estado y eventos sin escribir en la simulación.
