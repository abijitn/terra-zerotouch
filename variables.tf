variable "aws_account_id" {
  description = "AWS account id"
  default     = "960706185170"
}

variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

# Lambda Module variables
variable "aws_subnets" {
  description = "The VPC subnets to associate with the lambda function"
}
variable "aws_sg" {
  description = "The VPC security groups to associate with the lambda function"
}

# API Module variables
