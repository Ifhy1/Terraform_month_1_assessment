variable "region" {
  description = "The AWS region to deploy in"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "instance_type" {
  description = "Type of EC2 instance"
  type        = string
  default     = "t3.micro"
}