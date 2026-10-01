# Política de Privacidad de Cronos

**Última actualización:** 1 de octubre de 2026

Esta Política de Privacidad describe cómo **Cronos** ("la aplicación"), desarrollada de forma independiente por **fcastrodev** (Alejandro Castro), trata la información y privacidad de los usuarios.

---

### 1. Principio fundamental: Privacidad por diseño (100% Local y Offline)

Cronos es una herramienta de productividad y control del tiempo diseñada bajo la premisa de **privacidad absoluta**:

* **Sin servidores:** La aplicación funciona de manera completamente local. No poseemos, alquilamos ni operamos servidores para almacenar datos de los usuarios.
* **Sin cuentas ni registros:** No es necesario crear una cuenta, proporcionar tu nombre, correo ni ninguna credencial para utilizar la app.
* **Almacenamiento exclusivo en el dispositivo:** Toda tu información (tareas, actividades registradas, notas, horarios, rachas y métricas) se almacena únicamente en tu propio dispositivo a través de una base de datos local SQLite.

---

### 2. Permisos del sistema y su finalidad

Para ofrecer ciertas funciones avanzadas, Cronos puede solicitar permisos opcionales en Android:

* **Acceso a datos de uso (`PACKAGE_USAGE_STATS`):**
  * **Finalidad:** Permite la función de "App Tracking" y el análisis de productividad, detectando qué aplicaciones se utilizan en primer plano para vincularlas a actividades y cronómetros.
  * **Tratamiento:** Esta información se procesa localmente en el procesador de tu teléfono. **Nunca** se transmite a internet ni se comparte con terceros.
* **Notificaciones y servicios en primer plano (`POST_NOTIFICATIONS`, `FOREGROUND_SERVICE`):**
  * **Finalidad:** Mostrar la notificación persistente del cronómetro en curso y enviar recordatorios de tareas planificadas.
* **Biometría (`USE_BIOMETRIC`):**
  * **Finalidad:** Bloquear el acceso a la app con tu huella o reconocimiento facial mediante las APIs nativas del sistema. Cronos nunca tiene acceso a tus datos biométricos.
* **Cámara / Galería:**
  * **Finalidad:** Permitir al usuario seleccionar una imagen de perfil local si así lo desea.
* **Acceso a Internet (`INTERNET`):**
  * **Finalidad:** Consultar la API pública de GitHub Releases para comprobar si existen nuevas versiones de la aplicación. Esta consulta es de solo lectura y no envía ningún dato del usuario.

---

### 3. Servicios de terceros y publicidad

* **Sin publicidad:** Cronos no incluye anuncios de ninguna red publicitaria.
* **Sin rastreadores ni telemetría:** Cronos no integra SDKs de análisis de terceros (como Google Analytics, Firebase Analytics, Facebook SDK ni similares).

---

### 4. Respaldo y eliminación de datos

* **Control total del usuario:** Tienes control absoluto para exportar tus datos en formatos estándar (CSV, JSON, PDF) o realizar copias de seguridad locales.
* **Eliminación:** Puedes borrar todos los datos en cualquier momento desde los ajustes de la aplicación, borrando los datos de la app desde la configuración de Android o simplemente desinstalando la aplicación.

---

### 5. Modificaciones a esta política

Si en el futuro se incorpora alguna funcionalidad que requiera actualizar esta política, se publicará la versión actualizada en este mismo repositorio y en las notas de la versión.

---

### 6. Contacto

Si tienes cualquier duda, pregunta o sugerencia sobre esta Política de Privacidad, puedes ponerte en contacto con el desarrollador:

* **Desarrollador:** Alejandro Castro (fcastrodev)
* **Correo electrónico:** fcastrodev1@gmail.com
* **Repositorio oficial:** https://github.com/ale-fcastro/cronos
