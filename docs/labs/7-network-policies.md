# Lab 7: Network Policies

## Introduction

In this lab, you'll explore Kubernetes Network Policies, which provide the ability to control network traffic flow between pods, namespaces, and external endpoints.

By default, all pods in a Kubernetes cluster can communicate with any other pod and reach out to any available endpoint. Network Policies act as firewalls, allowing you to enforce rules about which connections are allowed.

Understanding Network Policies is crucial for implementing security best practices in your Kubernetes clusters.

They allow you to implement the principle of least privilege at the network level, ensuring that pods can only communicate with the specific services they need to function.

## Objectives

By the end of this lab, you will be able to:

- Understand the concept and purpose of Network Policies
- Create and apply basic Network Policies
- Implement ingress and egress traffic controls
- Use label selectors and namespaces in Network Policies
- Test and validate policy effectiveness

## Prerequisites

- Completion of [Lab 6: Persistent Storage](6-storage.md)
- Understanding of basic Kubernetes concepts including namespaces and labels
- Execute `cd ../007-network-policies` to navigate to this lab directory

## Lab Tasks

### Task 1: Understanding Network Policies

Before diving into hands-on examples, let's understand the key components of Network Policies:

1. **Pod Selector**: Defines which pods the policy applies to
2. **Ingress Rules**: Control incoming traffic to the selected pods
3. **Egress Rules**: Control outgoing traffic from the selected pods
4. **From/To Rules**: Specify sources/destinations allowed to communicate with the selected pods

Network Policies are namespace-scoped resources, meaning they only apply to pods within the namespace they're created in.

### Task 2: Creating a Test Environment

Let's set up a test environment with multiple applications to demonstrate Network Policies:

```bash
# Create a namespace for this exercise
kubectl create namespace netpol-test

# Use this namespace for subsequent commands
kubectl config set-context --current --namespace=netpol-test

# Deploy a backend service
kubectl apply -f backend-deployment.yaml

# Create a service for the backend
kubectl expose deployment backend --port=80

# Deploy a client app
kubectl apply -f client-deployment.yaml

# Deploy another pod with different labels
kubectl apply -f other-deployment.yaml

# Wait for pods to be ready
kubectl wait --for=condition=ready pod --selector=app=backend --timeout=90s
kubectl wait --for=condition=ready pod --selector=app=client --timeout=90s
kubectl wait --for=condition=ready pod --selector=app=other --timeout=90s
```

### Task 3: Verifying Connectivity Before Network Policies

Before applying any Network Policies, let's verify that all pods can communicate with each other:

```bash
# Get the client pod name
CLIENT_POD=$(kubectl get pod -l app=client -o jsonpath='{.items[0].metadata.name}')

# Check logs to confirm the client can access the backend
kubectl logs --tail=10 $CLIENT_POD

# Get the other pod name
OTHER_POD=$(kubectl get pod -l app=other -o jsonpath='{.items[0].metadata.name}')

# Check logs to confirm the other pod can access the backend
kubectl logs --tail=10 $OTHER_POD

# Test connectivity from another namespace
kubectl run test-from-default --image=busybox --rm -it --restart=Never -n default -- wget -O- --timeout=2 http://backend.netpol-test
```

You should see that all pods can access the backend service without restrictions.

### Task 4: Creating a Default Deny Policy

A security best practice is to start with a default deny policy and then explicitly allow required traffic. Let's implement this:

```bash
# Create a Network Policy that denies all ingress traffic
kubectl apply -f default-deny-ingress.yaml

# Verify the Network Policy was created
kubectl get networkpolicies
```

This policy selects all pods in the namespace (empty pod selector means "match all") and denies all incoming traffic to them.

### Task 5: Testing the Default Deny Policy

Now let's verify that the traffic is blocked:

```bash
# Wait a moment for the policy to take effect
sleep 5

# Check client logs (should show connection failures)
kubectl logs --tail=5 $CLIENT_POD

# Check other pod logs (should also show connection failures)
kubectl logs --tail=5 $OTHER_POD

# Test from another namespace (should fail)
kubectl run test-from-default --image=busybox --rm -it --restart=Never -n default -- wget -O- --timeout=2 http://backend.netpol-test
```

You should now see connection timeouts in the logs, indicating that the Network Policy is blocking traffic.

### Task 6: Allowing Specific Traffic

Now let's allow traffic from the client pod to the backend:

```bash
# Create a Network Policy that allows traffic from client pods to backend pods
kubectl apply -f allow-client-to-backend.yaml

# Verify the new Network Policy
kubectl get networkpolicies
```

This policy selects pods with the label `app: backend` and allows incoming TCP traffic on port 80 from pods with the label `app: client`.

### Task 7: Testing the Specific Allow Policy

Let's test our configuration:

```bash
# Wait a moment for the policy to take effect
sleep 5

# Check client logs (should now show successful connections)
kubectl logs --tail=5 $CLIENT_POD

# Check other pod logs (should still show connection failures)
kubectl logs --tail=5 $OTHER_POD

# Test from another namespace (should still fail)
kubectl run test-from-default --image=busybox --rm -it --restart=Never -n default -- wget -O- --timeout=2 http://backend.netpol-test
```

You should see that:

- The client pod can now access the backend (successful connections)
- The "other" pod still cannot access the backend (connection failures)
- Pods from other namespaces still cannot access the backend

### Task 8: Allowing Traffic from Other Namespaces

Now, let's allow traffic from the default namespace:

```bash
# Create a Network Policy that allows traffic from the default namespace
kubectl apply -f allow-from-default-namespace.yaml

# Label the default namespace to match our selector
kubectl label namespace default kubernetes.io/metadata.name=default --overwrite

# Verify the new Network Policy
kubectl get networkpolicies
```

This policy allows traffic to backend pods from any pod in the namespace labeled `kubernetes.io/metadata.name: default`.

### Task 9: Testing Cross-Namespace Policy

Let's verify that the cross-namespace policy works:

```bash
# Wait a moment for the policy to take effect
sleep 5

# Test connectivity from the default namespace (should now succeed)
kubectl run test-from-default --image=busybox --rm -it --restart=Never -n default -- wget -O- --timeout=2 http://backend.netpol-test
```

The test pod in the default namespace should now be able to connect to the backend service.

### Task 10: Creating an Egress Policy

So far, we've focused on ingress policies (controlling incoming traffic). Now let's create an egress policy to control outgoing traffic:

```bash
# Create a Network Policy that restricts outgoing traffic
kubectl apply -f restrict-client-egress.yaml

# Verify the egress policy
kubectl get networkpolicies
```

This policy restricts the client pods to only communicate with backend pods on port 80 and the DNS service on port 53.

### Task 11: Testing the Egress Policy

Let's verify that the client pod can still reach the backend but can't communicate with other destinations:

```bash
# Get the client pod name
CLIENT_POD=$(kubectl get pod -l app=client -o jsonpath='{.items[0].metadata.name}')

# Exec into the client pod
kubectl exec -it $CLIENT_POD -- sh

# Inside the pod, test connectivity to the backend
wget -O- --timeout=2 http://backend

# Test connectivity to an external site (should fail)
wget -O- --timeout=2 https://kubernetes.io

# Exit the pod
exit
```

You should observe that the client pod can connect to the backend but cannot reach external sites.

### Task 12: Cleanup

Before moving on to the next lab, let's clean up the resources we created:

!!! warning
    This will take some time to complete, as it will delete all resources in the `netpol-test` namespace.


```bash
# Delete test pods
kubectl delete pod --all -n netpol-test

# Return to default namespace
kubectl config set-context --current --namespace=default

# Delete the test namespace (removes all resources in it)
kubectl delete namespace netpol-test

# Remove label from default namespace
kubectl label namespace default kubernetes.io/metadata.name-
```

## Lab Validation

Let's confirm you've mastered the key concepts from this lab:

- You understand the purpose and components of Network Policies
- You can create and apply basic ingress and egress policies
- You know how to use label selectors to target specific pods
- You can implement namespace-based policies

## Summary

Congratulations! You have completed Lab 7 of the Kubernetes Fundamentals Workshop. In this lab, you've learned:

1. How Network Policies control traffic flow between pods
2. How to create ingress policies to restrict incoming traffic
3. How to create egress policies to restrict outgoing traffic
4. How to use label and namespace selectors in policies
5. How multiple policies combine to create a comprehensive security posture
6. Best practices for implementing network security in Kubernetes

Network Policies are an essential tool for implementing the principle of least privilege in your Kubernetes clusters, ensuring that pods can only communicate with the specific services they need to function.

## Next Steps

Proceed to [Lab 8: RBAC and Security](8-rbac.md) to learn about Role-Based Access Control and other security features in Kubernetes.
