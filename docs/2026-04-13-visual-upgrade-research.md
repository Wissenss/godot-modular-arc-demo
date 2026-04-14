# Investigacion de Stack Visual para AI Rogue

Fecha: 2026-04-13

## Diagnostico honesto del intento anterior

El intento anterior no alcanzo un look profesional porque se apoyo en tres recursos demasiado superficiales:

1. Glows aditivos locales sin una logica de material ni de rebote.
2. Una composicion de foco demasiado simple, sin contraste claro entre zonas hero, zonas de lectura y periferia.
3. Ausencia de respuesta fisica basica en 2D: normales, especular controlado, sombras/occlusion creibles y correccion global de color.

La referencia del usuario funciona mejor porque combina:

- Jerarquia de iluminacion.
- Temperaturas separadas por zonas.
- Materiales que reaccionan distinto a la luz.
- Vignette y color grading para compactar toda la imagen.
- Focos hero con bloom y halation controlados.
- Fondos y UI integrados en la misma direccion de arte.

## Restriccion tecnica encontrada en el proyecto

El proyecto actual usa:

- `renderer/rendering_method="gl_compatibility"`

Esto es importante porque el renderer Compatibility en Godot 4 es el menos avanzado. Segun la documentacion oficial:

- Forward+ es el renderer mas avanzado.
- Compatibility es el menos avanzado y esta pensado para hardware viejo, web o proyectos que no necesitan features avanzados.
- Forward+ y Mobile tienen acceso a RenderingDevice y soporte para features nuevos primero.
- Compatibility no soporta varias capacidades modernas que ayudan al acabado visual.

Conclusion: si el objetivo principal es calidad visual desktop, el salto mas rentable no es un shader aislado, sino mover el proyecto a `Forward+` para escritorio y usar fallback solo donde realmente haga falta.

## Librerias y herramientas investigadas y descargadas

Se descargaron en:

- `sin usar/visual_research/third_party/`

### 1. Godot 4 Color Correction and Screen Effects

Ruta local:

- `sin usar/visual_research/third_party/Godot-4-Color-Correction-and-Screen-Effects`

Licencia:

- MIT

Valor:

- Es la mejor pieza inmediata para el look final de imagen.
- Sirve para color grading, vignette, bloom booster, halation, grain, sharpen, chromatic aberration, posterization y filtros globales.
- Encaja muy bien con un juego 2D estilizado porque permite “cerrar” la imagen con una direccion cinematica consistente.

Uso recomendado:

- Integrarlo como capa final de postproceso.
- Usar la version ligera para gameplay normal y una variante mas rica para menu, descanso, transiciones o habilidades.

Veredicto:

- `Recomendada como integracion principal de postproceso global.`

### 2. Godot Normal Map Generator

Ruta local:

- `sin usar/visual_research/third_party/godot_normalMap_generator`

Licencia:

- MIT

Valor:

- Permite generar normal maps desde texturas dentro del flujo de Godot.
- Es util para prototipar rapido respuesta de luz sobre tiles, props y enemigos.
- El propio proyecto aclara que para mejores resultados conviene Laigter.

Uso recomendado:

- Usarlo primero para pruebas rapidas dentro del editor.
- Una vez validado el pipeline, mover los assets mas importantes a mapas mejores hechos con una herramienta dedicada.

Veredicto:

- `Recomendada como herramienta de pipeline interno, no como acabado final de todos los assets.`

### 3. Godot Post Process Plugin

Ruta local:

- `sin usar/visual_research/third_party/Godot-Post-Process-Plugin`

Licencia:

- MIT

Hallazgo importante:

- Su README indica que el desarrollo se detuvo por una reescritura (`PostFX`).
- Nacio para Godot 4.2.

Valor:

- Tiene efectos utiles: vignette, grain, CRT/VHS, blur, glitch, chromatic aberration, outline.
- Puede servir como referencia de implementacion y para estudiar presets.

Riesgo:

- Base menos conveniente para apostar toda la direccion visual del proyecto.

Veredicto:

- `No usar como base principal. Mantener solo como referencia o banco de ideas.`

### 4. EffekseerForGodot4

Ruta local:

- `sin usar/visual_research/third_party/EffekseerForGodot4`

Licencia:

- MIT

Valor:

- Es la opcion mas seria para VFX de combate verdaderamente profesionales.
- Tiene un pipeline de efectos mucho mas fuerte para beams, flashes, impacto, trailing, bursts y patrones complejos.

Riesgo:

- La integracion es mas pesada.
- No es la mejor primera pieza si antes no resolvemos renderer, iluminacion base y materiales.

Veredicto:

- `Muy prometedora para la fase 2 de VFX de combate, no para ser el primer paso.`

## Herramienta externa recomendada pero no vendorizada

### Laigter

No se vendorizo dentro del repo por ahora, pero la documentacion oficial de Godot la menciona como herramienta libre y abierta para generar normal/specular maps cuando no existen.

Uso recomendado:

- Generar normal maps mejores para tiles clave, props metalicos, pantallas y enemigos.

Veredicto:

- `Muy recomendada como herramienta artistica externa.`

## Recomendacion final de stack

### Recomendacion principal

Para que el juego se vea verdaderamente mejor, el orden correcto no es “meter mas shaders”, sino este:

1. Cambiar desktop a `Forward+`.
2. Rehacer la iluminacion del cuarto con built-ins de Godot:
   - `CanvasModulate`
   - `PointLight2D`
   - `DirectionalLight2D` puntual solo donde aporte
   - `LightOccluder2D`
   - `CanvasTexture` con normal/specular maps
3. Integrar `Godot-4-Color-Correction-and-Screen-Effects` como cierre global de imagen.
4. Rehacer la composicion del cuarto con zonas:
   - foco hero
   - periferia oscura
   - guias de lectura
   - contraste frio/calido
   - materiales con distinta respuesta
5. Rehacer VFX de combate:
   - primero con mejor pipeline nativo
   - si sigue faltando nivel, evaluar `EffekseerForGodot4` para ataques clave

## Direccion artistica concreta para el bioma 0

El bioma 0 no necesita “mas luz”, necesita mejor luz:

- Base ambiental fria y oscura.
- Focos hero calidos o cyan-hot en puntos interactivos.
- Material metalico con especular discreto.
- Pantallas y energia con bloom contenido, no lavado.
- Vignette suave para concentrar mirada.
- Periferia mas apagada que el centro jugable.
- Separacion clara entre piso base, carriles, bordes, terminales y elementos interactivos.

## Propuesta de implementacion en bloques

### Bloque 1

- Cambiar renderer desktop a `Forward+`.
- Mantener una nota de fallback si luego se necesita web o hardware viejo.
- Integrar shader de color correction global en una escena de prueba.

### Bloque 2

- Crear un “lighting rig” real para `Brunich_tests`:
  - ambient base
  - hero lights
  - rim lights
  - occluders
  - specular response

### Bloque 3

- Generar normal maps para:
  - tile principal del piso
  - pantallas / paneles
  - props hero
  - cuerpo del MC
  - enemigo AI

### Bloque 4

- Rehacer VFX de combate:
  - beam
  - impactos
  - carga
  - sobrecalentamiento
  - feedback de habilidad del MC

### Bloque 5

- Ajustar composicion del cuarto por layout:
  - entradas
  - salida
  - arena central
  - rutas visuales
  - lugares de combate

## Decision recomendada

La mejor apuesta calidad/tiempo para este proyecto es:

- `SI` integrar `Godot-4-Color-Correction-and-Screen-Effects`
- `SI` usar `godot_normalMap_generator` para arrancar pipeline de normales
- `SI` reconstruir iluminacion con built-ins de Godot y normal/specular maps
- `NO` basar el proyecto en `Godot-Post-Process-Plugin`
- `MAYBE` usar `EffekseerForGodot4` despues, si el pipeline nativo aun no alcanza el nivel deseado

## Fuentes principales

- Godot docs: renderers
- Godot docs: 2D lights and shadows
- Godot docs: CanvasTexture
- Repositorios revisados y descargados:
  - KorinDev/Godot-Post-Process-Plugin
  - ArseniyMirniy/Godot-4-Color-Correction-and-Screen-Effects
  - krosseye/godot_normalMap_generator
  - effekseer/EffekseerForGodot4
