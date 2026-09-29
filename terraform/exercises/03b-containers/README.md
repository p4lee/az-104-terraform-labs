# Exercise 03b - Containers (Registry, Container Instances, Container Apps)

Terraform source: `terraform/exercises/03b-containers/`
Exam domain: Deploy and manage Azure compute resources (20-25% of AZ-104)

## What is built

- Resource group `rg-az104-containers`
- An Azure Container Registry (Basic SKU, `modules/container-registry`) with
  **the admin user disabled**
- A user-assigned managed identity (`id-containers-pull`) holding the
  **AcrPull** role on the registry, reusing `modules/rbac-assignment` from
  exercise 01
- An Azure Container Instance (`aci-az104-web`) with a public FQDN
- A Log Analytics workspace and a Container Apps environment
- An Azure Container App (`ca-az104-web`) with external ingress, scaling
  between 0 and 2 replicas

Both container hosts run the **same image**, so the comparison is about the
hosting model rather than the workload.

## Why a managed identity instead of registry credentials

A registry can have an admin user - one username and password that anything
can use to pull. It is the quick path, and it is what most tutorials show.

This exercise does it the way a real environment should: `admin_enabled =
false`, a managed identity with the `AcrPull` role, and both container hosts
authenticating as that identity. Nothing stores a registry password.

The identity is **user-assigned** rather than system-assigned so the role
can be granted before any container exists. A system-assigned identity is
created with its resource, so the first image pull can race the role
assignment.

## Container Instances vs Container Apps

| | Container Instance | Container App |
|---|---|---|
| Model | One container group, no orchestration | Managed, Kubernetes-based platform |
| Scaling | Manual: you change the resource | Automatic, including scale to zero |
| Ingress | A public IP and optional DNS label | Built-in HTTPS ingress with a managed certificate |
| Revisions | None - redeploy to change | Revisions with traffic splitting |
| Billing | Per second while it exists | Per use, with a monthly free grant |
| Suits | Short jobs, simple always-on containers | HTTP services and event-driven workloads |

## Note: ACR Tasks is blocked on trial subscriptions

`az acr build` returns `TasksOperationsNotAllowed` on free trial and new
subscriptions - Azure disables the managed build service there, and
enabling it needs a support request. Two ways around it:

    # build locally (needs Docker) and push
    az acr login --name <registry>
    docker build -t <registry>.azurecr.io/az104-web:v1 ./app
    docker push <registry>.azurecr.io/az104-web:v1

    # or copy a public image into the registry, no build at all
    az acr import --name <registry> --source docker.io/library/nginx:alpine --image az104-web:v1

`az acr login` authenticates with your Azure account, so it works with the
admin user disabled.

## Order of operations

Terraform cannot create the containers before the image exists in the
registry, and building an image is an action rather than infrastructure, so
the apply is split:

    cd terraform/exercises/03b-containers
    cp terraform.tfvars.example terraform.tfvars
    # edit terraform.tfvars: pick a globally unique acr_name and aci_dns_label

    terraform init `
      -backend-config="resource_group_name=<from bootstrap output>" `
      -backend-config="storage_account_name=<from bootstrap output>"

    # 1. registry only
    terraform apply -target=module.registry -target=module.resource_group

    # 2. build and push the image in Azure - no local Docker needed
    az acr build --registry <acr_name> --image az104-web:v1 ./app

    # 3. everything else
    terraform apply

`-target` is usually a warning sign, but this is the case it exists for: a
real dependency that Terraform does not manage.

## Verifying

    terraform output aci_fqdn            # open in a browser
    terraform output container_app_fqdn  # open in a browser (https)

    az acr repository list --name <acr_name> -o table
    az container logs -g rg-az104-containers -n aci-az104-web --container-name web

## Cost notes

- ACR Basic: about EUR 4.60/month, billed daily - a day or two costs cents
- Container Instance: about EUR 0.02/hour for 0.5 vCPU and 1 GB, per second
- Container App: covered by the monthly free grant at this size, and scales
  to zero when idle
- Log Analytics: first 5 GB/month free

Run `terraform destroy` when the exercise is documented. The container
instance is the only piece that costs while idle.

## What this demonstrates for AZ-104

- Creating a container registry and pushing an image with `az acr build`
- Pulling from a registry with a managed identity and the AcrPull role
  instead of admin credentials
- Running a container in Azure Container Instances with a public FQDN
- Running the same image in Azure Container Apps with external ingress,
  revisions and scale to zero
- Choosing between the two services
- Splitting an apply when a dependency lives outside Terraform
