# This gives the URL to visit the website
output "alb_dns_name" {
  description = "The URL of your website"
  value       = aws_lb.web_alb.dns_name
}

# This gives the IP to SSH into Bastion host
output "bastion_public_ip" {
  description = "The Public IP of your Bastion"
  value       = aws_instance.bastion.public_ip
}

# This shows the VPC ID for records
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.techcorp_vpc.id
}
