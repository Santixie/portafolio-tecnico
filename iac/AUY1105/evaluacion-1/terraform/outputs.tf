output "vpc_id" {
  description = "ID de la VPC"
  value       = aws_vpc.main.id
}

output "ec2_id" {
  description = "ID de la instancia EC2"
  value       = aws_instance.main.id
}