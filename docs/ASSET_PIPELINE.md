# Pipeline de assets

## Modelos desde Blender

- Aplicar transformaciones antes de exportar y usar metros como unidad.
- Exportar a glTF Binary (`.glb`) con materiales y texturas empacados cuando sea conveniente.
- Mantener pivotes centrados y orientados hacia el frente del vehículo.
- Nombrar mallas de nivel de detalle `Mesh_LOD0`, `Mesh_LOD1`, `Mesh_LOD2` y colisiones `Col_Shape`.
- Separar colisiones de la geometría visible y evitar modificadores innecesarios en el archivo exportado.

## Texturas

- Preferir PNG para fuentes con transparencia y WebP para imágenes de trabajo apropiadas.
- Limitar texturas de props y UI a 2048 px por lado para la plataforma móvil salvo excepción documentada.
- Revisar compresión VRAM S3TC/BPTC en escritorio y ETC2/ASTC en móvil.
- Empacar mapas compatibles en atlas para reducir cambios de material y draw calls.

## Revisión y entrega

- Usar nombres en `snake_case`, conservar la fuente editable y registrar autor/licencia.
- Verificar escala, pivotes, orientación, LOD y colisión en una escena de inspección.
- Pasar `tools/asset_auditor.gd` antes de integrar contenido nuevo.
