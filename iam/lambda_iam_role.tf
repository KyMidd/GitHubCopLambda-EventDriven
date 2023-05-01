data "aws_iam_policy_document" "GitHubCopNewRepoTriggerRole_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "GitHubCopNewRepoTriggerRole" {
  name               = "GitHubCopNewRepoTriggerRole"
  assume_role_policy = data.aws_iam_policy_document.GitHubCopNewRepoTriggerRole_assume_role.json
}

resource "aws_iam_role_policy" "GitHubCopRepoTrigger_ReadSecrets" {
  name = "ReadSecret"
  role = aws_iam_role.GitHubCopNewRepoTriggerRole.id

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "secretsmanager:GetResourcePolicy",
            "secretsmanager:GetSecretValue",
            "secretsmanager:DescribeSecret",
            "secretsmanager:ListSecretVersionIds"
          ],
          "Resource" : [
            var.github_pat_secret_arn,
            var.github_webhook_secret_arn
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : "secretsmanager:ListSecrets",
          "Resource" : "*"
        },
        {
          "Effect": "Allow",
          "Action": [
            "kms:Decrypt"
          ],
          "Resource": [
            data.aws_secretsmanager_secret.github_pat_secret_kms_cmk_arn.kms_key_id
          ]
        }
      ]
    }
  )
}

data "aws_secretsmanager_secret" "github_pat_secret_kms_cmk_arn" {
  arn = var.github_pat_secret_arn
}
# data.aws_secretsmanager_secret.github_pat_secret_kms_cmk_arn.kms_key_id

resource "aws_iam_role_policy" "GitHubCopRepoTrigger_Cloudwatch" {
  name = "Cloudwatch"
  role = aws_iam_role.GitHubCopNewRepoTriggerRole.id

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : "logs:CreateLogGroup",
          "Resource" : "arn:aws:logs:us-east-1:${data.aws_caller_identity.current.id}:*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          "Resource" : [
            "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.id}:log-group:/aws/lambda/${var.lambda_name}:*"
          ]
        }
      ]
    }
  )
}
