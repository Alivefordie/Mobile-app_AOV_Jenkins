resource "aws_security_group" "taskflow_api" {
  name        = "taskflow-api-sg"
  description = "Allow Taskflow API traffic on port 8080"

  ingress {
    description = "Allow HTTP traffic to Taskflow API"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "taskflow-api-sg"
  }
}
resource "aws_instance" "taskflow_api" {
  ami           = "ami-61ad6e59d7b0"
  instance_type = "t2.micro"

  vpc_security_group_ids = [
    aws_security_group.taskflow_api.id
  ]

  tags = {
    Name = "taskflow-api"
  }
}