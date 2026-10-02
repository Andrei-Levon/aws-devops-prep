variable "aws_region" {
  type        = string
  description = "AWS region for deployment"
  default     = "eu-central-1"
}

variable "environment" {
  type        = string
  description = "Deployment environment"
  default     = "dev"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  type        = string
  description = "CIDR block for the public subnet"
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.micro"
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  description = "Allowed CIDR blocks for HTTP ingress (restrict to your IP if desired)"
  default     = ["0.0.0.0/0"]
}

variable "server_state" {
  type        = string
  description = "Target state of the EC2 instance ('running' or 'stopped')"
  default     = "stopped"

  validation {
    condition     = contains(["running", "stopped"], var.server_state)
    error_message = "server_state must be either 'running' or 'stopped'."
  }
}
