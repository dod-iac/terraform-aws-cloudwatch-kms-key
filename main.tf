/**
 * ## Usage
 *
 * Creates a KMS key used to encrypt data-at-rest stored in CloudWatch Logs
 *
 * ```hcl
 * module "cloudwatch_kms_key" {
 *   source = "dod-iac/cloudwatch-kms-key/aws"
 *
 *   name = "alias/name"
 *
 *   tags = {
 *     Application = var.application
 *     Environment = var.environment
 *     Automation  = "Terraform"
 *   }
 * }
 * ```
  *
 * ## Testing
 *
 * Run all terratest tests using the `terratest` script.  If using `aws-vault`, you could use `aws-vault exec $AWS_PROFILE -- terratest`.  The `AWS_DEFAULT_REGION` environment variable is required by the tests.  Use `TT_SKIP_DESTROY=1` to not destroy the infrastructure created during the tests.  Use `TT_VERBOSE=1` to log all tests as they are run.  The go test command can be executed directly, too.
 *
 * ## Terraform Version
 *
 * Terraform 0.12. Pin module version to ~> 1.0.0 . Submit pull-requests to master branch.
 *
 * Terraform 0.11 is not supported.
 *
 * ## License
 *
 * This project constitutes a work of the United States Government and is not subject to domestic copyright protection under 17 USC § 105.  However, because the project utilizes code licensed from contributors and other third parties, it therefore is licensed under the MIT License.  See LICENSE file for more information.
 */

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

data "aws_iam_policy_document" "cloudwatch" {
  policy_id = "key-policy-cloudwatch"
  statement {
    sid = "Enable IAM User Permissions"
    actions = [
      "kms:*",
    ]
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        format(
          "arn:%s:iam::%s:root",
          data.aws_partition.current.partition,
          data.aws_caller_identity.current.account_id
        )
      ]
    }
    resources = ["*"]
  }
  statement {
    sid = "AllowCloudWatchLogs"
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        format(
          "logs.%s.amazonaws.com",
          data.aws_region.current.name
        )
      ]
    }
    resources = ["*"]
  }
}

resource "aws_kms_key" "cloudwatch" {
  description             = var.description
  deletion_window_in_days = var.key_deletion_window_in_days
  enable_key_rotation     = "true"
  policy                  = data.aws_iam_policy_document.cloudwatch.json
  tags                    = var.tags
}

resource "aws_kms_alias" "cloudwatch" {
  name          = var.name
  target_key_id = aws_kms_key.cloudwatch.key_id
}
