resource "aws_s3_bucket" "main" {
    region = "${var.aws_region}"
    bucket = "${var.website_dns}"
    acl = "public-read"

    website {
        index_document = "index.html"
        error_document = "index.html"
    }
}
data "template_file" "main" {
    template = <<EOF
curl -L https://github.com/swagger-api/swagger-ui/archive/${var.swagger_ui_version}.tar.gz -o /tmp/swagger-ui.tar.gz
mkdir -p /tmp/swagger-ui
tar --strip-components 1 -C /tmp/swagger-ui -xf /tmp/swagger-ui.tar.gz

aws s3 sync --acl public-read /tmp/swagger-ui/dist s3://${aws_s3_bucket.main.bucket} --delete
rm -rf /tmp/swagger-ui
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