# Evaluación 1 — AUY1104 Ciclo de Vida del Software

## Objetivo

Implementar un flujo completo de despliegue en contenedores sobre un cluster k3s en AWS Learner Lab, automatizado con GitHub Actions, publicando imágenes en Docker Hub y exponiendo tres servicios mediante NodePort en los puertos 30080, 30090 y 30100.

---

## Arquitectura

La solución está dividida en dos repositorios con responsabilidades distintas:

**Main (repositorio central)**
Actúa como repositorio de workflows reutilizables. Contiene el workflow de provisión de infraestructura en AWS usando Terraform, que levanta la instancia EC2 e instala k3s automáticamente. Define además los workflows reutilizables que otros repositorios pueden invocar mediante `workflow_call`.

**Runner (repositorio de aplicación)**
Contiene la aplicación `demo-api` y su pipeline CI/CD. Cuando se hace push a `main`, el pipeline invoca el workflow compartido del Main usando `workflow_call`, delegando la lógica de build, push a Docker Hub y despliegue en k3s sin duplicarla.

La ventaja de esta arquitectura es que si se necesita modificar el proceso de despliegue, el cambio se hace en un solo lugar (Main) y todos los repositorios que lo invocan se actualizan automáticamente.

---

## Manifiestos de Kubernetes

| Archivo | Tipo | Descripción |
|---|---|---|
| `deployment.yaml` | Deployment | Define la imagen Docker de demo-api, réplicas y health checks (`readinessProbe` / `livenessProbe`) en `/health` |
| `service.yaml` | Service NodePort | Expone demo-api al exterior por el puerto 30090 |
| `nginx-deployment.yaml` | Deployment | Despliega nginx usando `nginx:latest` sin imagen personalizada |
| `nginx-service.yaml` | Service NodePort | Expone nginx por el puerto 30080 |

Los tres servicios expuestos son:

- Puerto **30080** — nginx
- Puerto **30090** — demo-api
- Puerto **30100** — Apache

---

## Pipeline CI/CD

El pipeline del Runner ejecuta las siguientes etapas en orden:

a. **Build** — construye la imagen Docker a partir del `Dockerfile`
b. **Push** — publica la imagen en Docker Hub
c. **Verificación** — ejecuta `curl` contra el endpoint `/health` para validar que la imagen funciona antes de marcar el pipeline como exitoso
d. **Deploy** — aplica los manifiestos en el cluster k3s mediante `kubectl apply`

Solo se publica una imagen que ya fue validada en el entorno real.

---

## Decisiones de diseño

a. Se optó por `workflow_call` en vez de duplicar la lógica de despliegue en cada repositorio, siguiendo el principio DRY (Don't Repeat Yourself).

b. Los manifiestos de nginx se incluyen directamente en el Runner porque nginx no requiere imagen personalizada — usa `nginx:latest` desde Docker Hub.

c. El `readinessProbe` y `livenessProbe` apuntan al endpoint `/health` para que Kubernetes verifique automáticamente el estado de los pods sin intervención manual.

---

## Lecciones aprendidas y mejoras futuras

En una evaluación anterior el pipeline de pruebas estaba desacoplado del pipeline de build, lo que significaba que los tests corrían sobre el código fuente pero no validaban que la imagen Docker construida funcionara correctamente. En esta evaluación se corrigió incluyendo las etapas de build, push y verificación dentro del mismo pipeline.

Como mejora futura se identificó agregar un paso de **rollback automático**: si la verificación con `curl` falla después del despliegue, el pipeline debería ejecutar `kubectl rollout undo` automáticamente, dejando el sistema en estado estable sin intervención manual.
