# All sorts of IAM permissions - Can be even granular.
resource "aws_iam_role" "iam_role_for_lambda" {
  name = "iam_role_for_lambda"


  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_exec_role_sqs" {
  role = "${aws_iam_role.iam_role_for_lambda.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_exec_role_dynamodb" {
  role = "${aws_iam_role.iam_role_for_lambda.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_policy" "kms_decrypt" {
  name        = "custom_kms_policy"
  path        = "/"

  policy = <<EOF
{
  "Version" : "2012-10-17",
  "Statement" : [
      {
          "Effect" : "Allow",
          "Action" : [
              "kms:*"
          ],
          "Resource" : [
              "*"
            ]
        }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_exec_role_kms" {
  role = "${aws_iam_role.iam_role_for_lambda.name}"
  policy_arn = "arn:aws:iam::${var.aws_account_id}:policy/${aws_iam_policy.kms_decrypt.name}"
}


# Creating SQS dead letter queue
resource "aws_sqs_queue" "msg_dlq" {
  name                      = "msg_dlq"
  max_message_size          = 2048
  message_retention_seconds = 3600

}

# This will be the SQS queue to post messages to.
resource "aws_sqs_queue" "msg_queue" {
  name                      = "${var.msg_sqs_name}"
  max_message_size          = 2048
  message_retention_seconds = 3600
  redrive_policy            = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.msg_dlq.arn}\",\"maxReceiveCount\":2}"

}

# Creating DynamoDB table 

resource "aws_dynamodb_table" "message_table" {
  name           = "${var.msg_ddb_name}"
  billing_mode   = "PROVISIONED"
  read_capacity  = 10
  write_capacity = 10
  hash_key       = "Ugly_trick"
  range_key      = "Timestamp"

  attribute {
    name = "Ugly_trick"
    type = "S"
  }
  attribute {
    name = "Timestamp"
    type = "S"
  }

}

# This first lambda function  will return the latest item from DynamoDB
# `msg_lambda.handler`
module "lambda" {
  source  = "./lambda"
  name    = "msg_lambda"
  runtime = "python3.6"
  role    = "${aws_iam_role.iam_role_for_lambda.arn}"
  //aws_subnets = "${var.aws_subnets}"
  //aws_sg = "${var.aws_sg}"
  msg_sqs_name = "DUMMY"
  msg_ddb_name = "${var.msg_ddb_name}"
}

# This is a second lambda function that will post message to SQS
# `msg_lambda.post_handler`
module "lambda_post" {
  source  = "./lambda"
  name    = "msg_lambda"
  handler = "post_handler"
  runtime = "python3.6"
  role    = "${aws_iam_role.iam_role_for_lambda.arn}"
  //aws_subnets = "${var.aws_subnets}"
  //aws_sg = "${var.aws_sg}"
  msg_sqs_name = "${var.msg_sqs_name}"
  msg_ddb_name = "DUMMY"
}

# This is a third lambda function that will process messages in SQS
# `msg_lambda.sqs_handler`
module "lambda_sqs" {
  source  = "./lambda"
  name    = "msg_lambda"
  handler = "sqs_handler"
  runtime = "python3.6"
  role    = "${aws_iam_role.iam_role_for_lambda.arn}"
  //aws_subnets = "${var.aws_subnets}"
  //aws_sg = "${var.aws_sg}"
  msg_sqs_name = "${var.msg_sqs_name}"
  msg_ddb_name = "${var.msg_ddb_name}"
}

# -- Couldn't make it work - Doesnt work elegantly or consistently. Still leaving it for now.
# Creating SQS trigger for lambda
resource "aws_lambda_event_source_mapping" "exec_sqs_handler" {
  event_source_arn = "${aws_sqs_queue.msg_queue.arn}"
  function_name    = module.lambda_sqs.arn
  batch_size        = 1
  enabled           = true
}


# Set the lambda execution to CloudWatch event triggered
resource "aws_cloudwatch_event_rule" "every_one_minute" {
    name = "every-one-minute"
    description = "Fires every one minute"
    schedule_expression = "rate(2 minutes)"
}

resource "aws_cloudwatch_event_target" "check_every_min" {
    rule = "${aws_cloudwatch_event_rule.every_one_minute.name}"
    arn = module.lambda_sqs.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda_sqs" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = module.lambda_sqs.arn
    principal = "events.amazonaws.com"
    source_arn = "${aws_cloudwatch_event_rule.every_one_minute.arn}"
}

# Now, we need an API to expose those functions publicly
resource "aws_api_gateway_rest_api" "msg_api" {
  name = "Message API"
}

# The API requires at least one "endpoint", or "resource" in AWS terminology.
# The endpoint created here is: /msg
resource "aws_api_gateway_resource" "msg_api_res_msg" {
  rest_api_id = "${aws_api_gateway_rest_api.msg_api.id}"
  parent_id   = "${aws_api_gateway_rest_api.msg_api.root_resource_id}"
  path_part   = "msg"
}

# Until now, the resource created could not respond to anything. We must set up
# a HTTP method (or verb) for that!
# This is the code for method GET /msg, that will talk to the first lambda
module "msg_get" {
  source      = "./api_method"
  rest_api_id = "${aws_api_gateway_rest_api.msg_api.id}"
  resource_id = "${aws_api_gateway_resource.msg_api_res_msg.id}"
  method      = "GET"
  path        = "${aws_api_gateway_resource.msg_api_res_msg.path}"
  lambda      = "${module.lambda.name}"
  region      = "${var.aws_region}"
  account_id  = "${var.aws_account_id}"
}

# This is the code for method POST /msg, that will talk to the second lambda
module "msg_post" {
  source      = "./api_method"
  rest_api_id = "${aws_api_gateway_rest_api.msg_api.id}"
  resource_id = "${aws_api_gateway_resource.msg_api_res_msg.id}"
  method      = "POST"
  path        = "${aws_api_gateway_resource.msg_api_res_msg.path}"
  lambda      = "${module.lambda_post.name}"
  region      = "${var.aws_region}"
  account_id  = "${var.aws_account_id}"
}

# We can deploy the API now! (i.e. make it publicly available)
resource "aws_api_gateway_deployment" "msg_api_deployment" {
  rest_api_id = "${aws_api_gateway_rest_api.msg_api.id}"
  stage_name  = "production"
  description = "Deploy methods: ${module.msg_get.http_method} ${module.msg_post.http_method}"
}
