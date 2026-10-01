# AI Rogue 2D: reglas de trabajo

Este contrato es propio del juego 2D. No hereda motores, ramas, personajes,
plugins ni reglas de escenas del proyecto AIROG 3D.

## Fuentes y alcance

1. La petición actual de Bruno define la tarea y sus límites.
2. Este archivo define seguridad y forma de trabajar.
3. `Narrativa/00_MUST_READ_PARA_IAS.md` dirige al código y al documento necesario.
4. La biblia define identidad y propuestas narrativas; el juego y las pruebas
   frescas determinan qué existe. Una propuesta no se declara implementada.

Busca con `rg` antes de leer archivos grandes. Confirma raíz, rama y cambios
de las rutas del encargo. No leas todos los planes históricos por rutina.

## Motor y seguridad

- Godot 4.7.2 es la referencia para editar, importar, jugar y verificar.
  Otra versión es una prueba adicional, no cambia esta decisión.
- Usa `tools/run_visual_tests.ps1`: audio Dummy, timeout y procesos propios.
  No cierres editores ni juegos ajenos. Las capturas no prueban rendimiento.
- Las pruebas de guardado se ejecutan con el lanzador: cada ejecución usa
  `user://tests/<sesion>/`. Metajuego rechaza el almacenamiento de partidas reales.
- Conserva cambios ajenos. No uses `git add .`, `git commit -a`, resets ni
  restauraciones masivas. Revisa archivos exactos antes de integrar.
- No cambies de rama ni hagas pull sobre cambios sin proteger. El repo es
  compartido: cada cambio va en una rama corta y entra a `master` por PR.
  Nada de ramas `codex/…` ni worktrees dentro de otro proyecto.
- No borres assets, código legado o planes por parecer inútiles. Comprueba
  referencias y valor único antes de proponer su retirada.
- No añadas parches temporales, bypasses, mocks sustitutivos ni fallbacks nuevos
  sin permiso de Bruno. Diagnostica la causa; no escondas el error con un `if`.
- No controles otros chats ni lances otra IA sin autorización directa de Bruno.

## Código y verificación

- Reutiliza los componentes y perfiles reales. No copies el combate del
  minijuego de carga sobre el juego fuente ni mantengas dos versiones de habilidades.
- Acota cada cambio. No renombres rutas históricas ni traduzcas identificadores
  públicos mientras corriges otra cosa. Un movimiento requiere revisar referencias.
- Nuevos comentarios: español, breves, explican una decisión. Sin cajas decorativas,
  narración obvia ni firmas de IA. No traduzcas todo el código en una tanda mecánica.
- Reproduce el riesgo antes de editar. Revisa salida, stderr y código de salida.
  Un test fallido sigue siendo deuda; no lo retires por ser antiguo sin diagnóstico.
- Separa observación, hipótesis y causa comprobada. No confundas ausencia de
  errores con calidad visual, equilibrio o fluidez.
- Arte: escena completa y encuadre jugable, comparación antes/después y movimiento.
  Rendimiento: condiciones iguales, frío/caliente separados, sin juegos concurrentes.
- Bruno prueba cada tanda antes de ampliar diseño o habilidades. No acumules
  rediseños de menú, mapas y combate en una sola entrega.

## Escritura y cierre

- Documentación técnica: español claro, términos consistentes y frases concretas.
  Distingue sala, bioma, intento y run completada. No uses jerga para tapar dudas.
- Diálogo: consulta la biblia. No adoptes voseo ni mezcles idiomas por inercia;
  usa español neutro como criterio editorial nuevo, preservando el canon pendiente
  de aprobación. Cada voz debe ser reconocible sin leer el nombre del personaje.
- Los textos de código ficticio son un recurso del mundo, no la voz de todos
  los personajes ni instrucciones obligatorias para cada acción.
- Mensajes de commit: español, título breve con mayúscula, cambio concreto;
  sin firmas de IA, prompts pegados ni atribuciones a Bruno. No omitas hooks.
- Registra cambios, pruebas, pendientes y siguiente acción en el plan vigente.
  Las reglas no guardan resultados de cada sesión; `tmp/` no entra al commit.
