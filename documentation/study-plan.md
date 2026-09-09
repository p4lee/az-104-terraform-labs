# AZ-104 Study Plan

Source: official Microsoft Learn study guide for Exam AZ-104: Microsoft Azure Administrator (last updated April 2026). Passing score is 700, exam length is 100 minutes.

This plan is built for a 2-3 week intensive timeline, starting 2026-09-09, with a target exam date around late September 2026. It assumes AZ-900 knowledge and hands-on experience with Entra ID, Conditional Access, MFA, and PIM, so those topics get a light pass instead of a full introduction.

## Exam domains and weights

| Domain | Weight |
|---|---|
| Manage Azure identities and governance | 20-25% |
| Deploy and manage Azure compute resources | 20-25% |
| Implement and manage storage | 15-20% |
| Implement and manage virtual networking | 15-20% |
| Monitor and maintain Azure resources | 10-15% |

## A note on identity and governance

This domain has three parts, and only one overlaps with your background:

1. Microsoft Entra users, groups, licensing, external users, SSPR - you know this. Quick review only.
2. Azure RBAC - built-in roles, scope (management group, subscription, resource group, resource), interpreting access assignments. This is a different system from Entra directory roles and is a common source of exam confusion. Needs real attention.
3. Subscription governance - Azure Policy, resource locks, tags, management groups, cost management (budgets, alerts, Azure Advisor). Mostly new territory. Needs real attention.

## Week 1: Governance and Compute

Day 1: Set up an Azure free trial (needed for every lab from here on). Refresh on Azure Portal, Azure CLI, and Azure PowerShell basics. Management groups and subscriptions.

Day 2: Azure RBAC - built-in roles, assigning roles at different scopes, interpreting effective access.

Day 3: Azure Policy, resource locks, tags, cost management (budgets, alerts, Azure Advisor recommendations).

Day 4-5: Virtual machines - creation, sizing, disks, encryption at host, moving VMs across resource groups/subscriptions/regions, availability sets and availability zones, VM scale sets.

Day 6: ARM templates and Bicep - reading and modifying templates, deploying them, exporting a deployment as a template, converting ARM to Bicep.

Day 7: Containers (Azure Container Registry, Container Instances, Container Apps) and Azure App Service (plans, scaling, deployment slots, custom domains, TLS, backup).

## Week 2: Storage and Networking

Day 8: Storage accounts - creation, redundancy options, object replication, encryption.

Day 9: Access control for storage - firewalls and virtual networks, SAS tokens, stored access policies, access keys, identity-based access for Azure Files.

Day 10: Azure Blob Storage - containers, storage tiers, lifecycle management, versioning, soft delete.

Day 11: Azure Files - file shares, snapshots, soft delete. Azure Storage Explorer and AzCopy.

Day 12: Virtual networks - creation, subnets, peering, public IP addresses, user-defined routes, connectivity troubleshooting.

Day 13: Network security - NSGs, application security groups, effective security rules, Azure Bastion, service endpoints, private endpoints.

Day 14: Name resolution and load balancing - Azure DNS, internal/public load balancers, load balancer troubleshooting.

## Week 3: Monitoring, Backup, and review

Day 15: Azure Monitor - metrics, log settings, log queries, alert rules, action groups, Monitor Insights for VMs/storage/networks.

Day 16: Network Watcher and Connection Monitor.

Day 17: Backup and recovery - Recovery Services vault, Azure Backup vault, backup policies, backup/restore operations, backup reports and alerts.

Day 18: Azure Site Recovery - configuration and failover to a secondary region.

Day 19-20: Full practice exam, then review weak areas from the results.

Day 21: Final review of the topics that gave the most trouble, plus exam logistics (ID requirements, check-in process, what's allowed at the desk).

## How to use this plan

Each day should mix reading (Microsoft Learn modules for that topic) with a hands-on task in the Azure portal or CLI - actually creating the resource, not just reading about it. This matters more for compute, storage, and networking than for governance, since those are the areas most likely to show up as portal-based or drag-and-drop questions on the exam.

Progress notes and finished labs can go in /drafts while in progress, and finished write-ups or exam-readiness notes can move to /outputs when done.
