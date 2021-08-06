// =================================================================
//
// Work of the U.S. Department of Defense, Defense Digital Service.
// Released as open source under the MIT License.  See LICENSE file.
//
// =================================================================

package test

import (
	"context"
	"fmt"
	"os"
	"strings"
	"testing"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/kms"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/require"
)

func TestTerraformSimpleExample(t *testing.T) {

	// Allow test to run in parallel with other tests
	t.Parallel()

	region := os.Getenv("AWS_DEFAULT_REGION")

	// If AWS_DEFAULT_REGION environment variable is not set, then fail the test.
	require.NotEmpty(t, region, "missing environment variable AWS_DEFAULT_REGION")

	// Append a random suffix to the test name, so individual test runs are unique.
	// When the test runs again, it will use the existing terraform state,
	// so it should override the existing infrastructure.
	testName := fmt.Sprintf("terratest-key-simple-%s", strings.ToLower(random.UniqueId()))

	tags := map[string]interface{}{
		"Automation": "Terraform",
		"Terratest":  "yes",
		"Test":       "TestTerraformSimpleExample",
	}

	keyName := fmt.Sprintf("alias/terratest-%s", strings.ToLower(random.UniqueId()))
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// TerraformDir is where the terraform state is found.
		TerraformDir: "../examples/simple",
		// Set the variables passed to terraform
		Vars: map[string]interface{}{
			"test_name": testName,
			"tags":      tags,
			"name":      keyName,
		},
		// Set the environment variables passed to terraform.
		// AWS_DEFAULT_REGION is the only environment variable strictly required,
		// when using the AWS provider.
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": region,
		},
	})

	// If TT_SKIP_DESTROY is set to "1" then do not destroy the intrastructure,
	// at the end of the test run
	if os.Getenv("TT_SKIP_DESTROY") != "1" {
		defer terraform.Destroy(t, terraformOptions)
	}

	// InitAndApply runs "terraform init" and then "terraform apply"
	terraform.InitAndApply(t, terraformOptions)

	// Retrieve some trivial output from the terrafrom test run
	outputTestName := terraform.Output(t, terraformOptions, "test_name")
	outputKMSAliasARN := terraform.Output(t, terraformOptions, "aws_kms_alias_arn")
	outputKMSAliasName := terraform.Output(t, terraformOptions, "aws_kms_alias_name")
	outputKMSKeyARN := terraform.Output(t, terraformOptions, "aws_kms_key_arn")

	// Test that the output is what is expected.
	require.Equal(t, outputTestName, testName)
	require.True(t, len(outputKMSAliasARN) > 0)
	require.Equal(t, keyName, outputKMSAliasName)
	require.True(t, len(outputKMSKeyARN) > 0)

	awsCfg, errCfg := config.LoadDefaultConfig(context.TODO(), config.WithRegion(region))
	require.NoError(t, errCfg)
	svcKMS := kms.NewFromConfig(awsCfg)

	describeKeyOutput, errDescribeKey := svcKMS.DescribeKey(context.TODO(), &kms.DescribeKeyInput{
		KeyId: &keyName,
	})
	require.NoError(t, errDescribeKey)
	require.Equal(t, outputKMSKeyARN, *describeKeyOutput.KeyMetadata.Arn)

	listAliasesOutput, errListAliases := svcKMS.ListAliases(context.TODO(), &kms.ListAliasesInput{
		KeyId: describeKeyOutput.KeyMetadata.Arn,
	})
	require.NoError(t, errListAliases)
	require.Equal(t, outputKMSAliasARN, *listAliasesOutput.Aliases[0].AliasArn)

	getKeyPolicyOutput, errGetKeyPolicy := svcKMS.GetKeyPolicy(context.TODO(), &kms.GetKeyPolicyInput{
		KeyId:      describeKeyOutput.KeyMetadata.Arn,
		PolicyName: aws.String("default"),
	})
	require.NoError(t, errGetKeyPolicy)
	require.True(t, len(*getKeyPolicyOutput.Policy) > 0)
}
