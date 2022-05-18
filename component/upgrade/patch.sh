#!/bin/bash
set -e

# Patch CRDS so that ArgoCD does not delete them during upgrade
for crd in $CRDS_TO_PATCH; do
	  exists=$(kubectl get crd "${crd}" --ignore-not-found)
    if [ -z "$exists" ]; then
      >&2 echo "WARNING: Skipping '${crd}': not found."
      continue
    fi
    #Remove ArgoCD managed-by label from the CRD
    kubectl label crd "${crd}" argocd.argoproj.io/instance-
done

# Patch Locks so that the ArgoCD sync does not fail on first try
for lock in $(kubectl get locks -o name); do
    # Annotate locks so that ArgoCD updates locks later then Crossplane
    kubectl annotate "$lock" --overwrite argocd.argoproj.io/sync-wave='10'
done
