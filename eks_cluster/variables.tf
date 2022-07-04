variable "environment" {
  description = "Deployment Environment"
  default = "jksiazek-eks"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for VPC"
  default = "10.1.0.0/20"
}

variable "public_subnets_cidr" {
  type        = list(string)
  description = "CIDR block for Public Subnet"
  default = ["10.1.1.0/24", "10.1.2.0/24"]
}

variable "private_subnets_cidr" {
  type        = list(string)
  description = "CIDR block for Private Subnet"
  default = ["10.1.3.0/24", "10.1.4.0/24"]
}

variable "availability_zones" {
  type        = list(string)
  description = "AZ in which all the resources will be deployed"
  default = ["eu-west-1a", "eu-west-1b"]
}
