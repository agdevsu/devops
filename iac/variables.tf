##################
# Global Variables
##################

variable "aws_region" {
  type        = string
  description = "AWS Region where resources will be created"
}

variable "environment" {
  type        = string
  description = "Environment name for tagging and namming"
  default     = "production"
}

########################
# VPC & Subnet Variables
########################

variable "vpc_cidr_block" {
  type        = string
  description = "CIDR IPv4 block for VPC"
  default     = "10.1.0.0/16"
}

variable "subnets_count" {
  type        = number
  description = "Number of subnets to be created"
  default     = 2
}

variable "subnets_cidr_bits" {
  type        = number
  description = "Number of addtional bits to extend the prefix VPC CIDR block"
  default     = 8
}

#########################
# EC2 Instances Variables
#########################

variable "ec2_ssh_key_name" {
  type        = string
  description = "SSH Key name to manage EC2 instances"
}

###############
# ALB Variables
###############

variable "certificate_arn" {
  type        = string
  description = "SSL Certificate ARN to attach it to the ALB"
}