variable "allowed_cidr" {
  description = "CIDR allowed to communicate with Taskflow API"
  type        = string
  default     = "172.20.0.0/16"
}