# Build data source to find AWS account id
data "aws_caller_identity" "current" {}

# Get region
data "aws_region" "current" {}

# Locals
locals {
  # This is the name of the GitHub Cop repo
  lambda_name = "githubcop-new-repo-trigger"
}

# Build IAM module
module "iam" {
  source                       = "./iam"
  github_webhook_secret_arn = aws_secretsmanager_secret.github_webhook_secret.arn
  github_pat_secret_arn        = data.aws_secretsmanager_secret.GitHubPAT.arn
  lambda_name                  = local.lambda_name
}

# Build Lambda module
module "lambda" {
  source = "./lambda"

  aws_iam_role_GitHubCopNewRepoTriggerRole_arn = module.iam.GitHubCopNewRepoTriggerRole_arn
  lambda_name                                       = local.lambda_name
}