# platform-buckets

Single S3 bucket for an operational purpose. One module instance per bucket. The `purpose` input drives sensible defaults for versioning, lifecycle, and policy.

## Purposes

| purpose | versioning | current expire | noncurrent expire | extra policy |
|---|---|---|---|---|
| `tfstate` | enabled | never | 365d | deny unencrypted PUTs; `force_destroy` always false |
| `logs` | suspended | 90d | — | allow `delivery.logs.amazonaws.com` to write |
| `artifacts` | enabled | 30d | 30d | — |
| `athena` | suspended | 14d | — | — |

All buckets get: SSE (AES256 by default), public access block, `BucketOwnerEnforced` ownership, `aws:SecureTransport=false` deny, and a 7-day abort-incomplete-multipart rule.

## Inputs

| name | type | default | required |
|---|---|---|---|
| `name` | string | — | yes |
| `purpose` | string | — | yes (`tfstate` / `logs` / `artifacts` / `athena`) |
| `tags` | map(string) | — | yes (must include `domain`, `platform`, `project`) |
| `kms_key_arn` | string | `null` | no |
| `force_destroy` | bool | `false` | no (forced false for `tfstate`) |
| `versioning_override` | bool | `null` | no |
| `expiration_days_override` | number | `null` (0 disables) | no |
| `noncurrent_expiration_days_override` | number | `null` (0 disables) | no |
| `log_delivery_source_account_ids` | list(string) | `[]` | no (only for `purpose=logs`) |
| `ssm_path_prefix` | string | `null` | no — when set, publishes outputs to SSM Parameter Store |

## Outputs

- `bucket_id`
- `bucket_arn`
- `bucket_domain_name`

When `ssm_path_prefix` is set (e.g. `/myorg/prod/buckets/tfstate`), the module writes:

- `${prefix}/id`, `${prefix}/arn`, `${prefix}/fqdn`

## Caller's job

Naming is the caller's responsibility (e.g. `${account}-${env}-tfstate`). The module does not impose a naming scheme.

This module does **not** provision the DynamoDB lock table for `tfstate`. The bootstrap stack in the consumer repo is the right place for that.
