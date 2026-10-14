# Blue Dash — Godot 4.4.1

Juego endless runner para Android, basado en las cuatro imágenes suministradas.

## Controles
- Android: toca para saltar y toca otra vez antes de aterrizar para doble salto.
- PC: ESPACIO, flecha arriba, W o clic izquierdo.
- Toca para iniciar o reintentar después de perder.

## Mecánicas
- Carrera automática, gravedad, salto + doble salto.
- Tachos sobre el suelo y gaviotas a tres alturas aleatorias.
- Colisión con hitboxes más pequeñas que los sprites.
- Dificultad/velocidad progresivas, puntuación y récord persistente.
- Fondo celeste con pasto en desplazamiento.

## Abrir en Godot
Instala Godot 4.4.1, abre `project.godot` y ejecuta F6/F5.

## Compilar APK con GitHub Actions
1. Crea un repositorio de GitHub y sube **todo el contenido** de esta carpeta, incluyendo `.github/workflows/android.yml`.
2. En GitHub ve a **Actions > Compilar APK Android > Run workflow** (o haz push a `main`).
3. Al finalizar, abre la ejecución y descarga **BlueDash-Android-APK** en *Artifacts*.
4. Extrae el ZIP: contiene `BlueDash.apk`. Instálalo en Android permitiendo la instalación desde esa fuente.

El pipeline genera una APK **debug firmada**, apropiada para pruebas e instalación manual. Para publicar en Play Store hay que configurar firma de producción y exportar AAB.

Las imágenes de `assets/` derivan de los archivos aportados por el usuario. Antes de distribuir públicamente, verifica que dispones de los derechos necesarios para usar el diseño del personaje y el resto de los gráficos.
