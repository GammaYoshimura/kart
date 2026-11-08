# Estado del roadmap

Este registro acompaña a `ROADMAP.md`, que se mantiene fuera de Git por decisión del proyecto. Actualizar este archivo al completar cada hito y usarlo como punto de reanudación.

## Fase 0

### Completado y registrado en el historial Git

- [x] **F0-001–F0-011** Base del repositorio, estructura inicial y convenciones.
- [x] **F0-024–F0-027** Godot MCP reconoce el proyecto; escena de arranque creada y proyecto ejecutado.
- [x] **F0-030–F0-049** Esqueleto de arquitectura, servicios de plataforma, argumentos CLI, bootstrap y simulación serializable. `AndroidPlatformService` ya existe como andamiaje; no ampliarlo antes de Fase 11.
- [x] **F0-050–F0-058** Documentación de diseño/arte/audio, pipeline y fundamentos de assets.
- [x] **F0-059–F0-066** Framework de pruebas, tres pruebas unitarias (último resultado registrado: 3 aprobadas, 0 fallidas, 134 aserciones), monitor de rendimiento, overlay y escena smoke.
- [x] **F0-071–F0-072** Exportaciones Windows y servidor dedicado Windows/Linux creadas y ejecutadas; el servidor Windows se observó por debajo del límite de 80 MiB.
- [x] **F0-074, F0-077, F0-079** Script local de checks, plantilla de PR y arquitectura documentada.

### Parcial o pendiente

- [ ] **F0-012** Falta configurar un icono de aplicación; el export Android interrumpido señaló que no hay icono.
- [ ] **F0-013, F0-019, F0-021, F0-023** Completar y verificar ajustes explícitos de física, renderizado y advertencias/acciones de depuración.
- [ ] **F0-028** `get_uid` no encontró sidecar para una escena y `update_project_uids` no procesó escenas; revisar cuando toque la integridad de UID.
- [ ] **F0-067–F0-068** Presets Windows y servidor existen. Falta revisar el requisito de excluir assets pesados del servidor y confirmar la configuración completa.
- [ ] **F0-075** El workflow de CI existe, pero tenía indentación inválida en el bloque de descarga de Godot; corregido en esta continuación, queda pendiente verificarlo en GitHub Actions.
- [ ] **F0-076** Pendiente compilación automática Windows/servidor. Su parte Android queda aplazada.
- [ ] **F0-078** Ejecución MCP funciona, pero el último log mostró una advertencia de conexión de señal en `perf_overlay.gd`; corregida en esta continuación, pendiente volver a comprobar.
- [ ] **F0-080** No crear el tag de salida de Fase 0 mientras haya tareas no Android pendientes.

### Aplazado

- [ ] **F0-069, F0-070, F0-073 y parte Android de F0-076** Aplazados por instrucción del usuario hasta Fase 11. No trabajar en Android antes de entonces, excepto petición expresa del usuario.

## Punto actual

### Fase 1

- [x] **F1-001–F1-014** Recurso tipado `KartStatsResource`, sus parámetros de manejo, curvas por defecto generadas, validación de configuración y arquetipos equilibrado, ligero y pesado.
- [x] **F1-015–F1-019, F1-021** Fuentes abstracta, humana y guionizada; dirección analógica con zona muerta/curva, teclado suavizado en tres ticks, gatillos y botones de acelerador/freno del mando.
- [x] **F1-020** Buffer determinista de seis ticks para salto de derrape, consumible al tocar suelo.
- [x] **F1-022–F1-028** Estado serializable del kart con movimiento, suelo, superficie, derrape, turbo, colisiones y copia binaria; sin dependencias de nodos.
- [x] **F1-029** Cuerpo `CharacterBody3D` con esfera física, capas Kart_Hull y entrada de comandos por tick.
- [x] **F1-030** Pipeline por tick con fases separadas para suelo/superficie, temporizadores, hop/derrape, dirección, cinemática, gravedad y movimiento con colisiones.
- [ ] **F1-031–F1-032, F1-041** Completar modificadores de superficie/boost y proyección explícita de velocidades sobre los ejes del kart.
- [x] **F1-033–F1-040, F1-042** Sobrevelocidad, inercia/freno/reversa, suavizado de dirección, giro según velocidad, marcha atrás y agarre lateral.

**Verificación reciente:** el proyecto inició desde Godot MCP y `get_debug_output` devolvió `errors: []` tras añadir los recursos.

Siguiente trabajo de producto: **F1-031**, límites de velocidad con modificadores de superficie y turbo. El alcance de plataforma anterior a Fase 11 es Windows y servidor Linux/Windows.
