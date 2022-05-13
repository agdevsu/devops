output "aws_ec2_instance_public_ip" {
  value       = aws_instance.devops_ec2_api[*].public_ip
  description = "Public IP address to access EC2 instances"
}

output "aws_alb_public_dns" {
  value       = aws_lb.devops_alb.dns_name
  description = "DNS name of the Application Load Balancer"
}