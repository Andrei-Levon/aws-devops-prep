output "vpc_id" {
  value       = aws_vpc.interview_vpc.id
  description = "ID of the created VPC"
}

output "vpc_arn" {
  value       = aws_vpc.interview_vpc.arn
  description = "ARN of the created VPC"
}

output "instance_public_ip" {
  value       = aws_instance.web_server.public_ip
  description = "Public IPv4 address of the Python EC2 instance"
}

output "server_url" {
  value       = "http://${aws_instance.web_server.public_ip}"
  description = "HTTP URL to access the Python web server"
}
