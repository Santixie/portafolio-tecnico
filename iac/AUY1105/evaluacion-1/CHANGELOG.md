# Changelog

## [1.0.0] - 2024-11-01
### Added
- Configuración inicial del repositorio
- Archivo README.md con descripción del proyecto
- Archivo .gitignore para excluir archivos sensibles
- Archivo CHANGELOG.md para registro de cambios

## [1.1.0] - 2024-11-01
### Added
- Código Terraform para infraestructura AWS
- VPC con CIDR 10.1.0.0/16
- Subred con máscara /24
- Security Group con acceso SSH restringido a 10.1.0.0/16
- Instancia EC2 Ubuntu 24.04 LTS tipo t2.micro

## [1.2.0] - 2024-11-01
### Added
- Workflow de automatización con GitHub Actions
- Análisis estático con TFLint
- Análisis de seguridad con Checkov
- Validación con terraform validate
- Workflow activado solo por pull request hacia main

## [1.3.0] - 2024-11-01
### Added
- Políticas de seguridad con OPA
- Política para bloquear SSH público
- Política para restringir tipo de instancia a t2.micro