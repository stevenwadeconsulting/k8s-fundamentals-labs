# Lab 8: Role-Based Access Control (RBAC)

## Introduction

In this lab, you'll explore Role-Based Access Control (RBAC) in Kubernetes, which is a crucial mechanism for securing your cluster.

RBAC allows you to control who can access the Kubernetes API and what actions they can perform. This security model is essential for multi-tenant clusters and environments with strict security requirements.

You'll learn how to create and manage service accounts, roles, and role bindings, and understand how they work together to provide fine-grained access control.

Additionally, you'll see how pods can use service accounts to interact with the Kubernetes API securely.

## Objectives

By the end of this lab, you will be able to:

- Understand the RBAC authorization model in Kubernetes
- Create and manage Service Accounts
- Define Roles and ClusterRoles with specific permissions
- Bind roles to service accounts using RoleBindings and ClusterRoleBindings
- Configure pods to use service accounts
- Test and validate RBAC configurations
- Apply RBAC best practices in your environments

## Prerequisites

- Completion of [Lab 7: Network Policies](7-network-policies.md)
- Basic understanding of Kubernetes resources and the Kubernetes API
- Execute `cd ../008-rbac` to navigate to this lab directory

## Lab Environment Validation

Ensure you're in your assigned namespace:

```bash
# Verify your current namespace
kubectl config view --minify | grep namespace:

# If needed, set your namespace
kubectl config set-context --current --namespace=default

# Create a namespace for RBAC testing
kubectl create namespace rbac-test

# Switch to this namespace
kubectl config set-context --current --namespace=rbac-test
```

## Lab Tasks

### Task 1: Understanding RBAC Components

Before we start creating resources, let's understand the key components of the Kubernetes RBAC system:

1. **Service Accounts**: Identities that pods use to interact with the Kubernetes API
2. **Roles**: Define what actions can be performed on which resources within a namespace
3. **ClusterRoles**: Similar to Roles but apply cluster-wide (across all namespaces)
4. **RoleBindings**: Link a Role to a Subject (user, group, or service account) within a namespace
5. **ClusterRoleBindings**: Link a ClusterRole to a Subject cluster-wide

### Task 2: Creating a Service Account

Let's start by creating a service account:

```bash
# Create a service account
kubectl create serviceaccount app-sa

# Verify the service account was created
kubectl get serviceaccounts

# Examine the service account details
kubectl describe serviceaccount app-sa
```

Every service account automatically gets a secret that contains a token for authenticating with the Kubernetes API. In newer versions of Kubernetes, these tokens are created on demand when mounting the service account to a pod.

### Task 3: Creating a Role with Limited Permissions

Now, let's create a Role that defines what our service account can do:

```bash
# Create a Role that can only read pods and services
kubectl apply -f pod-and-service-reader-role.yaml

# Verify the role was created
kubectl get roles

# Examine the role details
kubectl describe role pod-and-service-reader
```

This Role allows only "get", "watch", and "list" actions on pods and services within the current namespace.

Understanding the components:

- **apiGroups**: The API group containing the resources. The core group is represented by an empty string ""
- **resources**: The resource types this role applies to
- **verbs**: The allowed actions on these resources

Common verbs include:

- get: Retrieve a specific resource
- list: List all resources of a type
- watch: Stream updates to resources
- create: Create a new resource
- update: Modify an existing resource
- patch: Partially modify an existing resource
- delete: Remove a resource

### Task 4: Creating a RoleBinding

Next, we need to bind our Role to the service account:

```bash
# Create a RoleBinding
kubectl apply -f read-pods-and-services-rolebinding.yaml

# Verify the role binding was created
kubectl get rolebindings

# Examine the role binding details
kubectl describe rolebinding read-pods-and-services
```

The RoleBinding links our service account (`app-sa`) to the Role (`pod-and-service-reader`), granting the permissions defined in the Role to the service account.

### Task 5: Creating a Pod with the Service Account

Now let's create a pod that uses our service account:

```bash
# Create a pod that uses our service account
kubectl apply -f rbac-test-pod.yaml

# Wait for the pod to be ready
kubectl wait --for=condition=Ready pod/rbac-test-pod --timeout=60s
```

This pod uses the `app-sa` service account and runs the `kubectl` command-line tool, which we'll use to test our RBAC configuration.

### Task 6: Testing RBAC Permissions

Let's test what our pod can and cannot do:

```bash
# Test listing pods (should work)
kubectl exec -it rbac-test-pod -- kubectl get pods

# Test listing services (should work)
kubectl exec -it rbac-test-pod -- kubectl get services

# Test listing deployments (should fail)
kubectl exec -it rbac-test-pod -- kubectl get deployments

# Test creating a pod (should fail)
kubectl exec -it rbac-test-pod -- kubectl run test --image=nginx
```

You should see that the pod can list pods and services (as allowed by our Role), but cannot list deployments or create pods (as these permissions were not granted).

### Task 7: Updating Role Permissions

Let's update our Role to add more permissions:

```bash
# Update the role to also allow access to deployments
kubectl apply -f pod-and-service-reader-role-v2.yaml

# Verify the updated role
kubectl describe role pod-and-service-reader
```

Let's test the updated permissions:

```bash
# Test listing deployments again (should now work)
kubectl exec -it rbac-test-pod -- kubectl get deployments

# Test creating a deployment (should still fail)
kubectl exec -it rbac-test-pod -- kubectl create deployment test --image=nginx
```

The pod should now be able to list deployments, but still cannot create them since we only added list permissions.

### Task 8: Creating a ClusterRole and ClusterRoleBinding

Sometimes you need permissions that span across all namespaces. Let's create a ClusterRole and ClusterRoleBinding:

```bash
# Create a ClusterRole to read nodes
kubectl apply -f node-reader-clusterrole.yaml

# Create a ClusterRoleBinding for our service account
kubectl apply -f read-nodes-clusterrolebinding.yaml

# Check the ClusterRole and ClusterRoleBinding
kubectl get clusterrole node-reader
kubectl get clusterrolebinding read-nodes
kubectl describe clusterrolebinding read-nodes
```

A ClusterRole and ClusterRoleBinding work similarly to Roles and RoleBindings, but they apply across all namespaces in the cluster.

### Task 9: Testing Cluster-Wide Permissions

Let's test our cluster-wide permissions:

```bash
# Test listing nodes (should work with ClusterRoleBinding)
kubectl exec -it rbac-test-pod -- kubectl get nodes

# Describe a specific node
NODE_NAME=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it rbac-test-pod -- kubectl describe node $NODE_NAME
```

The pod should now be able to list and describe nodes, which is a cluster-wide resource.

### Task 10: Using Aggregated ClusterRoles

Kubernetes provides some built-in ClusterRoles that you can reference in your RoleBindings:

```bash
# List the default ClusterRoles
kubectl get clusterroles | grep -E 'admin|edit|view'
```

These are the most commonly used default ClusterRoles:

- `cluster-admin`: Full access to the entire cluster
- `admin`: Full access within a namespace
- `edit`: Read/write access to most resources within a namespace
- `view`: Read-only access to most resources within a namespace

Let's create a RoleBinding that gives our service account view-only access to most resources:

```bash
# Create a RoleBinding to the view ClusterRole
kubectl apply -f app-sa-view-rolebinding.yaml
```

Let's test this new access:

```bash
# Test various resource types
kubectl exec -it rbac-test-pod -- kubectl get all
kubectl exec -it rbac-test-pod -- kubectl get configmaps
kubectl exec -it rbac-test-pod -- kubectl get events
```

The pod should now be able to view most resources in its namespace.

### Task 11: Inspecting RBAC with kubectl auth

Kubernetes provides the `kubectl auth` command to help you understand and troubleshoot RBAC configurations:

```bash
# Check if a service account can do something
kubectl auth can-i get pods --as=system:serviceaccount:rbac-test:app-sa

# Check if a service account can do something it shouldn't
kubectl auth can-i create deployments --as=system:serviceaccount:rbac-test:app-sa

# Check if a service account can access a specific resource
kubectl auth can-i get pods/nginx-pod --as=system:serviceaccount:rbac-test:app-sa

# Check permissions in a different namespace
kubectl auth can-i get pods --as=system:serviceaccount:rbac-test:app-sa --namespace=default
```

These commands help you verify what actions a service account is allowed to perform without having to actually attempt those actions.

### Task 12: RBAC Troubleshooting

When working with RBAC, you might encounter permission issues. Here's how to troubleshoot them:

1. **Check API Server Logs**: Look for "Forbidden" messages
2. **Use the Kubernetes API**: Try operations directly against the API
3. **Test with kubectl auth**: Use `kubectl auth can-i` to check permissions
4. **Verify RoleBinding Subjects**: Ensure they reference the correct service account
5. **Check for Typos**: Verify resource names, apiGroups, and verbs for typos

Let's create a pod with deliberately incorrect permissions to practice troubleshooting:

```bash
# Create a new service account with no permissions
kubectl create serviceaccount troubleshoot-sa

# Create a pod that uses this service account
kubectl apply -f troubleshoot-pod.yaml

# Wait for the pod to be ready
kubectl wait --for=condition=Ready pod/troubleshoot-pod --timeout=60s

# Try to list pods (should fail)
kubectl exec -it troubleshoot-pod -- kubectl get pods
```

Now let's diagnose and fix the issue:

```bash
# Check what permissions the service account has
kubectl auth can-i get pods --as=system:serviceaccount:rbac-test:troubleshoot-sa

# Create a minimal role and binding
kubectl apply -f pod-reader-rbac.yaml

# Try again to list pods (should now work)
kubectl exec -it troubleshoot-pod -- kubectl get pods
```

### Task 13: Cleanup

Before moving on, let's clean up the resources we created:

```bash
kubectl delete deployment --all
kubectl delete pod --all
kubectl delete role --all
kubectl delete rolebinding --all
kubectl delete clusterrolebinding read-nodes

# Delete the clusterroles
kubectl delete clusterrole node-reader

# Delete the service accounts
kubectl delete serviceaccount app-sa troubleshoot-sa

# Change back to default namespace
kubectl config set-context --current --namespace=default

# Delete the test namespace
kubectl delete namespace rbac-test
```

## Lab Validation

Let's confirm you've mastered the key concepts from this lab:

- You understand the RBAC authorization model in Kubernetes
- You can create and manage Service Accounts
- You know how to define Roles and ClusterRoles with specific permissions
- You can bind roles to service accounts using RoleBindings and ClusterRoleBindings
- You understand how pods use service accounts to interact with the Kubernetes API
- You know how to troubleshoot RBAC issues
- You're familiar with RBAC best practices

## Summary

Congratulations! You have completed Lab 8 of the Kubernetes Fundamentals Workshop. In this lab, you've learned:

1. How the Kubernetes RBAC system works and its key components
2. How to create and manage Service Accounts
3. How to define fine-grained permissions using Roles and ClusterRoles
4. How to bind roles to service accounts using RoleBindings and ClusterRoleBindings
5. How to configure pods to use specific service accounts
6. How to test and validate RBAC configurations
7. Best practices for implementing RBAC in your environments
8. How to troubleshoot RBAC issues

RBAC is a critical security feature in Kubernetes that allows you to control who can access the Kubernetes API and what actions they can perform. Understanding and properly implementing RBAC is essential for securing your Kubernetes clusters in production environments.

## Best Practices

Here are some RBAC best practices to keep in mind:

1. **Follow the Principle of Least Privilege**: Grant only the permissions necessary for a workload to function
2. **Use Namespaces for Isolation**: Separate workloads into different namespaces and use namespace-specific roles
3. **Prefer Roles over ClusterRoles**: Use namespace-scoped Roles when possible
4. **Create Specific, Focused Roles**: Create multiple specific roles rather than one all-encompassing role
5. **Regularly Audit RBAC Resources**: Review and clean up unused RBAC resources
6. **Use Default Roles When Appropriate**: Reuse the default view, edit, and admin roles
7. **Avoid Direct Cluster-Admin Access**: Limit the use of cluster-admin privileges

## Next Steps

Proceed to [Lab 9: Comprehensive Final Exercise](9-complete-app.md) where you'll bring together all the concepts you've learned in this workshop to deploy a complete three-tier application.
