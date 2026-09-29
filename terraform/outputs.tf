output "instance_address" {
  description = "Address of the Taskflow API instance"
  value       = aws_instance.taskflow_api.public_ip
}