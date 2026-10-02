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
  value       = aws_instance.web_server.public_ip != "" ? "http://${aws_instance.web_server.public_ip}" : "Server is stopped (no public IP)"
  description = "HTTP URL to access the Python web server"
}

output "server_status" {
  value       = aws_ec2_instance_state.web_server_state.state
  description = "Operational state of the EC2 instance"
}
