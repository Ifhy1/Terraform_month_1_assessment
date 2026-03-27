# This gives you the URL to visit your website
output "alb_dns_name" {
  description = "The URL of your website"
  value       = aws_lb.web_alb.dns_name
}

# This gives you the IP to SSH into your Bastion host
output "bastion_public_ip" {
  description = "The Public IP of your Bastion"
  value       = aws_instance.bastion.public_ip
}

# This shows the VPC ID for your records
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.techcorp_vpc.id
}