# Bootstrap: remote state storage

Creates the resource group, storage account, and blob container that every
exercise under `terraform/exercises/` uses as its remote state backend.

This is the one config in the whole project that intentionally uses **local**
state - it creates the storage account other configs depend on, so it can't
depend on that backend itself. Its local `terraform.tfstate` file is
gitignored; treat this folder's state file as something you keep safe on
your own machine (or back up), since losing it means losing track of these
resources.

## Run it once

    cd terraform/bootstrap
    cp terraform.tfvars.example terraform.tfvars
    # edit terraform.tfvars: pick a globally unique storage_account_name
    terraform init
    terraform plan
    terraform apply

## Then note the outputs

`terraform output` after apply gives you `resource_group_name`,
`storage_account_name`, and `container_name`. You'll pass these to every
exercise's `terraform init` as `-backend-config` values - see each
exercise's README.
