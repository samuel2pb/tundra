# tundra

<p align="center">
  <img src="./docs/img/logo.png" alt="tundra" width="480" />
</p>

<p align="center">
  <a href="#modules"><img src="https://img.shields.io/badge/terraform-%3E%3D%201.6.0-7B42BC?logo=terraform" alt="Terraform"></a>
  <a href="#modules"><img src="https://img.shields.io/badge/aws--provider-~%3E%205.0-FF9900?logo=amazonwebservices" alt="AWS Provider"></a>
  <img src="https://img.shields.io/badge/region-us--east--1-blue" alt="Region">
</p>

A small, opinionated Terraform module library for spinning up the cloud pieces of a Fargate-based data lake: S3 zones, operational buckets, a minimal VPC, and an ECS cluster with task roles and task definitions.

Modules are organised by provider under `modules/<provider>/`. The library currently ships AWS modules (`modules/aws/...`); GCP and Azure equivalents will land under `modules/gcp/` and `modules/azure/` as the platform expands.

This repository contains **module definitions only** — no backend config, no compositions, no apply pipeline. A consumer repository wires the modules together and runs `terraform apply`.

## Why

Most published Terraform modules optimise for breadth: every flag, every variant, every cloud quirk. Tundra optimises for *small, sharp defaults* that a single team can read in an afternoon:

- Smallest viable VPC for Fargate (a `/27`, two `/28` public subnets, no NAT)
- S3 buckets locked down by default (public access blocked, TLS-only, ownership enforced)
- Optional SSM Parameter Store publication so downstream tools (Prefect, Airflow, Lambdas) can resolve resource IDs by name instead of hardcoding ARNs

If you need a 200-variable VPC module, look elsewhere. If you want something you can fork and own, this is the size.

## Modules

### AWS (`modules/aws/`)

| module | purpose |
|---|---|
| [`main`](modules/aws/main) | **Top-level composition.** Wires every other AWS module together for the full stack from a single module call. |
| [`datalake-buckets`](modules/aws/datalake-buckets) | One S3 bucket per data lake zone (default `raw`, `sot`, `smt`) |
| [`platform-buckets`](modules/aws/platform-buckets) | Operational buckets (`tfstate`, `logs`, `artifacts`, `athena`) |
| [`vpc`](modules/aws/vpc) | Smallest Fargate-friendly VPC (public subnets, no NAT) |
| [`ecs-cluster`](modules/aws/ecs-cluster) | ECS cluster with `FARGATE` + `FARGATE_SPOT` capacity providers |
| [`ecs-task-definition`](modules/aws/ecs-task-definition) | Fargate task definition + CloudWatch log group |
| [`iam-container-role`](modules/aws/iam-container-role) | Task role (Glue catalog + S3 RW) and execution role |

If you want the whole stack with sane defaults, use [`aws/main`](modules/aws/main). If you need a custom layout, call the leaf modules directly.

### GCP (`modules/gcp/`)

Planned. Not yet shipped.

### Azure (`modules/azure/`)

Planned. Not yet shipped.

Each module has its own README with inputs, outputs, and usage notes.

## Conventions

- **Region**: pinned to `us-east-1`.
- **Required tags**: every module accepts a `tags` map and validates it contains `domain`, `platform`, and `project`.
- **Naming**: caller-driven via `name` / `name_prefix`. Suggested scheme is `${account}-${env}-...`.
- **SSM publication**: every resource-creating module accepts an optional `ssm_path_prefix`. When set, the module's outputs are also published to SSM Parameter Store under that path, which makes them queryable by service-account-style consumers without passing Terraform outputs around.

## Requirements

- Terraform `>= 1.6.0`
- AWS provider `~> 5.0`

## Usage

Reference modules from a consumer repo via Git source. The fastest path is the [`aws/main`](modules/aws/main) composition:

```hcl
module "platform" {
  source = "git::https://github.com/samuel2pb/tundra.git//modules/aws/main?ref=v0.2.0"

  name_prefix = "myorg-prod"
  tags = {
    domain   = "data"
    platform = "datalake"
    project  = "example"
  }

  ssm_path_prefix = "/myorg/prod"

  task_image = "${aws_ecr_repository.app.repository_url}:0.1.0"
}
```

Or call a leaf module directly when you need finer control:

```hcl
module "buckets" {
  source = "git::https://github.com/samuel2pb/tundra.git//modules/aws/datalake-buckets?ref=v0.2.0"

  name_prefix = "myorg-prod"
  tags = {
    domain   = "data"
    platform = "datalake"
    project  = "example"
  }

  ssm_path_prefix = "/myorg/prod/datalake"
}
```

Pin `ref` to a tag (recommended) or a commit SHA. Branches are not stable references.

The consumer repo owns:

- backend configuration (S3 + DynamoDB lock)
- the bootstrap stack (tfstate bucket, lock table, OIDC provider, deploy role)
- account compositions
- the apply pipeline

## Development

Quality checks run locally via [`pre-commit`](https://pre-commit.com). Configuration lives in `.pre-commit-config.yaml`. Install once per checkout:

```sh
pip install pre-commit  # or: brew install pre-commit
pre-commit install
```

Hooks:

- `terraform_fmt`
- `terraform_validate` (with `-backend=false`)
- `terraform_tflint` (uses `.tflint.hcl`)
- `terraform_trivy` (HIGH and CRITICAL only)
- whitespace, EOF newline, YAML, merge-conflict, large-file checks

Run against everything on demand:

```sh
pre-commit run --all-files
```

There is intentionally no CI workflow — checks are enforced at commit time on every contributor's machine.

## Contributing

Issues and PRs welcome. Code ownership is declared in [`.github/CODEOWNERS`](.github/CODEOWNERS); a maintainer review is expected before merge.

For non-trivial changes, open an issue first to discuss scope.

## License

No license has been chosen yet. Until a `LICENSE` file is added, default copyright applies and external use is at the user's risk. Track this in [issue #2](https://github.com/samuel2pb/tundra/issues) (TODO).
