# AUY1105-grupo-7

## Descripción
Repositorio del proyecto de Infraestructura como Código (IaC)
para la asignatura AUY1105 - Infraestructura como código II.

## Objetivo
Implementar un pipeline automatizado con GitHub Actions para
analizar la calidad y seguridad del código Terraform en AWS.

## Estructura del repositorio
```
├── terraform/        # Código de infraestructura
├── .github/
│   └── workflows/    # GitHub Actions
├── policies/         # Políticas OPA
├── .gitignore
├── CHANGELOG.md
└── README.md
```

## Integrantes
- Benjamin Santis (@Santixie)
- Jose Osorio (@Cosm09)
- Katalina Inostroza (@katalinaino)

## Instrucciones de uso
1. Clonar el repositorio
2. Instalar Terraform
3. Ejecutar `terraform init` dentro de la carpeta `/terraform`
4. Ejecutar `terraform plan` para previsualizar los cambios
5. Ejecutar `terraform apply` para aprovisionar la infraestructura

---

## Definición del código Terraform

El código Terraform se encuentra en la carpeta `/terraform` y define una infraestructura básica en AWS compuesta por red, seguridad y cómputo.

### Proveedor
Se utiliza el proveedor oficial de AWS (`hashicorp/aws`) en su versión mayor `~> 5.0`. La región se configura mediante la variable `var.region` (valor por defecto: `us-east-1`).

### Variables (`variables.tf`)

| Variable | Tipo | Valor por defecto | Descripción |
|---|---|---|---|
| `region` | string | `us-east-1` | Región de AWS donde se despliega la infraestructura |
| `ami_id` | string | `ami-0e86e20dae9224db8` | ID de la AMI de Ubuntu 24.04 LTS |

### Recursos (`main.tf`)

#### `aws_vpc` — Red privada virtual
Define una VPC con el bloque CIDR `10.1.0.0/16`, que actúa como red aislada donde se alojan todos los recursos de la infraestructura.

#### `aws_subnet` — Subred
Crea una subred dentro de la VPC con el bloque CIDR `10.1.1.0/24`. Contiene los recursos de cómputo de la aplicación.

#### `aws_security_group` — Grupo de seguridad
Controla el tráfico de red hacia y desde la instancia EC2:
- **Ingress**: permite únicamente tráfico SSH (puerto 22) desde dentro de la VPC (`10.1.0.0/16`). No se permite acceso SSH público.
- **Egress**: permite todo el tráfico saliente.

#### `aws_instance` — Instancia EC2
Define una máquina virtual con las siguientes características:
- **Sistema operativo**: Ubuntu 24.04 LTS
- **Tipo de instancia**: `t2.micro`
- **Red**: desplegada en la subred definida anteriormente
- **Seguridad**: asociada al security group que restringe el acceso SSH

### Outputs (`outputs.tf`)

| Output | Descripción |
|---|---|
| `vpc_id` | ID de la VPC creada |
| `ec2_id` | ID de la instancia EC2 creada |
