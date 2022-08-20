# Generate new README
terraform-docs markdown . --output-file TMP_README.md | Out-Null

# Replace header
[IO.File]::WriteAllText('TMP_README.md', ([IO.File]::ReadAllText('TMP_README.md') -replace '<!-- BEGIN_TF_DOCS -->', '<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->'))

# Replace trailer
[IO.File]::WriteAllText('TMP_README.md', ([IO.File]::ReadAllText('TMP_README.md') -replace '<!-- END_TF_DOCS -->', '<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->'))

# Append final new line
[IO.File]::WriteAllText('README.md', ([IO.File]::ReadAllText('TMP_README.md') + "`n"))

# Remove intermediate file
Remove-Item -Path TMP_README.md
