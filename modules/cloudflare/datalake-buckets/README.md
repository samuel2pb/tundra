# datalake-buckets (Cloudflare R2)

Provisions one R2 bucket per data lake zone (default: `raw`, `sot`, `smt`).

Per bucket: lifecycle for incomplete multipart aborts, optional CORS, optional public r2.dev domain, configurable storage class and jurisdiction for data residency.

R2 buckets are S3-compatible — existing tools (DuckDB, Spark, boto3) connect via `https://<account_id>.r2.cloudflarestorage.com`.

## Inputs

| name | type | default | required |
|---|---|---|---|
| `account_id` | string | — | yes |
| `name_prefix` | string | — | yes |
| `zones` | list(string) | `["raw","sot","smt"]` | no |
| `tags` | map(string) | — | yes (must include `domain`, `platform`, `project`) |
| `location` | string | `null` | no — hint: apac, eeur, enam, weur, wnam, oc |
| `jurisdiction` | string | `"default"` | no — default, eu, fedramp |
| `storage_class` | string | `"Standard"` | no — Standard, InfrequentAccess |
| `abort_incomplete_multipart_upload_days` | number | `7` | no |
| `cors_allowed_origins` | list(string) | `[]` | no — pass [] to skip CORS |
| `cors_allowed_methods` | list(string) | `["GET","HEAD"]` | no |
| `enable_managed_domain` | bool | `false` | no — enables r2.dev public access |
| `lifecycle_rules` | list(object) | `[]` | no — additional lifecycle rules |

## Outputs

- `bucket_names` — `{ zone => name }`
- `bucket_ids` — `{ zone => id }`
- `bucket_creation_dates` — `{ zone => timestamp }`
- `bucket_s3_endpoints` — `{ zone => s3_endpoint_url }`
- `managed_domain_urls` — `{ zone => r2.dev_url }` (only when enabled)

## Usage

```hcl
module "datalake" {
  source = "git::https://github.com/yourorg/tundra.git//modules/cloudflare/datalake-buckets?ref=v1.0.0"

  account_id   = "your-cloudflare-account-id"
  name_prefix  = "acme-prod"
  location     = "weur"
  jurisdiction = "eu"

  tags = {
    domain   = "analytics"
    platform = "dataplatform"
    project  = "lakehouse"
  }

  cors_allowed_origins = ["https://app.acme.com"]

  lifecycle_rules = [
    {
      id                = "expire-temp"
      prefix            = "tmp/"
      delete_after_days = 30
    },
    {
      id                          = "archive-old-raw"
      prefix                      = ""
      transition_to_ia_after_days = 90
    },
  ]
}
```
