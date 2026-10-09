variable "projet" {
  type        = string
  description = "Nom du projet"
  default     = "startup-idp"
}

variable "env" {
  type        = string
  description = "Nom de l'environement"
  default     = "prod"
}

variable "vpc_cidr_block" {
  type        = string
  description = "CIDR du VPC"
  default     = "10.0.0.0/16"
}

variable "ec2_type" {
  type        = string
  description = "Type de l'EC2"
  default     = "t3.medium"
}

variable "subnet_public_cidr_block" {
  type        = string
  description = "CIDR du subnet"
  default     = "10.0.1.0/24"
}

variable "subnet_public_az" {
  type        = string
  description = "AZ du subnet public"
  default     = "eu-west-2a"
}

variable "s3_bucket_app" {
  type        = string
  description = "Nom du bucket pour l'app"
  default     = "startup-idp-bucket"
}