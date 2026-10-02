terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Native S3 Remote Backend (No DynamoDB required in Terraform >= 1.10)
  backend "s3" {
    bucket       = "tfstate-406526694439-eu-central-1"
    key          = "interview-prep/terraform.tfstate"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = "DevOpsInterviewPrep"
    }
  }
}

# VPC
resource "aws_vpc" "interview_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.environment}-interview-vpc"
  }
}

# 1. Internet Gateway (Enables bidirectional internet communication for the VPC)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.interview_vpc.id

  tags = {
    Name = "${var.environment}-igw"
  }
}

# 2. Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.interview_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment}-public-subnet-1"
  }
}

# 3. Route Table (Routes outbound internet traffic to the Internet Gateway)
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.interview_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.environment}-public-rt"
  }
}

# 4. Route Table Association (Associates route table with the public subnet)
resource "aws_route_table_association" "public_rta" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# 5. Security Group (Stateful firewall: allows HTTP ingress, allows all egress)
resource "aws_security_group" "web_sg" {
  name        = "${var.environment}-web-server-sg"
  description = "Allow inbound HTTP traffic"
  vpc_id      = aws_vpc.interview_vpc.id

  ingress {
    description = "HTTP from allowed CIDR blocks"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-web-server-sg"
  }
}

# 6. Dynamic AMI lookup for latest Amazon Linux 2023 (x86_64)
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# 7. EC2 Web Server running Python 3 HTTP Server
resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              mkdir -p /opt/app
              cat << 'HTML' > /opt/app/index.html
              <!DOCTYPE html>
              <html>
              <head>
                <title>AWS DevOps Interview Prep</title>
                <style>
                  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; background-color: #0f172a; color: #f8fafc; }
                  .card { background: #1e293b; padding: 2.5rem; border-radius: 12px; box-shadow: 0 10px 25px rgba(0,0,0,0.5); text-align: center; border: 1px solid #334155; max-width: 480px; }
                  h1 { color: #38bdf8; margin-top: 0.5rem; }
                  p { color: #94a3b8; font-size: 1rem; line-height: 1.5; }
                  .badge { display: inline-block; padding: 6px 14px; background: #0284c7; color: white; border-radius: 9999px; font-size: 0.8rem; font-weight: 600; text-transform: uppercase; letter-spacing: 0.05em; }
                  .meta { margin-top: 1.5rem; padding-top: 1rem; border-top: 1px solid #334155; font-size: 0.85rem; color: #64748b; }
                </style>
              </head>
              <body>
                <div class="card">
                  <span class="badge">Step 1 Complete</span>
                  <h1>Hello from AWS!</h1>
                  <p>Lightweight Python 3 HTTP server running inside an EC2 instance in your custom VPC.</p>
                  <div class="meta">AWS DevOps Interview Prep &bull; Region: eu-central-1</div>
                </div>
              </body>
              </html>
              HTML

              cd /opt/app
              nohup python3 -m http.server 80 > /var/log/python-server.log 2>&1 &
              EOF

  user_data_replace_on_change = true

  tags = {
    Name = "${var.environment}-python-web-server"
  }
}
