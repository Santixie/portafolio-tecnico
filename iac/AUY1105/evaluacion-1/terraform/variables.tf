variable "region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "AMI de Ubuntu 24.04 LTS"
  type        = string
  default     = "ami-0e86e20dae9224db8"
}