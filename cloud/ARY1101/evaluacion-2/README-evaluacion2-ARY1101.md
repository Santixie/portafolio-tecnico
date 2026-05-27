# Evaluación 2 — ARY1101 Infraestructura Cloud II

## Objetivo

Diseñar e implementar una arquitectura de Alta Disponibilidad (HA) sobre la infraestructura base de TechNova Solutions en AWS, incorporando monitoreo continuo, respaldo automatizado y pruebas de continuidad operacional.

## Evidencia

- [`Evaluación 2 - Infraestructura Cloud II.pdf`](./Evaluación%202%20-%20Infraestructura%20Cloud%20II.pdf) — Informe técnico completo
- [`Evaluación 2 - Infraestructura Cloud II -- Presentacion.pdf`](./Evaluación%202%20-%20Infraestructura%20Cloud%20II%20--%20Presentacion.pdf) — Presentación de la evaluación

> La infraestructura base se despliega con el mismo template CloudFormation de la Evaluación 1 (`../evaluacion-1/cloudformation/technova-stack-fixed.yaml`).

---

## Arquitectura de Alta Disponibilidad (HA)

La solución distribuye recursos en dos zonas de disponibilidad (`us-east-1a` y `us-east-1b`) para eliminar puntos únicos de falla.

### Componentes principales

**Application Load Balancer — `alb-technova`**
- Tipo Internet-facing, distribuye tráfico HTTP (puerto 80) hacia el Target Group `tg-technova`
- Security Group dedicado `technova-sg-alb` con entrada en puertos 80 y 443
- DNS: `alb-technova-1693801865.us-east-1.elb.amazonaws.com`

**Auto Scaling Group — `asg-technova`**
- Launch Template `lt-technova` basado en AMI `ami-technova-apache`
- Capacidad mínima: 2 instancias, deseada: 2, máxima: 3
- Distribución equilibrada entre `us-east-1a` y `us-east-1b`
- Health check integrado con el ALB

**Instancias EC2 — `t3.small`**
- 2 vCPU, 2 GB RAM, volumen EBS gp3 50 GB cifrado
- Apache instalado sirviendo la página de TechNova Solutions
- Agente CloudWatch instalado para envío de métricas
- Perfil IAM `LabInstanceProfile` asignado

**RDS MySQL Multi-AZ — `rds-technova`**
- Motor MySQL 8.4, clase `db.t3.micro`, 50 GB gp3 cifrado
- Primaria en `us-east-1a`, standby en `us-east-1b`
- Conmutación automática ante fallas de zona

### AMIs creadas
| AMI | ID | Descripción |
|---|---|---|
| `ami-technova-base` | `ami-04d33bb967826742a` | AMI base sin Apache |
| `ami-technova-apache` | `ami-0d42a0ae09117e499` | AMI con Apache y CloudWatch Agent — usada por el ASG |

### Security Groups
| SG | Puertos de entrada |
|---|---|
| `technova-sg-alb` | 80, 443 desde `0.0.0.0/0` |
| `sg_ec2_technova` | 22 (SSH), 80, 443, 3001 desde `sg-alb` |
| `sg_rds_technova` | 3306 solo desde `sg_ec2_technova` |

---

## Monitoreo y Alertas

**CloudWatch Agent** instalado en todas las EC2, recolectando cada 60 segundos:
- CPU: `cpu_usage_user`, `cpu_usage_idle`, `cpu_usage_system`
- Memoria: `mem_used_percent`, `mem_available`
- Disco: `disk_used_percent` en `/`

**Dashboard `dashboard-technova`** con tres widgets de línea temporal: CPU Usage, Memory Usage y Disk Usage para ambas instancias del ASG.

**Alarmas CloudWatch** con notificación vía SNS (`sns-technova-alertas` → `benj.santis@duocuc.cl`):
- `alarma-cpu-technova` — se activa si `cpu_usage_user > 75%` durante 1 período de 60 segundos
- `alarma-memoria-technova` — se activa si `mem_used_percent > 75%` durante 1 período de 5 minutos

La alarma de CPU fue validada generando carga del 99.9% con la herramienta `stress`, confirmando el envío del correo de alerta.

---

## Respaldo y Recuperación

**Plan AWS Backup — `backup-technova`**
- Regla `regla-diaria-technova`: frecuencia de 24 horas, retención 7 días
- Recursos: todas las instancias EC2 y todas las bases de datos RDS
- Almacén: Default, rol IAM: LabRole

**Snapshots RDS automáticos** con retención de 7 días. Se verificó el snapshot `rds:rds-technova-2026-05-20-19-29` en estado disponible.

---

## Pruebas de Alta Disponibilidad

### Prueba 1 — Falla de instancia EC2
Se detuvo manualmente la instancia `i-0ad65261ec3aee22c` (us-east-1a). Resultados:
- El ALB redirigió el tráfico automáticamente hacia la instancia saludable en `us-east-1b`
- La aplicación continuó respondiendo sin interrupción
- El ASG aprovisionó automáticamente una nueva instancia para mantener la capacidad deseada de 2

### Prueba 2 — Failover de RDS Multi-AZ
Se ejecutó reinicio con conmutación por error sobre `rds-technova`. Resultados:
- Failover completado en **menos de 1 minuto**
- La instancia primaria migró automáticamente de `us-east-1a` a `us-east-1b`
- Sin pérdida de datos (RPO ≈ 5 minutos por transaction logs)

### Prueba 3 — Restauración desde Snapshot
- RDS restaurado desde snapshot automático → instancia `rds-technova-restored` en estado Available
- EC2 restaurada desde AMI `ami-technova-apache` → instancia `ec2-technova-restored` con 3/3 comprobaciones exitosas

---

## Análisis RTO y RPO

| Componente | RTO | RPO |
|---|---|---|
| EC2 (Auto Scaling) | ≈ 3–5 minutos | ≈ 24 horas (backup diario) |
| RDS (Multi-AZ) | < 1 minuto | ≈ 5 minutos (transaction logs) |

---

## Mejoras propuestas

a. Implementar HTTPS con certificado SSL/TLS vía AWS Certificate Manager (ACM) en el ALB
b. Configurar políticas de escalado automático basadas en métricas de CPU para el ASG
c. Agregar caché con Amazon ElastiCache para reducir carga sobre RDS
d. Implementar AWS WAF en el ALB para protección contra ataques web
e. Reducir RPO de EC2 configurando AWS Backup con frecuencia horaria
f. Evaluar estrategia Multi-Region para recuperación ante fallas a nivel de región completa
