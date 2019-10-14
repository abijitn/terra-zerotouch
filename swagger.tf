resource "aws_s3_bucket" "main" {
    region = "${var.aws_region}"
    bucket = "${var.website_dns}"
    acl = "public-read"

    website {
        index_document = "index.html"
        error_document = "index.html"
    }
    depends_on = [aws_api_gateway_deployment.msg_api_deployment]
}
data "template_file" "main" {
    template = <<EOF
echo "Need to figure how to get the api_id value to this template"
echo "aws apigateway get-export --parameters extensions='apigateway' --rest-api-id <api_id> --stage-name production --export-type swagger ./swagger-ui/dist/swagger.json"
aws s3 sync --acl public-read ./swagger-ui/dist s3://${aws_s3_bucket.main.bucket} --delete

EOF
}
resource "null_resource" "main" {
    triggers = {
        rendered_template = "${data.template_file.main.rendered}"
        version = "${var.swagger_ui_version}"
    }

    provisioner "local-exec" {
        command = "${data.template_file.main.rendered}"
    }
}