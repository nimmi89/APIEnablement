# This file defines all the infrastructure resources

# Archive multiple files for lambda .
data "archive_file" "lambdafiles" {
  type        = "zip"
  output_path = "${path.module}/lambda.zip"
  source {
    content  = file("../src/getRootResponse.py")
    filename = "getRootResponse.py"
  }
  source {
    content  = file("../src/getHealthStatus.py")
    filename = "getHealthStatus.py"
  }
  source {
    content  = file("../src/getMetadataInfo.py")
    filename = "getMetadataInfo.py"
  }
}

# IAM role to give Lambda function access to CloudWatch.

resource "aws_iam_role" "tf_lambda_role" {
  name = "${var.project-name}-lambda-role"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
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
  tags = {
    Name = "${var.project-name}_lambda_role"
  }
}

resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.tf_lambda_role.id
  policy_arn = aws_iam_policy.lambda_logging.arn
}

# API GATEWAY  [Common]
resource "aws_api_gateway_rest_api" "tf-api-gw" {
  name        = "${var.project-name}-api-gw"
  description = "Myob Serverless Application"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
 
  tags = {
    Name = "${var.project-name}-api-gw"
  }
}

resource "aws_api_gateway_api_key" "tf-api-key" {
  name = "${var.project-name}-api-key"
}

# SSM [Storing the api key value generated]
resource "aws_ssm_parameter" "api_key" {
  name  = "API_KEY"
  type  = "SecureString"
  value = aws_api_gateway_api_key.tf-api-key.value

  lifecycle {
    ignore_changes = [value]
  }
}


# Resource 1 endpoint[Root]

resource "aws_api_gateway_method" "get_root" {
  rest_api_id      = aws_api_gateway_rest_api.tf-api-gw.id
  resource_id      = aws_api_gateway_rest_api.tf-api-gw.root_resource_id
  http_method      = "GET"
  authorization    = "NONE"
  api_key_required = true
}

# LAMBDA 1[Process root resource]

resource "aws_lambda_function" "tf_lambda_fn1" {
  function_name = "${var.project-name}-get-root-response"
  filename         = data.archive_file.lambdafiles.output_path
  source_code_hash = filebase64sha256(data.archive_file.lambdafiles.output_path)
  handler          = "getRootResponse.lambda_handler"
  runtime          = "python3.8"
  role             = aws_iam_role.tf_lambda_role.arn
  tags = {
    Name = "${var.project-name}-get-root-response"
  }
}
resource "aws_lambda_permission" "apigw_lambda1" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.tf_lambda_fn1.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.tf-api-gw.execution_arn}/*/*"
}

resource "aws_api_gateway_integration" "lambda1" {
  rest_api_id             = aws_api_gateway_rest_api.tf-api-gw.id
  resource_id             = aws_api_gateway_method.get_root.resource_id
  http_method             = aws_api_gateway_method.get_root.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  
  uri                     = aws_lambda_function.tf_lambda_fn1.invoke_arn
}

# Resource 2 endpoint[Health]

resource "aws_api_gateway_resource" "health" {
  rest_api_id = aws_api_gateway_rest_api.tf-api-gw.id
  parent_id   = aws_api_gateway_rest_api.tf-api-gw.root_resource_id
  path_part   = "health"
}

resource "aws_api_gateway_method" "get_health" {
  rest_api_id      = aws_api_gateway_rest_api.tf-api-gw.id
  resource_id      = aws_api_gateway_resource.health.id
  http_method      = "GET"
  authorization    = "NONE"
  api_key_required = true
}

# LAMBDA 2[Process health check]
resource "aws_lambda_function" "tf_lambda_fn2" {
  function_name = "${var.project-name}-get-health-status"
  filename = data.archive_file.lambdafiles.output_path
  source_code_hash = filebase64sha256(data.archive_file.lambdafiles.output_path)
  handler  = "getHealthStatus.lambda_handler"
  runtime  = "python3.8"
  role     = aws_iam_role.tf_lambda_role.arn
  tags = {
    Name = "${var.project-name}-get-health-status"
  }

}
resource "aws_lambda_permission" "apigw_lambda2" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.tf_lambda_fn2.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.tf-api-gw.execution_arn}/*/*"
}

resource "aws_api_gateway_integration" "lambda2" {
  rest_api_id             = aws_api_gateway_rest_api.tf-api-gw.id
  resource_id             = aws_api_gateway_method.get_health.resource_id
  http_method             = aws_api_gateway_method.get_health.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  content_handling        = "CONVERT_TO_TEXT"
  uri                     = aws_lambda_function.tf_lambda_fn2.invoke_arn
}

# Resource 3 endpoint[Metadata]
resource "aws_api_gateway_resource" "metadata" {
  rest_api_id = aws_api_gateway_rest_api.tf-api-gw.id
  parent_id   = aws_api_gateway_rest_api.tf-api-gw.root_resource_id
  path_part   = "metadata"
}

resource "aws_api_gateway_method" "get_metadata" {
  rest_api_id   = aws_api_gateway_rest_api.tf-api-gw.id
  resource_id   = aws_api_gateway_resource.metadata.id
  http_method   = "GET"
  authorization = "NONE"
  api_key_required = true
}

# To get git_sha and version
data "aws_ssm_parameter" "tf_git_sha" {
  name = "GIT_SHA"
}
data "aws_ssm_parameter" "tf_app_version" {
  name = "VERSION"
}

# LAMBDA 3[Process metadata Info]
resource "aws_lambda_function" "tf_lambda_fn3" {
  function_name = "${var.project-name}-get-app-info"
  # The bucket storing the source code artifact
  #s3_bucket        = "${var.project-name}-s3-bucket"
  #s3_key           = "v${var.app-version}/lambda.zip"
  runtime          = "python3.8"
  role             = aws_iam_role.tf_lambda_role.arn
  filename         = data.archive_file.lambdafiles.output_path
  handler          = "getMetadataInfo.lambda_handler"
  environment {
    variables = {
      GIT_SHA = data.aws_ssm_parameter.tf_git_sha.value
      VERSION = data.aws_ssm_parameter.tf_app_version.value
    }
  }
  tags = {
    Name = "${var.project-name}-get-app-info"
  }
  depends_on = [
    data.aws_ssm_parameter.tf_git_sha,
    data.aws_ssm_parameter.tf_app_version,
    ]

}

resource "aws_lambda_permission" "apigw_lambda3" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.tf_lambda_fn3.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.tf-api-gw.execution_arn}/*/*"
}

resource "aws_api_gateway_integration" "lambda3" {
  rest_api_id = aws_api_gateway_rest_api.tf-api-gw.id
  resource_id = aws_api_gateway_method.get_metadata.resource_id
  http_method = aws_api_gateway_method.get_metadata.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  content_handling        = "CONVERT_TO_TEXT"
  uri                     = aws_lambda_function.tf_lambda_fn3.invoke_arn
}

# API DEPLOYMENT
resource "aws_api_gateway_deployment" "tf-gw-deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda1,
    aws_api_gateway_integration.lambda2,
    aws_api_gateway_integration.lambda3,
  ]

  rest_api_id = aws_api_gateway_rest_api.tf-api-gw.id
  stage_name  = "v1OpsTechnicalTest"
}


resource "aws_api_gateway_usage_plan" "tf-gw-usage-plan" {
  name        = "${var.project-name}-gw-usage-plan"
  description = "usage plan for version v1.0"

  api_stages {
    api_id = aws_api_gateway_rest_api.tf-api-gw.id
    stage  = aws_api_gateway_deployment.tf-gw-deployment.stage_name
  }
}

resource "aws_api_gateway_usage_plan_key" "v1" {
  key_id        = aws_api_gateway_api_key.tf-api-key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.tf-gw-usage-plan.id
}


