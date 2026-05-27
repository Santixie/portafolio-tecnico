# Evaluación 1 – Ciberseguridad Ofensiva

**Asignatura:** OCY1104 – Ciberseguridad Ofensiva  
**Fecha:** 14 de abril de 2026  
**Estudiante:** Benjamín Santis Hermosilla

---

## Descripción

Análisis de vulnerabilidades sobre la máquina virtual Metasploitable3 utilizando Nessus Essentials desde Kali Linux. El objetivo fue identificar, clasificar y analizar fallas de seguridad en un entorno controlado aplicando principios de ciberseguridad ofensiva.

---

## Entorno

| Máquina        | IP         | Rol      |
|----------------|------------|----------|
| Kali Linux     | 10.0.2.5   | Atacante |
| Metasploitable | 10.0.2.15  | Objetivo |

Ambas máquinas conectadas en red NAT mediante VirtualBox.

---

## Herramientas utilizadas

- **Nessus Essentials** – escaneo avanzado de vulnerabilidades (Advanced Scan)
- **VirtualBox** – virtualización del entorno de laboratorio
- **ping** – verificación de conectividad entre máquinas

---

## Desarrollo

### 1. Configuración de máquinas virtuales

Se configuraron ambas VMs con adaptador de red NAT bajo la misma red `NatNetwork`. Se verificó conectividad con `ping` antes de iniciar el análisis.

### 2. Configuración de Nessus

Se instaló y configuró Nessus Essentials en Kali Linux con cuenta de administrador local. Se creó una carpeta de escaneo `EVA1` para organizar los resultados.

### 3. Escaneo a Metasploitable

Se ejecutó un **Advanced Scan** contra `10.0.2.15`. El escaneo tomó 20 minutos y detectó **44 vulnerabilidades** clasificadas por severidad CVSS v3.0.

---

## Vulnerabilidades críticas identificadas

### a. Canonical Ubuntu Linux SEoL — CVSS 10.0 (Crítica)

El sistema operativo no recibe parches de seguridad. Cualquier nueva CVE descubierta quedará permanentemente sin remediar, exponiendo toda la infraestructura desde su base.

### b. ProFTPD mod_copy – Divulgación de información — CVSS 9.8 (Crítica)

El módulo `mod_copy` permite copiar y mover archivos en el servidor sin autenticación. Un atacante remoto puede robar datos confidenciales o sobrescribir archivos clave sin credenciales.

### c. RCE por deserialización en Drupal — CVSS 10.0 (Crítica)

Falla en la aplicación web que permite ejecutar código malicioso de forma remota sin autenticación. Con una sola petición manipulada, un atacante puede tomar control total del servidor.

---

## Análisis contextual

**Principios ofensivos aplicados:** verificación de conectividad con `ping`, seguido de escaneo sistemático con Nessus para mapear servicios activos y vulnerabilidades, priorizando por severidad CVSS.

**Tácticas de ataque posibles:**
- ProFTPD: conexión sin autenticación para copiar archivos sensibles
- Drupal RCE: envío de payload malicioso para instalar una reverse shell
- Ubuntu SEoL: uso de exploits de kernel públicos para escalada de privilegios

**Contribución de las herramientas:** Nessus identificó las 44 vulnerabilidades de forma automática comparando servicios detectados contra su base de datos de CVEs, permitiendo priorizar rápidamente sin análisis manual.

---

## Resultado del escaneo

| Severidad | Cantidad |
|-----------|----------|
| Crítica   | 3        |
| Alta      | ~9       |
| Media     | ~9       |
| Baja      | ~4       |
| Info      | ~19      |
| **Total** | **44**   |
