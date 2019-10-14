output "api_id" {
  value = "${aws_api_gateway_deployment.msg_api_deployment.id}"
}

output "api_invoke_url" {
  value = "${aws_api_gateway_deployment.msg_api_deployment.invoke_url}"
}
