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

# SQS variables
variable "msg_sqs_name" {
  description = "The name of the SQS queue"
  default = "msg_queue"
}

variable "msg_ddb_name" {
  description = "The name of the DynamoDB table"
  default = "msg_table"
}

variable "website_dns" {
  description = "S3 bucket for swagger"
  default = "swagger-terranotouch"
}
variable "swagger_ui_version" {
  description = "Swagger version"
  default = "v3.24.0"
}
