# AWS modules

Terraform modules targeting the AWS provider.

| module | purpose |
|---|---|
| [`datalake-buckets`](datalake-buckets) | One S3 bucket per data lake zone (default `raw`, `sot`, `smt`) |
| [`platform-buckets`](platform-buckets) | Operational buckets (`tfstate`, `logs`, `artifacts`, `athena`) |
| [`vpc`](vpc) | Smallest Fargate-friendly VPC (public subnets, no NAT) |
| [`ecs-cluster`](ecs-cluster) | ECS cluster with `FARGATE` + `FARGATE_SPOT` capacity providers |
| [`ecs-task-definition`](ecs-task-definition) | Fargate task definition + CloudWatch log group |
| [`iam-container-role`](iam-container-role) | Task role (Glue catalog + S3 RW) and execution role |

All modules pin `aws ~> 5.0` and Terraform `>= 1.6.0`. See each module's README for inputs and outputs.
