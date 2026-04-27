# Mini Project 2
# Khushi Prajapati

Error: Terraform Provider Plugin Fails to Start
[Error Message]
[Error: Failed to load plugin schemas]
[timeout while waiting for plugin to start]

Cause
This error usually happens in environments like Vagrant or restricted Linux VMs where:

Terraform cannot write to default system temp directories
Plugin cache directory is missing or not writable
AWS provider fails to initialize due to environment restrictions

Fix
Create custom temporary and plugin cache directories, and set environment variables before running Terraform:

mkdir -p ~/tmp ~/terraform-plugin-cache

export TMPDIR=~/tmp
export TF_PLUGIN_CACHE_DIR=~/terraform-plugin-cache

Then run:
terraform init -upgrade
terraform validate

Why this works
TMPDIR → tells Terraform where to store temporary files (fixes permission issues)
TF_PLUGIN_CACHE_DIR → stores provider plugins locally and avoids repeated downloads
Prevents plugin startup failures caused by system restrictions

Important Notes
These export commands are temporary (they reset after terminal closes)
If the issue happens again, re-run the export commands
