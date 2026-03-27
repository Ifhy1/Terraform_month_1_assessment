# TechCorp AWS Infrastructure Deployment

Overview
This repository contains the Terraform configuration for the TechCorp production environment. The goal was to build a secure, scalable, and highly available infrastructure that separates the public-facing web tier from the private database layer.

The Architecture
The deployment consists of 27 resources across a custom VPC, structured as follows:

Networking: A VPC with 2 Public Subnets (Frontend) and 4 Private Subnets (App & Database) across two Availability Zones for redundancy.

Security & Access: * Bastion Host: Acting as the single point of entry for SSH management.

NAT Gateways: Allowing private instances to access the internet for updates without being publicly reachable.

Load Balancing & Scaling: * Application Load Balancer (ALB): Handling incoming HTTP traffic.

Auto Scaling Group (ASG): Dynamically managing EC2 web servers to handle traffic spikes.

Database Tier: An RDS PostgreSQL instance isolated in the private subnets, accessible only from the web tier.

Project Files
main.tf: Resource definitions for VPC, EC2, ALB, and RDS.

variables.tf & outputs.tf: Configuration inputs and critical endpoint exports.

user_data/: Bootstrapping scripts for the web and database server setups.

evidence/: Screenshots documenting the successful terraform apply, connectivity tests, and final destroy.

Deployment Workflow
Initialize: terraform init to set up the AWS provider.

Validation: terraform plan to confirm the 27-resource blueprint.

Execution: terraform apply --auto-approve for full orchestration.

Verification: Validated ALB DNS, Bastion SSH, and Postgres connectivity.

Teardown: terraform destroy to successfully decommission all resources.




 
