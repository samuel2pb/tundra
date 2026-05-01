# ecs-cluster

Provisions an ECS cluster with `FARGATE` and `FARGATE_SPOT` capacity providers. Default strategy points at Fargate Spot. No services are created — orchestrators (e.g. Airflow, Step Functions) call `RunTask` against this cluster.

## Inputs

| name | type | default | required |
|---|---|---|---|
| `name` | string | — | yes |
| `tags` | map(string) | — | yes (must include `domain`, `platform`, `project`) |
| `default_capacity_provider` | string | `FARGATE_SPOT` | no |
| `enable_container_insights` | bool | `true` | no |

## Outputs

- `cluster_arn`
- `cluster_name`
- `cluster_id`
