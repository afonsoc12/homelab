---
name: longhorn-pvc-reattach
description: Rebind an existing Longhorn PersistentVolume (with real data) to a new PVC/app, instead of letting the app create a fresh empty volume. Trigger when moving an app between namespaces/releases (e.g. sandbox -> homelab) and its old PVC/data must carry over, when a PV is stuck `Released` and needs to become `Available` again, or when a pod fails to start with `Multi-Attach error for volume ... already exclusively attached`.
---

# Reattaching a Longhorn PV to a New PVC

Use this when an app is redeployed under a new release/namespace (e.g. migrating a
manually-installed `helm` release into GitOps) and the new PVC would otherwise bind to
a brand-new empty Longhorn volume, orphaning the old one with the real data.

Reclaim policy must be `Retain` (check with `kubectl get pv <pv> -o jsonpath='{.spec.persistentVolumeReclaimPolicy}'`).
If it's `Delete`, the old PV is gone as soon as its PVC is deleted — this dance won't help; you'd need to restore from a Longhorn/Kopia backup instead.

## 1. Identify the old PV

```bash
kubectl get pv | grep <app-name>
```

Look for one `Released` (its old PVC was deleted) or still `Bound` to the release you're retiring — note its name (`pvc-<uuid>`).

## 2. Pause ArgoCD self-heal on the app *and* its parent

ArgoCD's `selfHeal` will revert a manual `kubectl scale --replicas=0` within seconds. Worse,
if the app is templated by a root app-of-apps (`argocd-apps`), the root's own selfHeal
re-applies the child `Application`'s spec (including `syncPolicy`) from git, undoing a
per-app pause. You must pause **both**:

```bash
kubectl patch application <app> -n addons --type=merge -p '{"spec":{"syncPolicy":{"automated":null}}}'
kubectl patch application argocd-apps -n addons --type=merge -p '{"spec":{"syncPolicy":{"automated":null}}}'
```

This is a shared-cluster mutation (affects self-heal cluster-wide, briefly) — confirm with
the user before doing it, and always restore it in step 6 even if something fails.

## 3. Scale down and confirm the pod is gone

```bash
kubectl scale deploy -n <namespace> <app> --replicas=0
# poll until this returns 0
kubectl get pods -n <namespace> -l app.kubernetes.io/instance=<app> --no-headers | wc -l
```

Don't proceed until the pod count is actually 0 — a still-terminating pod holds the volume
attachment and the new PVC will fail with `Multi-Attach error`.

## 4. Delete the new (empty) PVC, free the old PV's claim

```bash
kubectl delete pvc -n <namespace> <pvc-name>
kubectl patch pv <old-pv> --type=merge -p '{"spec":{"claimRef":null}}'
kubectl get pv <old-pv> -o jsonpath='{.status.phase}'   # should print "Available"
```

## 5. Pre-bind the PV to the exact future claim

Don't hand-set `volumeName` on a manually-applied PVC — that field is immutable once bound,
and ArgoCD's git-templated PVC (which never specifies `volumeName`) will permanently show
`OutOfSync` and repeatedly fail to sync trying to patch it back to empty.

Instead, reserve the PV for the specific claim ArgoCD is about to create, by setting
`claimRef` on the **PV** side to the target namespace/name:

```bash
kubectl patch pv <old-pv> --type=merge -p '{"spec":{"claimRef":{"namespace":"<namespace>","name":"<pvc-name>"}}}'
kubectl get pv <old-pv> -o jsonpath='{.status.phase} {.spec.claimRef.namespace}/{.spec.claimRef.name}'
# -> "Available <namespace>/<pvc-name>"
```

The PV stays `Available` (reserved, not yet bound) until a PVC with that exact
namespace/name shows up — at which point Kubernetes binds them automatically, with no
`volumeName` ever written to the PVC spec.

## 6. Restore ArgoCD sync policy and trigger a sync

```bash
kubectl patch application <app> -n addons --type=merge -p '{"spec":{"syncPolicy":{"automated":{"prune":true,"selfHeal":true}}}}'
kubectl patch application argocd-apps -n addons --type=merge -p '{"spec":{"syncPolicy":{"automated":{"prune":true,"selfHeal":true}}}}'
```

Missing-resource creation isn't always picked up instantly by self-heal (unlike drift on an
*existing* resource) — if the PVC doesn't reappear within a few seconds, force a sync of just
the app (not the root) via the Application's `operation` field, which works even without an
authenticated `argocd` CLI session:

```bash
kubectl patch application <app> -n addons --type=merge -p '{"operation":{"sync":{"syncStrategy":{"hook":{}}}}}'
kubectl get application <app> -n addons -o jsonpath='{.status.operationState.phase}'   # watch for Succeeded
```

Then confirm the PVC bound cleanly to the old volume, with the app fully `Synced` (not just `Healthy`):

```bash
kubectl get pvc -n <namespace> <pvc-name>                  # STATUS Bound, VOLUME = <old-pv>
kubectl get application <app> -n addons -o jsonpath='{.status.sync.status} {.status.health.status}'
# -> "Synced Healthy" — if it says "OutOfSync Healthy", the PVC likely still has a stray
#    manually-set volumeName; redo step 4-5 without setting it by hand.
```

Deployment replicas don't need manual scale-up — once the PVC is `Bound`, ArgoCD's own
reconcile brings the pod back (its desired replica count was never actually changed in
git, only observed live during the pause).

## Gotchas

- If step 2 is skipped, expect an infinite fight: ArgoCD recreates the replica, it binds
  the new empty PVC, and your delete/patch race against it.
- Always restore sync policy in step 6 even on failure — don't leave apps un-self-healing.
- Never hand-set `volumeName` on the PVC you apply — pre-bind via the PV's `claimRef`
  instead (step 5), so the live PVC stays byte-for-byte what ArgoCD would template and
  the app reports clean `Synced` status, not a permanent `OutOfSync`.
