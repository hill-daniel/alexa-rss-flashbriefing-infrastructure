variable lambdaCodeBucket {}
variable lambdaCodeFile {}
variable stage {}
variable feedUrl {}

data "aws_iam_policy" "lambda_basic_execution" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role" "lambda_response_exec_role" {
  name = "alexa-flashbriefing-lambda-role-${var.stage}"
  description = "Role for the execution of alexa flashbriefing lambda"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_response_basic_exection" {
  role = "${aws_iam_role.lambda_response_exec_role.name}"
  policy_arn = "${data.aws_iam_policy.lambda_basic_execution.arn}"
}

resource "aws_lambda_function" "response_lambda_func" {
  function_name = "alexa-flashbriefing-${var.stage}"
  handler = "main"
  runtime = "go1.x"
  role = "${aws_iam_role.lambda_response_exec_role.arn}"
  s3_bucket = "${var.lambdaCodeBucket}"
  s3_key = "alexa-flashbriefing-deployment.zip"
  memory_size = 128
  timeout = 10

  environment {
    variables = {
      ATOM_FEED_URL = "${var.feedUrl}"
    }
  }

  tags {
    Name = "alexa-flashbriefing"
    Stage = "${var.stage}"
  }
}

resource "aws_api_gateway_rest_api" "response_lambda_gateway" {
  name = "flashbriefing-gateway-${var.stage}"
  description = "API Gateway for the response lambda function"
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = "${aws_api_gateway_rest_api.response_lambda_gateway.id}"
  parent_id = "${aws_api_gateway_rest_api.response_lambda_gateway.root_resource_id}"
  path_part = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id = "${aws_api_gateway_rest_api.response_lambda_gateway.id}"
  resource_id = "${aws_api_gateway_resource.proxy.id}"
  http_method = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = "${aws_api_gateway_rest_api.response_lambda_gateway.id}"
  resource_id = "${aws_api_gateway_method.proxy.resource_id}"
  http_method = "${aws_api_gateway_method.proxy.http_method}"

  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = "${aws_lambda_function.response_lambda_func.invoke_arn}"
}

resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id = "${aws_api_gateway_rest_api.response_lambda_gateway.id}"
  resource_id = "${aws_api_gateway_rest_api.response_lambda_gateway.root_resource_id}"
  http_method = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = "${aws_api_gateway_rest_api.response_lambda_gateway.id}"
  resource_id = "${aws_api_gateway_method.proxy_root.resource_id}"
  http_method = "${aws_api_gateway_method.proxy_root.http_method}"

  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = "${aws_lambda_function.response_lambda_func.invoke_arn}"
}

resource "aws_api_gateway_deployment" "flashbriefing_deployment" {
  depends_on = [
    "aws_api_gateway_integration.lambda",
    "aws_api_gateway_integration.lambda_root",
  ]

  rest_api_id = "${aws_api_gateway_rest_api.response_lambda_gateway.id}"
  stage_name = "${var.stage}"
}

resource "aws_lambda_permission" "apigw" {
  statement_id = "AllowAPIGatewayInvoke"
  action = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.response_lambda_func.arn}"
  principal = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_deployment.flashbriefing_deployment.execution_arn}/*/*"
}
