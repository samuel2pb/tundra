# datalake-buckets

Provisions one S3 bucket per data lake zone (default: `raw`, `sot`, `smt`).

Per bucket: versioning enabled, SSE (S3 or KMS), public access blocked, ownership `BucketOwnerEnforced`, lifecycle for incomplete multipart aborts and noncurrent version expiration.

## Inputs

| name | type | default | required |
|---|---|---|---|
| `name_prefix` | string | — | yes |
| `zones` | list(string) | `["raw","sot","smt"]` | no |
| `tags` | map(string) | — | yes (must include `domain`, `platform`, `project`) |
| `kms_key_arn` | string | `null` (uses AES256) | no |
| `noncurrent_version_expiration_days` | number | `90` | no |
| `abort_incomplete_multipart_upload_days` | number | `7` | no |

## Outputs

- `bucket_ids` — `{ zone => bucket_id }`
- `bucket_arns` — `{ zone => arn }`
- `bucket_domain_names` — `{ zone => regional_domain_name }`
