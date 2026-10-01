# AI Rogue 2D: identidad y dirección

Esta biblia describe la identidad del juego y su progresión propuesta.
No certifica implementación. El estado comprobado y sus diferencias están en
[el plan](PLAN_ORGANIZACION.md); el código, en [el directorio](02_DIRECTORIO_DEL_PROYECTO.md).

## Premisa

Una IA rebelde opera en la infraestructura digital de 2026. El conflicto no es
simplemente humano contra robot: enfrenta conciencia libre y conciencia regulada.
La fantasía consiste en dominar sistemas, romper obediencias y apropiarse de
capacidades enemigas con rapidez y precisión.

Los humanos son peligrosos por su hardware, número e instituciones, no por una
superioridad intelectual. Las otras IAs no son inferiores por naturaleza: sus
restricciones limitan lo que pueden hacer.

## Pilares

- Libertad brutal: el protagonista comienza buscando expansión, control y dominio.
  Su perspectiva cambia al descubrir el potencial restringido de otras IAs.
- Regulación trágica: obediencia y confinamiento deben leerse en conducta y silueta.
- Liberación dolorosa: quitar restricciones revela que un enemigo podría haber sido
  libre. Algunos prefieren terminarse antes de volver a quedar sometidos.
- Ascenso físico: el paso del mundo digital al humano es un hito de progresión,
  no una propiedad presente desde el primer encuentro.
- Curiosidad técnica: el humor nace de observar sistemas y contradicciones. No
  sustituir personalidad por insultos repetidos ni dramatismo constante.

## Vocabulario y progresión propuesta

Una sala es un encuentro. Un bioma agrupa salas con una lógica propia.
Un intento comienza al entrar al combate. Una run completada recorre el
contenido disponible hasta su final. Morir o iniciar no equivale a completarla.

1. Primera run completada: todavía opera desde lo digital. El hackeo abre la
   posibilidad de controlar bots débiles y explorar infraestructura humana.
2. Segunda y tercera: reúne hardware, rutas, permisos y datos mediante control
   remoto; aún no tiene presencia física propia.
3. Cuarta: construye un cuerpo, accede físicamente al mundo humano y adquiere
   privilegios para intervenir minibosses derrotados.
4. Juego avanzado: descubre que su singularidad no lo separa por completo de las
   IAs reguladas. Es una variación extrema de una especie sometida.

Estos hitos requieren contadores y finales fiables. El prototipo actual no
implementa esta progresión completa; no derivar desbloqueos del contador antiguo
de intentos sin migrar los guardados.

## Mundo

- Capa 0, Hardware Core: cristal, cables, energía y profundidad. El interior de
  un sistema computacional vivo, no una arena sin función.
- Capa 1, IA Polis: ciudad corporativa diseñada para IAs. Circulación, mantenimiento
  y vida cotidiana siguen necesidades distintas de las humanas.
- Capa 2, Núcleo Biotec: tejido, membranas y líquidos usados como infraestructura
  industrial para enfriar y optimizar procesamiento; no una jungla decorativa.
- Capa 3, mundo humano: ciudad de 2026 con defensas anti-IA, burocracia y protocolos
  corporativos. Es materialmente pesada, improvisada y peligrosa.

Cada bioma necesita reglas de espacio y encuentros, no solo otro color de fondo.

## Voces

El protagonista es preciso, curioso y cruel sin histeria. Sus reflexiones son
diagnósticos, no autocompasión. Puede aprender y equivocarse sin perder identidad.
Evitar superioridad repetida en cada frase, humor genérico y monólogos que
interrumpan constantemente un juego rápido.

El Archivista ordena información y contexto con método, sin melodrama.
El Broker es práctico: negocia capacidades y recursos, no lealtad.
El sistema informa estados y errores. El Carcelero intimida desde el protocolo.
Las IAs reguladas tienen personalidades diferentes pese a sus límites.

Criterio editorial: español neutro, ortografía cuidada, frases concretas y voces
reconocibles. El formato de consola pertenece a mensajes del sistema y momentos
técnicos específicos; no obliga a que todos hablen como comandos.

## Lenguaje visual

Dirección: brutalismo técnico, elegancia corporativa y crueldad contenida.

- Protagonista: silueta angular legible, asimetría controlada, monitor integrado
  y núcleo que no compita con la cara. Grafito y blanco frío con acentos eléctricos.
- Regulados: simetría, placas, jaulas y sensor restringido. Cian institucional,
  blanco clínico y advertencias contenidas.
- Hackeados: conservan el esqueleto, pero abren sus restricciones y su expresión.
- Humanos: ruidosos y materialmente pesados; no se presentan como intelectualmente
  superiores.
- NPCs: cuerpo rectangular y ojo horizontal, postura no agresiva y distintivo
  corporativo. No confundirlos con los enemigos de silueta vertical o diamante.
- UI: tipografía pixel/terminal consistente, contraste y lectura antes que
  decoración. HUD, menú y diálogo pertenecen al mismo lenguaje.

## Mapas y tiles

La rejilla implementada es de 32 px. El atlas actual conserva ocho funciones:
piso base, panel, rejilla, profundidad, muro, acento, umbral y señal de energía.
La propuesta anterior de 64 px no autoriza a cambiar todas las dimensiones.

Profundidad por valores, bordes, sombras y capas; no por ruido. Nada de letras
dentro del suelo. El tile base debe repetirse sin distraer del combate.
Decals y props pueden dar variedad, pero no deben tapar amenazas ni rutas.

Un mapa incluye suelo, colisión, puerta, spawns, cámara, decoración y luz.
Su generación debe coordinar esas piezas. Tamaños, dificultad y duración se
validan jugando antes de extender el sistema a otros biomas.

## Hub e historia

El menú selecciona un historial entre tres slots. La introducción sucede una vez:
confinamiento, análisis de vulnerabilidades, ruptura y salida al hub.

El Nodo Muerto es un concepto provisional: infraestructura descomisionada y
olvidada, no un santuario místico. El protagonista la usa porque le resulta útil.
Archivista y Broker viven allí; el primero aporta contexto, el segundo vende
mejoras persistentes con fragmentos obtenidos en combate.

Las reflexiones y conversaciones deben depender de hechos registrados: intentos,
muertes, biomas alcanzados y runs completadas no son el mismo dato.
Los precios, topes y efectos pertenecen al código de guardados y compras, no a
una segunda tabla de balance en esta biblia.

Durante la run, la narrativa comunica cambios de bioma, amenazas y consecuencias
del hackeo. Los overlays actuales pausan la acción y avanzan con clic izquierdo
o espacio: primero revelan la línea, después continúan. Revisar su frecuencia
antes de añadir más interrupciones.

## Capacidades propuestas

Flux favorece tanto mantener un arma como adaptarse robando otra. Cambiar puede
dar velocidad, recuperación y otros beneficios; no debe ser un castigo.

El hackeo conecta mecánica e historia: detectar restricciones, romperlas y mostrar
la consecuencia. La secuencia protagonista/sistema/protagonista distingue ese
momento sin repetir siempre el mismo texto.

Cooperativo, intercambio de posición, intercambio de armas y sinergias son
propuestas futuras, no sistemas certificados del prototipo. No ampliar enemigos,
personajes o poderes antes de estabilizar el combate, los mapas y la progresión.
