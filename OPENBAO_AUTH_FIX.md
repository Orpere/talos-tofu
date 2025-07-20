# OpenBao External Secrets Authentication Fix

## Problem
The External Secrets Operator was unable to authenticate with OpenBao using Kubernetes authentication, receiving a 403 "permission denied" error.

## Root Cause
The OpenBao Kubernetes auth configuration was using a service account token that lacked the necessary RBAC permissions to validate tokens from other namespaces (specifically the `external-secrets` namespace).

## Solution Implemented
Added a dedicated `openbao-token-reviewer` service account with proper RBAC permissions to the `openbao-auth-setup.yaml` file:

### New Components Added:
1. **ServiceAccount**: `openbao-token-reviewer` in the `openbao` namespace
2. **ClusterRole**: With permissions for `tokenreviews` and `subjectaccessreviews`
3. **ClusterRoleBinding**: Binds the service account to the cluster role
4. **Secret**: Service account token for the token reviewer

### Modified Components:
- Updated the `get_kubernetes_info()` function in the auth setup job to use the token reviewer JWT instead of the current pod's service account token
- Added fallback logic for backward compatibility

## Required RBAC Permissions
The token reviewer service account needs:
- `authentication.k8s.io/tokenreviews` (create) - To validate service account tokens
- `authorization.k8s.io/subjectaccessreviews` (create) - To perform authorization checks

## Verification
- ✅ OpenBao Kubernetes auth configured successfully
- ✅ External Secrets Operator authenticates without errors
- ✅ SecretStore shows as `Valid` and `Ready`
- ✅ External secrets can be synced from OpenBao

## Files Modified
- `apps/manifests/overlays/openbao-auth-setup.yaml` - Added token reviewer resources and updated auth setup logic

This fix ensures that OpenBao has the proper permissions to validate service account tokens from any namespace, enabling seamless integration with the External Secrets Operator.
