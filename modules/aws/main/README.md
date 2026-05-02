# aws/main

Top-level composition that wires every AWS module together. Use this when you want the full Fargate-on-AWS data lake stack — VPC, S3 zones, operational buckets, ECS cluster, IAM roles, and task definition — provisioned from a single module call.

If you need a custom layout (different naming, partial resources, separate state), call the underlying modules directly instead.

## What it provisions

- A `/27` VPC with public-only subnets (`vpc`)
- One bucket per data lake zone (`datalake-buckets`)
- Operational buckets selected via `platform_buckets` (`platform-buckets`)
- ECS cluster with Fargate + Fargate Spot (`ecs-cluster`)
- Task and execution IAM roles, scoped to the data lake buckets (`iam-container-role`)
- Optional Fargate task definition + log group (`ecs-task-definition`) — created only when `task_image` is set

## Inputs

The minimum a caller has to provide is **`account_id`**, **`account_name`**, and **`tags`**. Everything else has a default that you can override per use case.

| name | type | default | required |
|---|---|---|---|
| `account_id` | string | — | yes (12-digit AWS account ID) |
| `account_name` | string | — | yes (lowercase, dashes allowed; used as default name prefix and SSM root) |
| `tags` | map(string) | — | yes (must include `domain`, `platform`, `project`; the module merges `account_id` and `account_name` automatically) |
| `region` | string | `us-east-1` | no |
| `name_prefix` | string | `account_name` | no — override only when you want a different prefix from the account name |
| `ssm_path_prefix` | string | `/${account_name}` | no — pass `""` to disable SSM publication |
| `vpc_cidr_block` | string | `10.0.0.0/27` | no |
| `vpc_az_count` | number | `2` | no |
| `datalake_zones` | list(string) | `["raw","sot","smt"]` | no |
| `datalake_kms_key_arn` | string | `null` | no |
| `platform_buckets` | list(string) | `["tfstate","logs","artifacts","athena"]` | no — pass `[]` to skip |
| `default_capacity_provider` | string | `FARGATE_SPOT` | no |
| `enable_container_insights` | bool | `true` | no |
| `additional_task_policy_statements` | any | `[]` | no |
| `execution_role_kms_key_arns` | list(string) | `[]` | no |
| `execution_role_secret_arns` | list(string) | `[]` | no |
| `task_image` | string | `null` | no — when null, the task definition is skipped |
| `task_family` | string | `name_prefix` | no |
| `task_cpu` | string | `512` | no |
| `task_memory` | string | `1024` | no |
| `task_command` | list(string) | `[]` | no |
| `task_entrypoint` | list(string) | `[]` | no |
| `task_environment` | list(object) | `[]` | no |
| `task_secrets` | list(object) | `[]` | no |
| `log_retention_days` | number | `7` | no |

## Outputs

- `vpc_id`, `public_subnet_ids`, `tasks_security_group_id`
- `datalake_bucket_ids` / `datalake_bucket_arns` (maps `zone => value`)
- `platform_bucket_ids` / `platform_bucket_arns` (maps `purpose => value`)
- `cluster_arn`, `cluster_name`
- `task_role_arn`, `execution_role_arn`
- `task_definition_arn`, `task_definition_arn_without_revision`, `log_group_name` — `null` when `task_image` is unset

## Defaults derived from `account_name`

Unless overridden, the module derives:

- **Name prefix** for every child resource = `account_name`
  - VPC: `${account_name}`
  - Data lake buckets: `${account_name}-${zone}` (e.g. `prod-raw`)
  - Operational buckets: `${account_name}-${purpose}` (e.g. `prod-tfstate`)
  - ECS cluster: `${account_name}`
  - IAM roles: `${account_name}-task`, `${account_name}-execution`
  - Task family: `${account_name}`
- **SSM root path** = `/${account_name}`, with each module publishing under a sub-path:
  - `/${account_name}/vpc/...`
  - `/${account_name}/datalake/...`
  - `/${account_name}/buckets/${purpose}/...`
  - `/${account_name}/ecs/cluster/...`
  - `/${account_name}/ecs/task/...`
  - `/${account_name}/iam/...`
- **Tags** = caller-supplied `tags` plus `account_id` and `account_name` injected automatically.

The module also asserts at plan time that the active AWS provider's account matches `var.account_id`, so a misconfigured provider never silently deploys into the wrong account.

## Examples

**Minimal — use everything default:**

```hcl
module "platform" {
  source = "git::https://github.com/samuel2pb/tundra.git//modules/aws/main?ref=v0.1.0"

  account_id   = "111122223333"
  account_name = "prod"

  tags = {
    domain   = "data"
    platform = "datalake"
    project  = "example"
  }
}
```

**With a container image, custom region, and overrides:**

```hcl
module "platform" {
  source = "git::https://github.com/samuel2pb/tundra.git//modules/aws/main?ref=v0.1.0"

  account_id   = "111122223333"
  account_name = "prod"
  region       = "eu-west-1"

  tags = {
    domain   = "data"
    platform = "datalake"
    project  = "example"
  }

  # Override the default name prefix
  name_prefix = "myorg-prod"

  # Override the default SSM root
  ssm_path_prefix = "/myorg/prod"

  task_image = "${aws_ecr_repository.app.repository_url}:0.1.0"
  task_environment = [
    { name = "ENV", value = "prod" },
  ]
}
```
