/**
 * ## Usage
 *
 * This example is used by the `TestTerraformSimpleExample` test in `test/terrafrom_aws_simple_test.go`.
 *
 * ## Terraform Version
 *
 * This test was created for Terraform 0.13.
 *
 * ## License
 *
 * This project constitutes a work of the United States Government and is not subject to domestic copyright protection under 17 USC § 105.  However, because the project utilizes code licensed from contributors and other third parties, it therefore is licensed under the MIT License.  See LICENSE file for more information.
 */

module "main" {
  source = "../../"

  name                        = var.name
  description                 = "A key used for testing a terraform modules"
  key_deletion_window_in_days = 7
}
