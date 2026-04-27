# Mini Project 2
# Khushi Prajapati

## ⚠️ Fix for Terraform Plugin Error (Vagrant Users)

If you encounter the following error while running Terraform:

```
Error: Failed to load plugin schemas
timeout while waiting for plugin to start
```

This usually happens in Vagrant or restricted Linux environments where Terraform cannot properly use system temporary directories or plugin cache.

### ✅ Solution

Run the following commands before `terraform init`:

```
mkdir -p ~/tmp ~/terraform-plugin-cache
export TMPDIR=~/tmp
export TF_PLUGIN_CACHE_DIR=~/terraform-plugin-cache
```

Then re-run:

```
terraform init -upgrade
```

### 📝 Notes

* These environment variables are temporary and reset after restarting the VM
* If the issue occurs again, just run the same commands again
* This fix is commonly required when using Terraform inside Vagrant
