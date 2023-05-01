# Build data source to find AWS account id
data "aws_caller_identity" "current" {}

# Get region
data "aws_region" "current" {}
