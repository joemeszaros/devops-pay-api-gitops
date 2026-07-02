variable "aws_region" {
  type        = string
  description = "AWS régió a state backendhez."
}

variable "project_name" {
  type        = string
  description = "Projektprefix a backend resource-okhoz."
  default     = "pay-api"
}
