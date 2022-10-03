terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
   region = "${var.aws_region}"
}

# API Gateway
#######################################

resource "aws_api_gateway_rest_api" "sum_api" {
  name = "myapi"
}

resource "aws_api_gateway_resource" "resource" {
  path_part   = "{${var.resource_name}}"
  parent_id   = aws_api_gateway_rest_api.sum_api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.sum_api.id
}

resource "aws_api_gateway_method" "post" {
  rest_api_id   = aws_api_gateway_rest_api.sum_api.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.sum_api.id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.post.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = aws_lambda_function.sum_lambda.invoke_arn
  passthrough_behavior    = "WHEN_NO_TEMPLATES"
  request_templates       = {
    "application/json" = <<EOF
{
   "body" : $input.json('$')
}
EOF
  }

}

resource "aws_api_gateway_method_response" "response_200" {
 rest_api_id = aws_api_gateway_rest_api.sum_api.id
 resource_id = aws_api_gateway_resource.resource.id
 http_method = aws_api_gateway_method.post.http_method
 status_code = "200"
 
 response_models = { "application/json" = "Empty"}
}

resource "aws_api_gateway_integration_response" "IntegrationResponse" {
  depends_on = [
     aws_api_gateway_integration.integration,
  ]
  rest_api_id = aws_api_gateway_rest_api.sum_api.id
  resource_id = aws_api_gateway_resource.resource.id
  http_method = aws_api_gateway_method.post.http_method
  status_code = aws_api_gateway_method_response.response_200.status_code
  response_templates = {
 "application/json" = <<EOF
 
 EOF
 }
}

resource "aws_api_gateway_deployment" "sum_api" {
   depends_on = [
     aws_api_gateway_integration.integration,
     aws_api_gateway_integration_response.IntegrationResponse,
   ]
   rest_api_id = aws_api_gateway_rest_api.sum_api.id
   stage_name  = var.stage
}

output "base_url" {
  value = "${aws_api_gateway_deployment.sum_api.invoke_url}/${var.resource_name}"
}


# SNS
######################

resource "aws_sns_topic" "resoult" {
  name = "resoult"
}

resource "aws_sns_topic_subscription" "target" {
  topic_arn = aws_sns_topic.resoult.arn
  protocol  = "email"
  endpoint  = "${var.email_endpoint}"
}

resource "aws_sns_topic_policy" "resoult_topic_policy" {
  arn = aws_sns_topic.resoult.arn
  policy = data.aws_iam_policy_document.resoult_topic_sns_policy_document.json
}

data "aws_iam_policy_document" "resoult_topic_sns_policy_document" {
  policy_id = "__default_policy_ID"

  statement {
    actions = [ "SNS:Publish" ]
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      aws_sns_topic.resoult.arn,
    ]
    sid = "__default_statement_ID"
  }
}

# Lambda
#######################################

provider "archive" {}

data "archive_file" "zip" {
  type        = "zip"
  source_file = "sum_lambda.py"
  output_path = "sum_lambda.zip"
}

data "aws_iam_policy_document" "policy" {
  statement {
    sid    = ""
    effect = "Allow"

    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "sum_lambda" {
  name               = "sum_lambda"
  assume_role_policy = "${data.aws_iam_policy_document.policy.json}"
}

resource "aws_lambda_function" "sum_lambda" {
   depends_on = [aws_sns_topic.resoult]

   function_name = "sum_lambda"

   filename         = "${data.archive_file.zip.output_path}"
   source_code_hash = "${data.archive_file.zip.output_base64sha256}"

   handler = "sum_lambda.lambda_handler"
   runtime = "python3.9"

   role    = "${aws_iam_role.sum_lambda.arn}"
   environment {
     variables = {
       SNS_ARN = aws_sns_topic.resoult.arn
     }
   }

}

resource "aws_lambda_permission" "apigw_sum_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sum_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.sum_api.execution_arn}/*/*"

}
