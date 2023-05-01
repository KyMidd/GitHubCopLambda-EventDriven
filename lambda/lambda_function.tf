###
# GitHubCop Trigger Lambda
###

data "archive_file" "githubcop_repo_trigger_lambda" {
  type        = "zip"
  source_file = "${path.module}/GitHubCopTriggerLambdaSource/GitHubCopRepoTrigger.py"
  output_path = "${path.module}/GitHubCopRepoTrigger.zip"
}

resource "aws_lambda_function" "GitHubCop_New_Repo_Trigger" {
  filename      = "${path.module}/GitHubCopRepoTrigger.zip"
  function_name = "GitHubCopRepoTrigger"
  role          = aws_iam_role.GitHubCopNewRepoTriggerRole.arn
  handler       = "GitHubCopRepoTrigger.lambda_handler"
  timeout       = 60

  # Layers are packaged code for lambda
  layers = [
    # This layer permits us to ingest secrets from Secrets Manager
    "arn:aws:lambda:us-east-1:177933569100:layer:AWS-Parameters-and-Secrets-Lambda-Extension:4"
  ]

  source_code_hash = data.archive_file.githubcop_repo_trigger_lambda.output_base64sha256

  runtime = "python3.7"
}
