# Lab 5: Horizontal Pod Autoscaling

## Introduction

In this lab, you'll explore Horizontal Pod Autoscaling (HPA), a Kubernetes feature that automatically scales the number of pod replicas based on observed metrics such as CPU utilisation. Autoscaling is essential for applications with variable workloads, allowing your infrastructure to adapt to changing demands automatically.

The HPA controller periodically adjusts the number of replicas in a Deployment, ReplicaSet, or StatefulSet to match the observed metrics with the target values you specify. This helps ensure your applications remain responsive under load while optimising resource usage during periods of low activity.

## Objectives

By the end of this lab, you will be able to:

- Configure resource requests and limits for containers
- Create Horizontal Pod Autoscalers based on CPU metrics
- Test autoscaling behavior under load
- Configure advanced HPA settings
- Understand autoscaling best practices

## Prerequisites

- Completion of [Lab 4: Services and Networking](4-services.md)
- Understanding of Deployments and resource management concepts

!!! warning
    Execute `cd ../005-autoscaling` to navigate to this lab directory

## Lab Tasks

### Task 1: Understanding Resource Requests and Limits

Before we can effectively use HPAs, we need to understand resource requests and limits, which are fundamental to Kubernetes resource management:

- **Resource Requests**: The minimum amount of resources that the container needs
- **Resource Limits**: The maximum amount of resources that the container can use

Let's create a deployment with specific resource requests and limits:

```bash
# Create a deployment with resource requests and limits
kubectl apply -f resource-deployment.yaml

# Check the deployment
kubectl get deployment resource-demo

# Examine the pod to see the resource settings
kubectl describe pod -l app=resource-demo | grep -A3 Limits -B2
```

!!! info
    Key points about resources:

    - CPU requests are specified in "millicores" (m). 100m = 0.1 CPU core
    - Memory requests are specified in bytes, or with suffixes like Mi (mebibyte) or Gi (gibibytes)
    - Resource requests are used for scheduling decisions
    - Resource limits are enforced by the container runtime

### Task 2: Creating a Sample Application for Autoscaling

Let's create an application that we can use to test autoscaling. We'll use the `php-apache` image which includes a basic PHP application that we can load test:

```bash
# Create a deployment with defined CPU resource requests
kubectl apply -f php-apache-deployment.yaml

# Create a service for the deployment
kubectl expose deployment php-apache --port=80

# Verify the deployment and service
kubectl get deployment php-apache
kubectl get service php-apache
```

The container image (`registry.k8s.io/hpa-example`) runs a simple PHP application that performs CPU-intensive calculations when accessed.

### Task 3: Creating a Horizontal Pod Autoscaler

Now let's create an HPA that will automatically scale our deployment based on CPU utilisation:

```bash
# First we need to install the metrics server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Create an HPA targeting 50% CPU utilization
kubectl autoscale deployment php-apache --cpu-percent=50 --min=1 --max=3

# Check the HPA status
kubectl get hpa
```

Let's examine what we created:

```bash
# Describe the HPA
kubectl describe hpa php-apache
```

!!! info
    Key points about the HPA:

    - Target: The deployment we're scaling (php-apache)
    - Min and Max Replicas: The scaling boundaries (1-3 pods)
    - Target CPU Utilisation: 50% of the requested CPU
    - Current CPU Utilisation: The current average across all pods
    - Current Replicas: The current number of pods

### Task 4: Testing the Autoscaler

Now let's generate load to test our autoscaler. We'll run a container that sends an infinite loop of queries to our php-apache service:

```bash
# Start a load generator
kubectl run memory-hog --image=busybox -- /bin/sh -c 'while true; do for i in $(seq 1 30); do wget -q -O- "http://php-apache" > /dev/null & done; sleep 0.1; done'
```

In a separate terminal, monitor the HPA status:

```bash
# Watch the HPA
kubectl get hpa php-apache --watch
```

You should see the reported CPU load increase and eventually the number of replicas will increase to handle the load. The HPA will increase the number of replicas gradually based on its scaling algorithm.

After several minutes, stop the load generator by pressing Ctrl+C in its terminal window. Then observe how the HPA scales down the deployment as the load decreases.

To better understand what's happening, let's look at all the components together:

```bash
# Watch the pods, HPA, and deployment together
kubectl get pods -l run=php-apache -o wide
kubectl get hpa php-apache
kubectl describe deployment php-apache
```

### Task 5: Understanding HPA Scaling Behavior

Let's examine how the HPA makes scaling decisions:

```bash
# Get detailed information about the HPA
kubectl describe hpa php-apache
```

Look at the "Events" section, which shows the scaling decisions that the HPA has made, including any scale-up or scale-down actions.

!!! note
    The HPA controller follows these general rules:

    1. It checks metrics at a regular interval (default: 15 seconds)
    2. It calculates the desired number of replicas based on current/target metric values
    3. It applies a stabilisation window to prevent "thrashing" (rapid scaling up and down)
    4. It respects minimum and maximum replica constraints

### Task 6: Creating an Advanced HPA (v2)

Let's create a more advanced HPA configuration using the `autoscaling/v2` API version:

```bash
# First delete our existing HPA
kubectl delete hpa php-apache

# Create an advanced HPA with scale-down stabilization
kubectl apply -f php-apache-hpa-v2.yaml

# Check the new HPA
kubectl get hpa
kubectl describe hpa php-apache-v2
```

!!! note
    Key features of this advanced HPA:

    - Uses the newer v2 API which supports multiple metrics
    - Configures scaling behaviour for both scale-up and scale-down events
    - Scales down slowly (10% every 60 seconds, with a 300-second stabilization window)
    - Scales up quickly (either doubles the pod count or adds 4 pods every 15 seconds, whichever is higher)

Let's test this new HPA by generating load again:

```bash
# Start a load generator
kubectl run -i --tty load-generator --rm --image=busybox:1.28 --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://php-apache; done"
```

In a separate terminal, monitor the HPA status:

```bash
# Watch the HPA and pods
kubectl get hpa php-apache-v2 --watch
kubectl get pods -l run=php-apache
```

After a few minutes, stop the load generator (Ctrl+C) and observe the scale-down behaviour, which should be more gradual than before.

### Task 7: Cleanup

Before moving on to the next lab, let's clean up the resources we created:

```bash
# Delete all resources created in this lab
kubectl delete hpa --all
kubectl delete deployment --all
kubectl delete service --all

# Verify cleanup
kubectl get hpa
kubectl get deployments
kubectl get services
```

## Lab Validation

Let's confirm you've mastered the key concepts from this lab:

- You understand how to configure resource requests and limits
- You can create and configure Horizontal Pod Autoscalers
- You know how to test and verify autoscaling behaviour
- You can create advanced HPAs with custom scaling behaviours
- You understand autoscaling best practices

## Summary

Congratulations! You have completed Lab 5 of the Kubernetes Fundamentals Workshop. In this lab, you've learned:

1. How to configure resource requests and limits for containers
2. How to create basic and advanced Horizontal Pod Autoscalers
3. How to test autoscaling behaviour under load

Horizontal Pod Autoscaling is a powerful feature that allows your applications to respond automatically to changing workloads, ensuring both performance and efficient resource utilisation.

## Next Steps

Proceed to [Lab 6: Persistent Storage](6-storage.md) to learn how to work with persistent data in Kubernetes.
