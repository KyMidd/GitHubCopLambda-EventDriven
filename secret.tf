# Create secret to store the PAT for REST calls
# In , this already exists, so we'll just reference it

# Created by hand in both locations
/*
resource "aws_secretsmanager_secret" "github_pat" {
  name       = "GitHubPATRestCalls"

  tags = {
    Terraform = "true"
    Contact   = "DevOps Team"
    Real Contact = "Kyler"
  }
}
*/

# Secret to read so can lookup ARN
data "aws_secretsmanager_secret" "GitHubPAT" {
  name = "GitHubPAT"
}

# Create secret to store github password to sign hash
resource "aws_secretsmanager_secret" "github_webhook_secret" {
  name = "GitHubWebhookSecret"

  tags = {
    Terraform      = "true"
    Contact        = "DevOps Team"
    "Real Contact" = "Kyler"
  }
}