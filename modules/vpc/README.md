# vpc

Smallest viable VPC for Fargate tasks that egress to public internet (e.g. Prefect Cloud API, ECR pulls). Public subnets only — tasks launch with `assign_public_ip = true` and rely on a security group that denies all inbound.

## Layout

- VPC `/27` (32 IPs)
- `az_count` public subnets `/28` (11 usable each)
- Internet gateway, single public route table
- Default security group locked (no rules)
- `tasks_egress_only` SG: all outbound, zero inbound

No NAT gateway, no private subnets, no VPC endpoints. Cost is the IGW (free) + data transfer.

## Inputs

| name | type | default | required |
|---|---|---|---|
| `name` | string | — | yes |
| `tags` | map(string) | — | yes (must include `domain`, `platform`, `project`) |
| `cidr_block` | string | `10.0.0.0/27` | no |
| `az_count` | number | `2` | no |
| `ssm_path_prefix` | string | `null` | no — when set, publishes outputs to SSM Parameter Store |

## Outputs

- `vpc_id`
- `vpc_cidr_block`
- `public_subnet_ids`
- `availability_zones`
- `internet_gateway_id`
- `tasks_security_group_id`

When `ssm_path_prefix` is set (e.g. `/myorg/prod/vpc`), the module writes `${prefix}/{id,cidr,internet_gateway_id,tasks_security_group_id}` as `String` parameters and `${prefix}/{public_subnet_ids,availability_zones}` as `StringList`.

## Usage with ECS Fargate

When running tasks (e.g. via Prefect ECS push pool), set:

```
network_configuration {
  subnets          = module.vpc.public_subnet_ids
  security_groups  = [module.vpc.tasks_security_group_id]
  assign_public_ip = true
}
```

`assign_public_ip = true` is required — without a NAT, tasks need an ephemeral public IP to reach ECR / Prefect API / Secrets Manager.
