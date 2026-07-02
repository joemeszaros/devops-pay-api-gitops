variable "aws_region" {
  type = string
}

variable "project_name" {
  type    = string
  default = "pay-api"
}

variable "cluster_name" {
  type    = string
  default = "pay-api-prod"
}

variable "cluster_version" {
  type        = string
  description = "Aktuálisan támogatott EKS Kubernetes verzió."
}

variable "vpc_cidr" {
  type    = string
  default = "10.50.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.50.0.0/24", "10.50.1.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.50.10.0/24", "10.50.11.0/24"]
}

variable "availability_zones" {
  type = list(string)
}

variable "github_org" {
  type = string
}

variable "github_app_repo" {
  type = string
}

variable "github_environment" {
  type    = string
  default = "prod"
}

variable "ecr_repository_name" {
  type    = string
  default = "pay-api"
}
