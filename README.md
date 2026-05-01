# tundra

Terraform module library for the data lake. Companion to [`awebo`](#) (data lake utility).

This repo holds **module definitions only**. A separate consumer repo wires these modules into account compositions and runs `terraform apply`.

## Modules

| module | purpose |
|---|---|
| [`datalake-buckets`](modules/datalake-buckets) | S3 buckets per zone (`raw`, `sot`, `smt`) |
| [`platform-buckets`](modules/platform-buckets) | Operational buckets (`tfstate`, `logs`, `artifacts`, `athena`) |
| [`ecr`](modules/ecr) | ECR repository for the awebo image |
| [`ecs-cluster`](modules/ecs-cluster) | ECS cluster with FARGATE + FARGATE_SPOT capacity providers |
| [`ecs-task-definition`](modules/ecs-task-definition) | Awebo Fargate task definition + log group |
| [`iam-container-role`](modules/iam-container-role) | Task role (Glue catalog + S3 RW) + execution role |

## Conventions

- **Region**: `us-east-1`
- **Required tags** on every resource: `domain`, `platform`, `project`. Modules accept a `tags` map and validate these keys are present.
- **Naming**: caller-driven via `name` / `name_prefix`. Suggested scheme: `${account}-${env}-...`.

## Versions

- Terraform `>= 1.6.0`
- AWS provider `~> 5.0`

## CI

`.github/workflows/ci.yml` runs on every PR:
- `terraform fmt -check -recursive`
- `terraform validate` per module
- `tflint` per module
- `trivy config` scan

## Consuming this repo

Reference modules from a consumer repo via Git source:

```hcl
module "buckets" {
  source = "git::https://github.com/samuel2pb/tundra.git//modules/datalake-buckets?ref=v0.1.0"

  name_prefix = "dodpit-prod-datalake"
  tags = {
    domain   = "data"
    platform = "datalake"
    project  = "awebo"
  }
}
```

Pin `ref` to a tag (recommended) or commit SHA. Branches are not stable references.

The consumer repo is responsible for:
- backend config (S3 + DynamoDB lock)
- bootstrap stack (tfstate bucket, lock table, GitHub OIDC provider, CI deploy role)
- account compositions
- the apply pipeline
