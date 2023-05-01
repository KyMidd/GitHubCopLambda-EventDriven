###
# API Gateway for GitHubCop Trigger Lambda
###

resource "aws_api_gateway_rest_api" "github_cop_api_gateway" {
  name        = "GitHubCopApiGateway"
  description = "GitHubCop API Gateway"
}

resource "aws_api_gateway_resource" "github_cop_api_gateway_proxy" {
  rest_api_id = aws_api_gateway_rest_api.github_cop_api_gateway.id
  parent_id   = aws_api_gateway_rest_api.github_cop_api_gateway.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "github_cop_api_gateway_method" {
  rest_api_id   = aws_api_gateway_rest_api.github_cop_api_gateway.id
  resource_id   = aws_api_gateway_resource.github_cop_api_gateway_proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "github_cop_api_gateway_proxy_root" {
  rest_api_id   = aws_api_gateway_rest_api.github_cop_api_gateway.id
  resource_id   = aws_api_gateway_rest_api.github_cop_api_gateway.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "github_cop_api_gateway_lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.github_cop_api_gateway.id
  resource_id = aws_api_gateway_method.github_cop_api_gateway_method.resource_id
  http_method = aws_api_gateway_method.github_cop_api_gateway_method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.GitHubCop_New_Repo_Trigger.invoke_arn
}

resource "aws_api_gateway_integration" "github_cop_api_gateway_lambda_root" {
  rest_api_id = aws_api_gateway_rest_api.github_cop_api_gateway.id
  resource_id = aws_api_gateway_method.github_cop_api_gateway_proxy_root.resource_id
  http_method = aws_api_gateway_method.github_cop_api_gateway_proxy_root.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.GitHubCop_New_Repo_Trigger.invoke_arn
}

resource "aws_api_gateway_deployment" "github_cop_api_gateway_deployment" {
  depends_on = [
    aws_api_gateway_integration.github_cop_api_gateway_lambda_integration,
    aws_api_gateway_integration.github_cop_api_gateway_lambda_root,
  ]

  rest_api_id = aws_api_gateway_rest_api.github_cop_api_gateway.id
  stage_name  = "cop"
}

resource "aws_lambda_permission" "lambda_permission" {
  statement_id  = "APIGatewayToGitHubCopNewRepoTriggerLambda"
  action        = "lambda:InvokeFunction"
  function_name = "GitHubCopRepoTrigger"
  principal     = "apigateway.amazonaws.com"

  # The /* part allows invocation from any stage, method and resource path
  # within API Gateway.
  source_arn = "${aws_api_gateway_rest_api.github_cop_api_gateway.execution_arn}/*"
}
