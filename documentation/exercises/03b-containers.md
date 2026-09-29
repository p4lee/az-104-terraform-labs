# Exercise 03b - Containers (Registry, Container Instances, Container Apps)

Terraform source: `terraform/exercises/03b-containers/`
Exam domain: Deploy and manage Azure compute resources (20-25% of AZ-104)

## What was built

- Resource group `rg-az104-containers`
- An Azure Container Registry, Basic SKU (`modules/container-registry`),
  with **the admin user disabled**
- A user-assigned managed identity `id-containers-pull` holding the
  **AcrPull** role on the registry, reusing `modules/rbac-assignment` from
  exercise 01
- An Azure Container Instance `aci-az104-web` with a public FQDN
- A Log Analytics workspace and a Container Apps environment
- An Azure Container App `ca-az104-web` with external ingress, scaling
  between 0 and 2 replicas

Both container hosts run the **same image** (`az104-web:v1`, nginx serving a
static page), so the comparison is about the hosting model only.

## Notable decisions

- **Managed identity instead of registry credentials.** A registry can have
  an admin user - one username and password that anything can use. Here
  `admin_enabled = false`, and both hosts pull as a managed identity with
  the AcrPull role. Nothing stores a registry password.
- **User-assigned, not system-assigned.** A system-assigned identity is
  created together with its resource, so the first image pull can race the
  role assignment. A user-assigned identity exists first, gets the role,
  and both hosts then share it.
- **`depends_on = [module.acr_pull]`** on both container resources, so the
  role assignment is in place before the first pull is attempted.
- **The apply is split.** Terraform cannot create the containers before the
  image exists, and building an image is an action rather than
  infrastructure: registry first (`-target`), then the image, then the rest.

## Terraform outputs

```
resource_group_name = "rg-az104-containers"
acr_login_server    = "acraz104cclab.azurecr.io"
aci_fqdn            = "az104-web-cclab.swedencentral.azurecontainer.io"
container_app_fqdn  = "ca-az104-web--ie0rcbc.delightfulcliff-d129d760.swedencentral.azurecontainerapps.io"
```

## Container Instances vs Container Apps - what the lab showed

| | Container Instance | Container App |
|---|---|---|
| Creation time | Under a minute | ~10 minutes for the environment (a managed Kubernetes-based platform behind the scenes) |
| Scaling | None - it is one container group | 0 to 2 replicas, automatic |
| Cold start | None, it is always running | First request after idle takes a few seconds (`min_replicas = 0`) |
| TLS | None. Plain HTTP on port 80 | HTTPS with an Azure-managed certificate, HTTP redirects to it |
| Hostname | `<label>.<region>.azurecontainer.io` | `<app>--<revision>.<environment>.<region>.azurecontainerapps.io` |
| Revisions | None - redeploy to change | One per configuration change, with traffic weights |
| Billing | Per second while it exists | Per use, with a monthly free grant |
| Suits | Short jobs, simple always-on containers | HTTP services and event-driven workloads |

The revision name in the container app's hostname
(`ca-az104-web--ie0rcbc`) is what makes blue-green deployments and traffic
splitting possible. ACI has no equivalent.

## Problems hit along the way

**1. ACR Tasks is blocked on trial subscriptions.**
`az acr build` failed with `TasksOperationsNotAllowed`. Azure disables the
managed build service on free trial and new subscriptions, and enabling it
needs a support request. Worked around by building the image locally with
Docker and pushing it:

    az acr login --name <registry>
    docker build -t <registry>.azurecr.io/az104-web:v1 ./app
    docker push <registry>.azurecr.io/az104-web:v1

`az acr login` authenticates with the Azure account rather than the admin
user, so this works with `admin_enabled = false`. The other option is
`az acr import`, which copies a public image into the registry without any
build.

**2. `MissingSubscriptionRegistration: Microsoft.App`.**
The Container Apps environment failed because the resource provider was not
registered on the subscription. Resource providers are registered per
subscription, and many are off until first used:

    az provider register --namespace Microsoft.App
    az provider show --namespace Microsoft.App --query registrationState -o tsv

In the portal: **Subscription -> Settings -> Resource providers**. This sits
alongside quotas and policies as subscription-level governance, and it is
on the exam.

**3. PowerShell mangles `-target=module.x`.**
`terraform apply -target=module.registry` failed with `Invalid target
"module"` - PowerShell split the argument. Quoting the value fixes it:
`-target="module.registry"`.

## Verification in the Azure portal

| # | Screenshot | What it shows |
|---|---|---|
| 1 | `screenshots/01-acr-repositories.png` | The `az104-web` repository and its `v1` tag in the registry |
| 2 | `screenshots/02-acr-admin-disabled.png` | Access keys: admin user disabled, so no password-based pulls |
| 3 | `screenshots/03-acr-iam-acrpull.png` | The AcrPull role assignment on the managed identity - the replacement for that password |
| 4 | `screenshots/04-aci-overview.png` | Container instance running, its FQDN and the image it pulled |
| 5 | `screenshots/05-aci-browser.png` | The page served over plain HTTP - no certificate |
| 6 | `screenshots/06-resource-providers.png` | `Microsoft.App` registered on the subscription |
| 7 | `screenshots/07-container-app-overview.png` | Container app, its URL, revision and environment |
| 8 | `screenshots/08-container-app-browser.png` | The same page over HTTPS with a managed certificate |
| 9 | `screenshots/09-container-app-scale.png` | Scale settings: minimum 0, maximum 2 replicas |

The container instance's nginx log also recorded the browser requests,
confirming traffic reached the container:

    az container logs -g rg-az104-containers -n aci-az104-web --container-name web

## Cost notes

- ACR Basic: about EUR 4.60/month, billed daily
- Container Instance: about EUR 0.02/hour for 0.5 vCPU and 1 GB, per second
- Container App: within the monthly free grant at this size, and scales to zero
- Log Analytics: first 5 GB/month free

Destroyed after documenting.

## What this demonstrates for AZ-104

- Creating a container registry and getting an image into it
- Pulling with a managed identity and the AcrPull role instead of admin
  credentials
- Running a container in Azure Container Instances with a public FQDN
- Running the same image in Azure Container Apps with external ingress,
  revisions and scale to zero
- Choosing between the two services on startup time, TLS, scaling and cost
- Subscription-level resource provider registration
- Splitting an apply when a dependency lives outside Terraform
