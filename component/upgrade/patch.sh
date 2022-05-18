#!/bin/bash
set -e

#Patch CRDS so that ArgoCD does not delete them during upgrade
for crd in $CRDS_TO_PATCH; do
	  exists=$(kubectl get crd "${crd}" --ignore-not-found)
    if [ -z "$exists" ]; then
      >&2 echo "WARNING: Skipping '${crd}': not found."
      continue
    fi
    #Remove ArgoCD managed-by label from the CRD
    kubectl label crd "${crd}" argocd.argoproj.io/instance-
done

#Patch Locks so that ArgoCD does not delete them during upgrade
for lock in $(kubectl get locks -o name); do
    #Remove ArgoCD managed-by label from the Lock
    kubectl label "$lock" argocd.argoproj.io/instance-
done
