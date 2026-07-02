variable "project_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "cluster_version" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
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
  type = string
}
