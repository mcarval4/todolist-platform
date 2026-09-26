# TodoList Platform

This repository provisions the capabilities on which TodoList runs. The local stack is an adapter
for the technical challenge; it can be replaced by a managed Kubernetes stack without changing the
GitOps repository or the application image flow.

## Boundaries

- `stacks/local-kind/cluster` creates only the local kind cluster.
- `stacks/local-kind/platform` installs Cilium, Argo CD, Kyverno, CloudNativePG and monitoring.
- `bootstrap` seeds Argo CD with the Application maintained by `mcarval4/todolist-gitops`.

Application workloads, database resources and application secrets are not managed by Terraform.
Before the first Argo CD synchronization, create local-only secrets with:

```bash
../todolist-gitops/scripts/create-local-secrets.sh
```

## Local Commands

```bash
make cluster-up
make platform-up
make bootstrap
make destroy
```
