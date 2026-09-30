output "instance_address" {
  description = "Address of the provisioned Taskflow API host"
  value       = aws_instance.taskflow_api.public_ip
}