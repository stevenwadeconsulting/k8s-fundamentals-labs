# Lab 1: Initial Kubernetes Exploration

## Introduction

Welcome to your first hands-on lab with Kubernetes! In this lab, you'll establish a solid foundation by learning essential `kubectl` commands, exploring your cluster, and creating your first Kubernetes resources.

A deep understanding of these fundamentals is critical before moving on to more complex Kubernetes concepts. This lab will give you the tools to navigate, inspect, and interact with any Kubernetes cluster.

## Objectives

By the end of this lab, you will be able to:

- Connect to and explore your Kubernetes cluster
- Use essential `kubectl` commands for resource management
- Understand and work with Kubernetes namespaces
- Create and interact with your first Pod
- Master different output formats for effective troubleshooting

## Prerequisites

- Access to your assigned Kubernetes cluster
- Basic familiarity with command-line interfaces
- Execute `cd 001-essentials` to navigate to this lab directory

## Lab Environment Validation

Let's first ensure you have access to your cluster:

```bash
# Display cluster connection information
kubectl cluster-info

# Verify kubectl can communicate with your cluster
kubectl get nodes
```

You should see information about your Kubernetes control plane and a list of the nodes in your cluster. If you encounter any errors, please ask for assistance before proceeding.

## Lab Tasks

### Task 1: Exploring Your Kubernetes Cluster

Let's start by examining the cluster components:

```bash
# Get detailed information about cluster nodes
kubectl get nodes -o wide

# Examine one specific node in detail
NODE_NAME=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
kubectl describe node $NODE_NAME
```

Take a moment to review the output. Note the:

- CPU and memory resources
- Node conditions
- System info
- Allocated resources

Next, let's look at the system pods that keep Kubernetes running:

```bash
# List all pods in the kube-system namespace
kubectl get pods -n kube-system

# Get more details about these system pods
kubectl get pods -n kube-system -o wide
```

These pods run components like:

- CoreDNS (cluster DNS)
- kube-proxy (network routing)
- Cloud-specific components

### Task 2: Understanding and Working with Namespaces

Namespaces provide a mechanism for isolating groups of resources within a cluster:

```bash
# List all namespaces in the cluster
kubectl get namespaces

# Get more information about a specific namespace
kubectl describe namespace default
```

### Task 3: API Resource Types

Kubernetes has many types of resources. Let's explore them:

```bash
# Get a list of all supported resource types
kubectl api-resources

# Count the total number of resource types
kubectl api-resources | wc -l

# Look for specific resource types
kubectl api-resources | grep -E 'deployment|pod|service'
```

To learn more about a specific resource type:

```bash
# Get documentation about pods
kubectl explain pod

# Get documentation about a specific field
kubectl explain pod.spec.containers

# Get documentation with recursive details
kubectl explain pod --recursive | less
```

Use `Ctrl+C` to exit if needed.

### Task 4: Creating Your First Pod

Now that you're familiar with the environment, let's create your first Pod:

```bash
# Create a simple nginx pod
kubectl apply -f nginx-pod.yaml
```

Verify the pod is running:

```bash
# Check if the pod is running
kubectl get pods

# Get more detailed information
kubectl describe pod nginx-pod
```

Review the important sections in the pod description:
- Container statuses
- Events at the bottom (useful for troubleshooting)
- Assigned IP address

### Task 5: Interacting with Your Pod

Let's view the logs from the pod:

```bash
# View the logs
kubectl logs nginx-pod
```

Now, let's execute commands inside the container:

```bash
# Get a shell in the container
kubectl exec -it nginx-pod -- /bin/bash

# Inside the container, check that nginx is running
curl localhost
exit
```

### Task 6: Working with Output Formats

Kubernetes supports various output formats, which are useful for different scenarios:

```bash
# Get basic pod information
kubectl get pod nginx-pod

# Output in YAML format
kubectl get pod nginx-pod -o yaml

# Output in JSON format
kubectl get pod nginx-pod -o json

# Get specific fields using jsonpath
kubectl get pod nginx-pod -o jsonpath='{.status.podIP}'

# Create a custom columns display
kubectl get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,IP:.status.podIP

# Sort output
kubectl get pods --sort-by=.metadata.creationTimestamp
```

Let's try a few more advanced queries:

```bash
# Get the container image used by your pod
kubectl get pod nginx-pod -o jsonpath='{.spec.containers[0].image}'

# Get the node where your pod is running
kubectl get pod nginx-pod -o jsonpath='{.spec.nodeName}'
```

### Task 7: Cleanup

Before moving on to the next lab, clean up your resources:

```bash
# Delete the pod you created
kubectl delete pod nginx-pod

# Verify the pod is gone
kubectl get pods
```

## Lab Validation
Let's confirm you've mastered the key concepts from this lab:

- You can successfully connect to and explore the Kubernetes cluster
- You understand how to navigate namespaces
- You can create a pod and examine its status
- You can interact with a running pod
- You know how to use different output formats for various needs
- You can successfully clean up resources

## Summary
Congratulations! You have completed the first lab of the Kubernetes Fundamentals Workshop. In this lab, you've learned:

- How to explore and interact with your Kubernetes cluster
- How to work with namespaces for resource isolation
- How to create and manage your first Kubernetes Pod
- Multiple ways to interact with and debug running workloads
- How to use various output formats for different needs

These fundamental skills will serve as building blocks for the more advanced concepts we'll cover in the upcoming labs.

## Next Steps
Proceed to [Lab 2: Deployments and Rolling Updates](2-deployments.md) to learn how to manage application deployments at scale.
