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
