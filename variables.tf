variable "region" {
  default = "ap-south-1"
}

variable "allowed_cidr" {
  description = "Your laptop public IP or VPN CIDR"
  default     = "0.0.0.0/0"
}

variable "vpc_id" {
  description = "Target VPC ID"
  default     = "vpc-057f66a3dc54e50ab"
}

variable "key_pair_name" {
  description = "Existing EC2 key pair name"
  default     = "test-uat"
}
