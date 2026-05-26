# Esta política bloquea el acceso SSH público (0.0.0.0/0)
# hacia instancias EC2 para evitar exposición innecesaria.
package terraform.security

deny[msg] {
  r := input.resource_changes[_]
  r.type == "aws_security_group"
  ingress := r.change.after.ingress[_]
  ingress.from_port == 22
  ingress.cidr_blocks[_] == "0.0.0.0/0"
  msg := "ERROR: No se permite acceso SSH público (0.0.0.0/0)"
}