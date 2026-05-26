# Evaluación 1 — AUY1105 Infraestructura como Código II

## Integrantes
- Benjamín Santis (@Santixie)
- José Osorio (@Cosm09)
- Katalina Inostroza (@katalinaino)

---

## Objetivo

Implementar un pipeline automatizado con GitHub Actions para analizar la calidad y seguridad del código Terraform en AWS, aplicando análisis estático, validación de seguridad y políticas OPA antes de aprovisionar infraestructura.

---

## Infraestructura definida

La infraestructura se define en la carpeta `terraform/` y aprovisiona los siguientes recursos en AWS (`us-east-1`):

| Recurso | Descripción |
|---|---|
| `aws_vpc` | VPC con bloque CIDR `10.1.0.0/16` |
| `aws_subnet` | Subred con bloque CIDR `10.1.1.0/24` dentro de la VPC |
| `aws_security_group` | Permite SSH solo desde dentro de la VPC (`10.1.0.0/16`), no desde internet |
| `aws_instance` | EC2 con Ubuntu 24.04 LTS, tipo `t2.micro`, dentro de la subred definida |

Los outputs exponen el `vpc_id` y el `ec2_id` para ser referenciados por otros módulos o pipelines.

---

## Políticas OPA

Las políticas están en la carpeta `policies/` y se ejecutan con Conftest sobre el código Terraform antes de cualquier despliegue.

**`deny_public_ssh.rego`**
Bloquea cualquier security group que permita acceso SSH (puerto 22) desde `0.0.0.0/0`. Garantiza que la instancia EC2 no sea accesible por SSH desde internet, reduciendo la superficie de ataque.

**`only_t2micro.rego`**
Restringe la creación de instancias EC2 únicamente al tipo `t2.micro`. Evita el uso accidental de instancias más costosas en entornos de laboratorio.

---

## Pipeline CI/CD

El workflow `terraform-ci.yml` se ejecuta en cada Pull Request hacia `main` y corre las siguientes etapas en orden secuencial:

a. **TFLint** — análisis estático del código Terraform para detectar errores de sintaxis y malas prácticas antes de ejecutar nada.

b. **Checkov** — análisis de seguridad sobre los archivos `.tf` para identificar configuraciones inseguras. Corre con `soft_fail: true`, lo que significa que reporta hallazgos sin bloquear el pipeline.

c. **Validación OPA** — ejecuta Conftest con las políticas `.rego` sobre el código Terraform. Si alguna política falla (SSH público o instancia distinta a `t2.micro`), el pipeline se detiene.

d. **Terraform Validate** — valida que la sintaxis y configuración del código Terraform sea correcta usando `terraform validate`. Corre con `-backend=false` para no requerir credenciales de AWS.

---

## Decisiones de diseño

a. El pipeline corre únicamente en Pull Requests hacia `main`, no en pushes directos, lo que obliga a que todo cambio pase por revisión antes de llegar a la rama principal.

b. Checkov usa `soft_fail: true` para no bloquear el pipeline por hallazgos de seguridad menores, permitiendo que el equipo los revise sin detener el flujo de trabajo.

c. Las políticas OPA se mantienen separadas del código Terraform en la carpeta `policies/`, lo que permite actualizarlas o agregar nuevas sin tocar la infraestructura.

d. `terraform validate` corre con `-backend=false` para no depender de credenciales de AWS en el entorno de CI, manteniendo el pipeline liviano y seguro.
