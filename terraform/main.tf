resource "aws_security_group" "taskflow_api" {
  name        = "taskflow-api-sg"
  description = "Allow Taskflow API traffic"

  ingress {
    description = "Allow Taskflow API traffic from Jenkins network"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  ingress {
    description = "Allow SSH from Jenkins network"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  egress {
    description = "Allow outbound traffic to Jenkins network"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.allowed_cidr]
  }

  tags = {
    Name = "taskflow-api-sg"
  }
}
# tfsec:ignore:aws-ec2-enable-at-rest-encryption:exp:2026-12-31
resource "aws_instance" "taskflow_api" {
  ami           = "ami-61ad6e59d7b0"
  instance_type = "t2.micro"

  key_name = aws_key_pair.taskflow_ansible.key_name

  vpc_security_group_ids = [
    aws_security_group.taskflow_api.id
  ]

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = {
    Name = "taskflow-api"
  }
}
resource "aws_key_pair" "taskflow_ansible" {
  key_name   = "taskflow-ansible"
  public_key = var.ssh_public_key
}