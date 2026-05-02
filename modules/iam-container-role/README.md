# iam-container-role

Two IAM roles for an ECS container workload:

- **Task role** — assumed by the application at runtime. Grants S3 read/write on the supplied bucket ARNs and account-wide Glue Data Catalog read/write.
- **Execution role** — assumed by the ECS agent. Attaches `AmazonECSTaskExecutionRolePolicy` (ECR pull, CloudWatch logs). Optionally extended with Secrets Manager / SSM read and KMS decrypt for secrets injection.

## Inputs

| name | type | default | required |
|---|---|---|---|
| `name_prefix` | string | — | yes |
| `tags` | map(string) | — | yes (must include `domain`, `platform`, `project`) |
| `bucket_arns` | list(string) | — | yes |
| `additional_task_policy_statements` | any | `[]` | no |
| `execution_role_kms_key_arns` | list(string) | `[]` | no |
| `execution_role_secret_arns` | list(string) | `[]` | no |
| `ssm_path_prefix` | string | `null` | no — when set, publishes role ARNs/names to SSM Parameter Store |

`bucket_arns` should be the bucket-level ARNs (e.g. `arn:aws:s3:::my-bucket`). Both bucket-level and `bucket/*` actions are granted.

## Outputs

- `task_role_arn`, `task_role_name`
- `execution_role_arn`, `execution_role_name`

When `ssm_path_prefix` is set, all four outputs are published as `${prefix}/<output_name>`.
