output "instance_address" {
  description = "Address of the Taskflow API compute instance"
  value       = aws_instance.taskflow_api.public_ip
}