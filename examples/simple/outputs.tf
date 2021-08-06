// =================================================================
//
// Work of the U.S. Department of Defense, Defense Digital Service.
// Released as open source under the MIT License.  See LICENSE file.
//
// =================================================================

output "tags" {
  value = var.tags
}

output "test_name" {
  value = var.test_name
}

output "aws_kms_alias_arn" {
  value = module.main.aws_kms_alias_arn
}

output "aws_kms_alias_name" {
  value = module.main.aws_kms_alias_name
}

output "aws_kms_key_arn" {
  value = module.main.aws_kms_key_arn
}
