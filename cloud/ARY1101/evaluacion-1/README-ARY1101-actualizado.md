# Evaluación 1 — ARY1101 Infraestructura Cloud II

## Objetivo

Migración y optimización de la plataforma e-commerce de **TechNova Solutions** hacia AWS, asumiendo el rol de Ingeniero Cloud para planificar, ejecutar y documentar la migración completa, aplicando estrategias Rehost para la capa de aplicación y Replatform para la base de datos.

## Evidencia

- [`Evaluacion 1- Benjamin Santis.pdf`](./Evaluacion%201-%20Benjamin%20Santis.pdf) — Informe técnico completo
- [`Evaluacion 1- Presentacion - Benjamin Santis.pdf`](./Evaluacion%201-%20Presentacion%20-%20Benjamin%20Santis.pdf) — Presentación de la evaluación
- [`cloudformation/technova-stack-fixed.yaml`](./cloudformation/technova-stack-fixed.yaml) — Template CloudFormation

---

## Contexto del problema (AS-IS)

TechNova Solutions operaba sobre servidores VMware con Ubuntu 20.04 LTS ejecutando contenedores Docker (Nginx, Node.js, MySQL 8.0) con las siguientes limitaciones:

- Sin alta disponibilidad — cualquier falla de hardware provocaba caída total
- Sin cifrado de datos en reposo ni en tránsito
- Respaldos manuales inconsistentes
- Red plana sin segmentación por capas

Costo on-premise estimado a 3 años: **6.000 USD**

---

## Arquitectura implementada (TO-BE)

La infraestructura se despliega en AWS (`us-east-1`) mediante el template CloudFormation parametrizable.

### Estrategias de migración
- **Rehost** — capa de aplicación: contenedores Docker del frontend y backend migrados a EC2 con Ubuntu 24.04 LTS
- **Replatform** — base de datos: MySQL 8.0 en Docker migrado a Amazon RDS MySQL 8.4.x como servicio gestionado

### Red
| Recurso | Valor |
|---|---|
| VPC | `10.0.0.0/22` con DNS hostnames habilitado |
| Subred Pública 1a | `10.0.0.0/26` — aloja EC2 |
| Subred Pública 1b | `10.0.1.0/26` |
| Subred Privada 1a | `10.0.2.0/26` — aloja RDS primaria |
| Subred Privada 1b | `10.0.3.0/26` — aloja RDS standby |

### Cómputo y almacenamiento
| Recurso | Detalle |
|---|---|
| EC2 `ec2-technova` | `t3.micro`, Ubuntu 24.04 LTS, IP elástica `3.90.131.114`, IP privada `10.0.0.28` |
| EBS | 50 GB gp3 cifrado |
| RDS `rds-technova` | MySQL 8.4.x, `db.t3.micro`, 50 GB gp3 cifrado, subred privada |
| ECR | Repositorios privados `technova-frontend` y `technova-backend` con cifrado AES-256 |

### Security Groups
| SG | Reglas |
|---|---|
| `sg_ec2_technova` | SSH (22) restringido a IP específica, HTTP (80) y HTTPS (443) públicos, API (3001) público |
| `sg_rds_technova` | MySQL (3306) solo desde `sg_ec2_technova` — nunca desde internet |

---

## Despliegue y verificación

a. Archivos transferidos a EC2 mediante SCP al 100% (docker-compose.yml, Dockerfiles, .env, scripts SQL, código de la aplicación)
b. Conectividad EC2→RDS verificada con `netcat` al puerto 3306
c. Contenedores levantados con `docker compose up -d`:
   - `tienda-tech-frontend` → puerto 80:80
   - `tienda-tech-backend` → puerto 3001:3001
d. Aplicación 100% operativa con CRUD completo sobre 4 productos desde RDS
e. API REST validada en `http://3.90.131.114:3001/api/productos`

---

## Análisis TCO

| Criterio | On-Premise | AWS t3.micro | AWS t3.medium |
|---|---|---|---|
| Costo mensual | — | $96,26 USD | $193,50 USD |
| Costo anual | — | $1.155,12 USD | $2.322 USD |
| Costo 3 años | $6.000 USD | $3.465 USD | $6.966 USD |
| Ahorro vs on-premise | — | **42% ($2.535 USD)** | -$966 (más caro) |
| RAM | — | 1 GB | 4 GB |
| Cifrado | No | Sí (EBS + RDS) | Sí (EBS + RDS) |
| Backups automáticos | No | Sí | Sí |

La configuración inicial con `t3.micro` es la más eficiente en costo-beneficio. El escalamiento a `t3.medium` queda reservado para períodos de alta demanda y puede revertirse una vez superado el peak — algo imposible en infraestructura on-premise.

---

## Pruebas de carga y escalamiento vertical

### RDS — db.t3.micro bajo carga
- CPU Utilization: peak de **38.9%**
- DatabaseConnections: peak de **46 conexiones** (límite: 61)
- Resultado: saturación confirmada con "Too many connections"

### RDS — db.t3.medium post-escalamiento
- Conexiones disponibles: **305** (vs 61 anteriores, +400%)
- Sin saturación durante toda la prueba de 120 segundos
- FreeableMemory: 3.023 GB disponibles

### EC2 — t3.micro bajo carga (3 fases: 40%, 60%, 95%)
- Peak CPU: **96%** (fase STEP3)
- Peak RAM: **78.38%** (714/911 MB) — umbral crítico del 70% superado
- Requests HTTP: 66 — **100% exitosos**
- Peak latencia: 0.004 segundos

### EC2 — t3.medium post-escalamiento
- Peak CPU: 96% (similar)
- Peak RAM: **63.67%** (2441/3834 MB) — umbral crítico NO alcanzado
- RAM total: 3.834 MB (**+320% más memoria**)
- Requests HTTP: 117 — sin errores 5xx

---

## Decisiones de diseño

a. **Template CloudFormation parametrizable** — todos los valores configurables se definen como parámetros, permitiendo reutilizar el mismo template en distintos ambientes sin modificar el código.

b. **RDS en subred privada** — la base de datos no tiene acceso público y solo acepta conexiones desde la EC2, siguiendo el principio de mínimo privilegio.

c. **Encriptación en reposo** — habilitada en EBS y RDS desde el inicio, no como configuración posterior.

d. **ECR con escaneo automático** — `ScanOnPush: true` en ambos repositorios para detectar vulnerabilidades en cada imagen publicada.

e. **Elastic IP** — asignada a la EC2 para mantener un endpoint fijo entre reinicios de la instancia.

f. **UserData automatizado** — la EC2 se aprovisiona automáticamente con Docker, Docker Compose v2, AWS CLI y cliente MySQL al lanzarse, sin intervención manual.
