# ecs-task-definition

Fargate-compatible ECS task definition with a single container, plus its CloudWatch log group. Designed to be referenced by external orchestrators (Airflow, Step Functions, etc.) via `RunTask`.

## Inputs

| name | type | default | required |
|---|---|---|---|
| `family` | string | — | yes |
| `image` | string | — | yes |
| `tags` | map(string) | — | yes (must include `domain`, `platform`, `project`) |
| `task_role_arn` | string | — | yes |
| `execution_role_arn` | string | — | yes |
| `region` | string | `us-east-1` | no |
| `cpu` | string | `512` | no |
| `memory` | string | `1024` | no |
| `container_name` | string | `family` | no |
| `command` | list(string) | `[]` | no |
| `entrypoint` | list(string) | `[]` | no |
| `environment` | list(object) | `[]` | no |
| `secrets` | list(object) | `[]` | no |
| `log_group_name` | string | `/ecs/${family}` | no |
| `log_retention_days` | number | `7` | no |
| `ephemeral_storage_gib` | number | `0` (Fargate default 21) | no |
| `runtime_platform` | object | `LINUX` / `X86_64` | no |
| `ssm_path_prefix` | string | `null` | no — when set, publishes outputs to SSM Parameter Store |

## Outputs

- `task_definition_arn`
- `task_definition_arn_without_revision`
- `family`, `revision`
- `container_name`
- `log_group_name`

When `ssm_path_prefix` is set, the module writes `${prefix}/{task_definition_arn,task_definition_arn_without_revision,family,container_name,log_group_name}`.
