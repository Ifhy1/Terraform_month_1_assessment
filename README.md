# TechCorp AWS Infrastructure Deployment

This project automates the creation of a secure, highly available network on AWS using Terraform.

## Project Structure
- `main.tf`: Core infrastructure resources.
- `variables.tf`: Input variable definitions.
- `outputs.tf`: Important infrastructure details (ALB URL, IPs).
- `user_data/`: Configuration scripts for Web and DB servers.

## How to Deploy
1. Run `terraform init`
2. Run `terraform plan`
3. Run `terraform apply`