# Biblia de audio

## Entrega técnica

- Mezcla final de música y contenido promocional: -14 LUFS integrados como referencia.
- True peak máximo de master: -1.0 dBTP.
- Frecuencia de proyecto y entregas maestras: 48 kHz.
- Exportar efectos mono cuando la fuente sea puntual; mantener música y ambientes amplios en estéreo.
- Los sonidos de juego deben ser originales o contar con licencia documentada.

## Eventos y prioridades

| Evento | Bus | Prioridad |
|---|---|---|
| Motor local y derrape | SFX_Kart_Local | Alta, ligado a velocidad y carga. |
| Motores rivales | SFX_Kart_Remote | Media, atenuación por distancia. |
| Colisión y aterrizaje | SFX_World | Alta, respuesta breve y clara. |
| Lanzamiento e impacto de objetos | SFX_Items | Alta en eventos cercanos. |
| Confirmación, navegación y avisos | SFX_UI | Media, nunca tapa alertas críticas. |
| Tema y transición de carrera | Music | Control independiente de efectos. |
| Voces de pilotos | Voice | Ducking de música si se implementa. |

## Mezcla

Dejar margen dinámico para impactos y mini-turbo, limitar picos accidentales y ofrecer controles separados de música, efectos y voces. Evitar fatiga con bucles largos y variaciones aleatorias deterministas cuando afecten a una repetición.
