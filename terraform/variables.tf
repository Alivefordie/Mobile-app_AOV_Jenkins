variable "allowed_cidr" {
  description = "CIDR allowed to access Taskflow API on port 8080"
  type        = string
  default     = "172.20.0.0/16"
}