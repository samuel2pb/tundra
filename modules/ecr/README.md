# ecr

Provisions an ECR repository with image scanning on push, immutable tags, and a lifecycle policy.

## Inputs

| name | type | default | required |
|---|---|---|---|
| `repo_name` | string | — | yes |
| `tags` | map(string) | — | yes (must include `domain`, `platform`, `project`) |
| `image_tag_mutability` | string | `IMMUTABLE` | no |
| `scan_on_push` | bool | `true` | no |
| `encryption_type` | string | `AES256` | no |
| `kms_key_arn` | string | `null` | no |
| `keep_last_n_images` | number | `30` | no |
| `untagged_expiration_days` | number | `14` | no |

## Outputs

- `repository_url`
- `repository_arn`
- `repository_name`
