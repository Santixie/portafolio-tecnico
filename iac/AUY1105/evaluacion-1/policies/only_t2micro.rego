# Esta política restringe la creación de instancias EC2
# solo al tipo t2.micro para control de costos.
package terraform.security

deny[msg] {
  r := input.resource_changes[_]
  r.type == "aws_instance"
  r.change.after.instance_type != "t2.micro"
  msg := "ERROR: Solo se permite el tipo de instancia t2.micro"
}