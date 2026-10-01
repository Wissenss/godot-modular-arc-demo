# Organización y coherencia de AI Rogue 2D

## Alcance

Motor de referencia: Godot 4.7.2. Base `efad118`; entra a `master` por PR. Primero coherencia y pruebas; después diseño y jugabilidad por tandas
que Bruno prueba. No trasladar el canon ni los sistemas de AIROG 3D.

## Cambios Comprobados

- Entrada, directorio, README y reglas propios del 2D. `claude.md` dirige a
  las fuentes vigentes; no duplica el catálogo. Biblia revisada para distinguir
  identidad, propuestas y sistemas implementados.
- Guardados de pruebas aislados en `user://tests/<sesion>/`, usando SaveManager
  real. Metajuego rechaza el almacenamiento normal; el contrato de aislamiento
  verifica que los tres slots reales no cambien.
- Metajuego termina correctamente: su quit era inalcanzable. VFX libera las
  entidades del fixture; el lanzador considera errores de stdout y stderr.
- Foco no recarga mientras se mantiene pulsado el botón tras agotar la carga.
  Enemigos sin jugador siguen actualizando sus visuales.
- Escena general: fixture sin pausa narrativa, cooldown previo del dodge aislado,
  probes liberados y expectativas justificadas de CY, dash, spawn y cara.
  Haz robado: centro claro y borde morado, no exigir morado al centro claro.
- Menú y hub aceptan clic izquierdo, no derecho, para iniciar y comprar.
  El hub bloquea nuevas activaciones mientras cambia de escena.
- Esquema de guardado 2: intentos, runs completadas, muertes y resultado separados.
  El contador antiguo migra a intentos; recursos y mejoras se conservan. No se
  inventan victorias o muertes antiguas. Migración sin escritura al leer previews.
- Primera run termina tras las tres capas digitales; siguientes tras cuatro.
  Final y muerte son idempotentes. Hackeo disponible tras el primer final.
  Contadores y reflexión del hub distinguen éxito, muerte y resultado desconocido.
- Atlas industrial nativo y cara a escala 0.76 conservan rejilla de 32 px,
  layouts, velocidad y alcance del robo originales.
- El cambio de `project.godot` a 4.7 procede del editor de Bruno. Se conserva.

## Verificación

Las pruebas se ejecutan secuencialmente con audio Dummy, timeout y procesos propios.
`tools/run_suite.ps1` incluye 20 smoke tests y cinco contratos adicionales:
visual, guardados, mouse del hub, progresión/migración y límites de interfaz.
Las capturas de menú y hub muestran contadores separados, sin recortes.
No es una certificación de rendimiento, equilibrio o calidad visual.

Batería en 4.7.2 tras la limpieza (01-10): 25 de 25 con código 0 y sin ERROR.
Referencias literales res:// de scenes/scripts sin destinos faltantes; no cubre
rutas dinámicas, addons ni carga de partidas. Logs y capturas en `tmp/`.

## Limpieza hecha

Retirados `sin usar/` (53 archivos sin referencias desde el juego activo), las
láminas de `art/_beta3_analysis/` (7.4 MB), la prueba de capas 2.5D de Beta3 y
los planes y specs viejos de `docs/`. Los sprites originales `art/beta3*` se
conservan. Todo sigue en el historial de Git.

## Problemas Abiertos y Orden

1. Bruno prueba final, contadores, desbloqueo y regreso al hub antes de ampliar
   historia. La materialización y el contenido físico siguen siendo propuestas.
2. Mapas: segunda sala de cada bioma mide 200x100 tiles frente a 40x20;
   25 veces más celdas, experimento activo sin benchmark en esta tanda.
   Unificar definición de sala, spawns, cámara, límites, decoración y luces.
3. Probar spawn seguro, puerta accesible, límites de proyectiles, limpieza y
   reentrada antes de extraer responsabilidades del orquestador.
4. Mejorar jerarquía visual en un solo mapa: props luminosos y capas oscuras
   dominan los tiles. Biblia contempla 64 px, implementación usa 32; no migrar
   automáticamente la rejilla.
5. Menú/hub siguen con hit-test manual; pendiente navegación con foco y Controls.
   Archivista está en el hub. Revisar voces en español neutro sin convertir
   a todos los personajes en consolas.
6. Después ampliar poderes, enemigos, dificultad y mapas. No integrar todavía
   este juego al minijuego de carga: requerirá tiempo local, no Engine.time_scale.
