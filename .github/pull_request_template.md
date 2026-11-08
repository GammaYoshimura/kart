## Resumen

<!-- Describe el cambio y su motivación. -->

## Comprobaciones

- [ ] Godot MCP ejecuta la escena afectada sin errores.
- [ ] Ejecuté `tools/run_all_checks.ps1` o expliqué por qué no aplica.
- [ ] Los recursos y archivos UID/importados necesarios están incluidos.

## Revisión de arquitectura

- [ ] La simulación no depende de presentación, cámara, audio ni UI.
- [ ] No se usa RNG global (`randf()` / `randi()`) desde simulación.
- [ ] Los comandos por tick y los estados serializables siguen versionados y tipados.
- [ ] El cambio respeta las capas de colisión y los presupuestos de Windows/Android.
- [ ] No se incluyó `ROADMAP.md`, secretos ni artefactos generados de exportación.
