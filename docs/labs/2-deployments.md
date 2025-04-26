# Lab 2: Deployments and Rolling Updates

## Introduction

In this lab, you'll learn about one of Kubernetes' most powerful concepts: Deployments. While Pods are the basic building blocks in Kubernetes, Deployments provide declarative updates and sophisticated lifecycle management for your applications.

Deployments manage ReplicaSets, which in turn manage Pods, creating a powerful abstraction that handles scaling, updates, and self-healing for your applications. Understanding how to work with Deployments is essential for running production applications on Kubernetes.

## Objectives

By the end of this lab, you will be able to:

- Create and manage Deployments with multiple replicas
- Perform rolling updates with zero downtime
- Roll back to previous versions when needed
- Scale applications up and down
- Use ConfigMaps and Secrets with Deployments
- Understand the relationship between Deployments, ReplicaSets, and Pods

## Prerequisites

- Completion of [Lab 1: Initial Kubernetes Exploration](1-essentials.md)
- Understanding of basic Kubernetes concepts (Pods, namespaces)
- Basic YAML knowledge
- Execute `cd ../002-deployments` to navigate to this lab directory

## Lab Tasks

### Task 1: Creating Your First Deployment

Let's start by creating a simple Deployment with multiple replicas:

```bash
# Create a deployment with 3 replicas
kubectl apply -f deployment.yaml
```

Now let's examine what was created:

```bash
# Check the deployment status
kubectl get deployments

# List the pods created by the deployment
kubectl get pods -l app=nginx

# Check the ReplicaSet created by the deployment
kubectl get replicasets
```

Take note of how the Deployment created a ReplicaSet, which in turn created three Pods. This hierarchy forms the foundation of the Deployment's capabilities.

Let's examine the deployment in more detail:

```bash
# Describe the deployment
kubectl describe deployment nginx-deployment
```

Note the key sections in the deployment description:
- Replicas status (current/desired)
- Update strategy
- Pod template
- Events

### Task 2: Performing a Rolling Update

One of the key features of Deployments is the ability to update your application with zero downtime:

```bash
# Update the deployment to use a newer image version
kubectl set image deployment/nginx-deployment nginx=nginx:1.21

# Watch the rolling update in progress
kubectl rollout status deployment/nginx-deployment
```

Let's see what happened behind the scenes:

```bash
# List the ReplicaSets
kubectl get replicasets

# Notice there are two ReplicaSets now - the original and the new one
```

You should see two ReplicaSets - the original one (scaled to 0 replicas) and the new one (with 3 replicas).

Examine the rollout history:

```bash
# View rollout history
kubectl rollout history deployment/nginx-deployment

# Get details about a specific revision
kubectl rollout history deployment/nginx-deployment --revision=2
```

### Task 3: Scaling a Deployment

Scaling applications is straightforward with Deployments:

```bash
# Scale up to 5 replicas
kubectl scale deployment nginx-deployment --replicas=5

# Verify the scaling operation
kubectl get pods -l app=nginx -o wide
```

Notice how the pods are distributed across your nodes for high availability.

Now let's scale down:

```bash
# Scale down to 2 replicas
kubectl scale deployment nginx-deployment --replicas=2

# Verify the scaling operation
kubectl get pods -l app=nginx
```

Kubernetes determined which pods to terminate while maintaining application availability.

### Task 4: Rolling Back a Deployment

Sometimes updates contain bugs. Let's simulate a problematic update and then roll back:

```bash
# Update to a non-existent image (simulating a bad deployment)
kubectl set image deployment/nginx-deployment nginx=nginx:nonexistent

# Check the status
kubectl rollout status deployment/nginx-deployment
```

This command will hang as Kubernetes tries to pull the non-existent image.

In another terminal, examine what's happening:

```bash
# Check the deployment status
kubectl get deployment nginx-deployment

# Look at the pods
kubectl get pods -l app=nginx

# Describe one of the pods with ImagePullBackOff status
POD_NAME=$(kubectl get pods -l app=nginx -o jsonpath='{.items[?(@.status.phase=="Pending")].metadata.name}' | head -1)
kubectl describe pod $POD_NAME
```

Now let's roll back to the working version:

```bash
# Roll back to the previous version
kubectl rollout undo deployment/nginx-deployment

# Verify the rollback
kubectl rollout status deployment/nginx-deployment

# Check the deployment
kubectl get deployment nginx-deployment

# Check the pods
kubectl get pods -l app=nginx
```

You can also roll back to a specific revision:

```bash
# Roll back to revision 1 (the original version)
kubectl rollout undo deployment/nginx-deployment --to-revision=1

# Verify the image version
kubectl describe deployment nginx-deployment | grep Image:

# Notice the image version is back to nginx:1.20
```

### Task 5: Working with ConfigMaps and Secrets

In real applications, you often need to inject configuration and sensitive data. Let's see how to use ConfigMaps and Secrets with Deployments:

First, create a ConfigMap:

```bash
# Create a ConfigMap
kubectl apply -f configmap.yaml

# Verify the ConfigMap
kubectl get configmap app-config -o yaml
```

Next, create a Secret:

```bash
# Create a Secret
kubectl create secret generic app-secrets \
  --from-literal=db-password=mySuperSecretPassword \
  --from-literal=api-key=ab12cd34ef56

# Verify the Secret (note the values are base64 encoded)
kubectl get secret app-secrets -o yaml
```

Now, create a new Deployment that uses both the ConfigMap and Secret:

```bash
kubectl apply -f webserver-deployment.yaml
```

Let's verify our configuration is working:

```bash
# Get one of the webserver pods
POD_NAME=$(kubectl get pods -l app=webserver -o jsonpath="{.items[0].metadata.name}")

# Check that the ConfigMap content was mounted properly
kubectl exec -it $POD_NAME -- cat /usr/share/nginx/html/index.html

# Check that the environment variables were set
kubectl exec -it $POD_NAME -- env | grep DB_PASSWORD
kubectl exec -it $POD_NAME -- env | grep API_KEY
kubectl exec -it $POD_NAME -- env | grep ENVIRONMENT
```

### Task 6: Understanding Deployment Strategies

Let's examine different deployment strategies. First, let's update our deployment to use the RollingUpdate strategy with specific parameters:

```bash
# Update the deployment with explicit RollingUpdate parameters
kubectl patch deployment nginx-deployment -p '{"spec":{"strategy":{"rollingUpdate":{"maxSurge":1,"maxUnavailable":0}}}}'

# Verify the update
kubectl get deployment nginx-deployment -o yaml | grep -A5 strategy
```

Now let's perform another update and observe how it respects our strategy parameters:

```bash
# Update the image again
kubectl set image deployment/nginx-deployment nginx=nginx:1.22

# Watch the rollout with our new parameters
kubectl rollout status deployment/nginx-deployment
```

Note how Kubernetes respects the maxSurge and maxUnavailable parameters during the update.

### Task 7: Cleanup

Before moving to the next lab, let's clean up the resources we created:

```bash
# Delete the deployments
kubectl delete deployment --all

# Delete the ConfigMap and Secret
kubectl delete configmap app-config
kubectl delete secret app-secrets

# Verify resources are gone
kubectl get deployments
kubectl get configmaps
kubectl get secrets
```

## Lab Validation

Let's confirm you've mastered the key concepts from this lab:

- You can create Deployments with specific requirements
- You understand how rolling updates work
- You can scale applications up and down
- You know how to roll back to a previous version when needed
- You can use ConfigMaps and Secrets with your Deployments
- You understand different update strategies

## Summary

Congratulations! You have completed Lab 2 of the Kubernetes Fundamentals Workshop. In this lab, you've learned:

1. How to create and manage Deployments
2. How to perform rolling updates with zero downtime
3. How to scale applications up and down
4. How to roll back to previous versions
5. How to use ConfigMaps and Secrets with your Deployments
6. How to configure deployment strategies

Deployments are the foundation of running reliable applications in Kubernetes, and the knowledge you've gained in this lab will be essential as you continue your Kubernetes journey.

## Next Steps

Proceed to [Lab 3: DaemonSets](3-daemonsets.md) to learn about another important workload resource in Kubernetes.
