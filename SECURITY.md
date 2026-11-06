# Security policy

## Reporting a vulnerability

Please do **not** open a public issue for security problems.

Use GitHub's private vulnerability reporting on this repository
("Security" tab → "Report a vulnerability"). You should get an
acknowledgement within a few days.

## Scope

tundra ships Terraform module definitions only. It contains no state,
no backend configuration, and no credentials. Anything the modules
create is locked down by default (public access blocked, TLS-only
buckets, egress-only security groups, IMDSv2 required).

In scope:

- A default that leaves a resource publicly reachable or writable.
- An IAM policy broader than the module README documents.
- A variable whose documented "safe" value is not actually safe.

Out of scope:

- Choices made in the consumer repository (backend, state, overrides).
- Upstream provider bugs. Report those to the Terraform AWS / Cloudflare
  provider projects.

## Supported versions

Only the latest tagged release receives fixes.
