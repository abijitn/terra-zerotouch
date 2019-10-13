variable "name" {
  description = "The name of the lambda to create, which also defines (i) the archive name (.zip), (ii) the file name, and (iii) the function name"
}

variable "runtime" {
  description = "The runtime of the lambda to create"
  default     = "nodejs"
}

variable "handler" {
  description = "The handler name of the lambda (a function defined in your lambda)"
  default     = "handler"
}

variable "role" {
  description = "IAM role attached to the Lambda Function (ARN)"
}

/*
variable "aws_subnets" {
  description = "The VPC subnets to associate with the lambda function"
}
variable "aws_sg" {
  description = "The VPC security groups to associate with the lambda function"
}

data "aws_subnet" "vpc_subnet" {
  id     = "${var.aws_subnets}"
}
data "aws_security_group" "vpc_sg" {
  id     = "${var.aws_sg}"
}
*/

resource "aws_lambda_function" "lambda" {

  //depends_on = ["aws_iam_role_policy_attachment.lambda"]
  //depends_on = ["aws_iam_role_policy_attachment.lambda_exec_role_eni"]
  filename      = "${var.name}.zip"
  function_name = "${var.name}_${var.handler}"
  role          = "${var.role}"
  handler       = "${var.name}.${var.handler}"
  runtime       = "${var.runtime}"
  // Deploy into a VPC.
  /*
  vpc_config {
      security_group_ids = ["${data.aws_security_group.vpc_sg.id}"]
      subnet_ids         = ["${data.aws_subnet.vpc_subnet.id}"]
  }
  */
}

output "name" {
  value = "${aws_lambda_function.lambda.function_name}"
}
