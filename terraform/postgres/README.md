# PostgreSQL

Terraform manages service databases, roles, and grants. Database maintenance
scripts accompany that configuration without representing transient planner
statistics as Terraform resources.

`scripts/analyze_authentik.sql` refreshes Authentik's planner statistics. It
refuses other databases, stops on errors, and bounds lock and statement waits.
It does not change JIT defaults, application resources, or scheduling.

Follow [Authentik's slow-query guidance](https://docs.goauthentik.io/troubleshooting/postgres/slow-queries/):
refresh statistics, measure again, and only disable JIT if compilation still
dominates execution. The PostgreSQL provider used here does not expose a
native database-level JIT configuration resource.
