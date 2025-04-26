# Lab 4: Services and Networking

## Introduction

In this lab, you'll learn about Kubernetes Services, which provide stable networking for your applications. While Pods can come and go (they're ephemeral), Services provide a consistent way to access your applications regardless of which Pods are running or where they're located in the cluster.

Kubernetes Services are essential for reliable microservice architectures, enabling seamless communication between application components and providing access to your applications from outside the cluster.

## Objectives

By the end of this lab, you will be able to:

- Understand different Service types (ClusterIP, NodePort, LoadBalancer)
- Create Services to expose applications within the cluster
- Configure Services for access from outside the cluster
- Implement service-to-service communication patterns
- Understand and use DNS-based service discovery
- Master label selectors for effective service targeting

## Prerequisites

- Completion of [Lab 3: DaemonSets](3-daemonsets.md)
- Understanding of Pods and Deployments
- Execute `cd ../004-services` to navigate to this lab directory

## Lab Tasks

### Task 1: Understanding Service Types

Kubernetes provides several Service types, each serving different networking needs:

1. **ClusterIP**: Default type; exposes the Service on an internal IP accessible only within the cluster
2. **NodePort**: Exposes the Service on each Node's IP at a static port
3. **LoadBalancer**: Exposes the Service externally using a cloud provider's load balancer
4. **ExternalName**: Maps the Service to a DNS name (not covered in this lab)

Let's begin by creating a sample application to use throughout this lab.

### Task 2: Deploying a Backend Application

First, let's create a backend deployment that we'll expose with various Service types:

```bash
# Create a backend deployment
kubectl apply -f backend-deployment.yaml

# Verify the deployment is running
kubectl get deployment backend
kubectl get pods -l app=backend
```

### Task 3: Creating a ClusterIP Service

The ClusterIP Service type is the default and provides internal access to your application:

```bash
# Create a ClusterIP service for the backend
kubectl apply -f backend-service.yaml

# Examine the service
kubectl get service backend-service
kubectl describe service backend-service
```

Note the following in the service description:

- **Type:** ClusterIP (the default)
- **ClusterIP:** The virtual IP assigned to this service
- **Selector:** How the service knows which pods to send traffic to
- **Endpoints:** The actual pod IPs that are receiving traffic

Let's test the service from within the cluster:

```bash
# Create a temporary pod to test the service
kubectl run test-client --image=busybox:1.28 -- sleep 3600
kubectl exec -it test-client -- wget -qO- backend-service
```

You should see "Hello from the backend service" in the output, confirming the service works.

Now, let's explore the service endpoints:

```bash
# Check service endpoints
kubectl get endpoints backend-service

# Compare with pod IPs
kubectl get pods -l app=backend -o wide
```

The endpoints match the IPs of the pods that match the service's selector.

### Task 4: Creating a LoadBalancer Service

LoadBalancer services expose your application externally using your cloud provider's load balancer. Since we're using Digital Ocean, which supports LoadBalancer services, let's create one:

```bash
# Create a LoadBalancer service
kubectl apply -f backend-loadbalancer-service.yaml
```

Note these key details:

- **Type:** LoadBalancer
- **External IP:** The IP address assigned by Digital Ocean
- **Port:** The port your service is exposed on (80)
- **TargetPort:** The container port (5678)

After applying this service, Digital Ocean will provision a load balancer and assign it an external IP address. It may take a minute or two for the external IP to be assigned:

```bash
# Check the service until an external IP is assigned
kubectl get service backend-loadbalancer --watch
```

Press Ctrl+C to exit the watch mode once the external IP appears.

You can access your service using:
```
http://<external-ip>
```

The LoadBalancer service type provides an easier and more robust way to expose your applications to the internet compared to NodePort, as it:

- Creates an actual load balancer in your cloud provider
- Provides a stable external IP
- Handles traffic distribution automatically
- Doesn't require knowing node IPs or specific ports

### Task 5: DNS-Based Service Discovery

Kubernetes provides DNS-based service discovery through CoreDNS. Let's explore how this works:

```bash
# Create a test pod with a shell
kubectl run dns-test --image=busybox:1.28 --rm -it -- sh
```

Inside the pod, run the following commands:

```bash
# Inside the pod, look up service DNS names
nslookup backend-service
nslookup frontend-service

# Try the fully qualified domain name
nslookup backend-service.default.svc.cluster.local

# Test connectivity using the DNS name
wget -qO- backend-service

# Exit the pod
exit
```

Key points about Kubernetes DNS:

- Services get DNS entries in the format: `<service-name>.<namespace>.svc.cluster.local`
- Within the same namespace, you can use just the service name
- The DNS resolves to the service's ClusterIP

### Task 6: Service Load Balancing

Let's examine how services distribute traffic across pods:

```bash
# Scale up the backend service to better demonstrate load balancing
kubectl scale deployment backend --replicas=3

# Wait for the new pods to be ready
kubectl get pods -l app=backend

# Create a test pod that repeatedly calls the service
kubectl run load-test --image=busybox:1.28 -- /bin/sh -c 'while true; do wget -qO- backend-service; sleep 1; done'

# Check the logs to see responses from different pods
kubectl logs -f load-test
```

You should see responses coming from different backend pods, demonstrating that the service is load-balancing requests. Press Ctrl+C to stop following the logs.

### Task 7: Using Labels and Selectors with Services

Services use label selectors to determine which pods to send traffic to. Let's explore this more deeply:

```bash
# Create a deployment with multiple labels
kubectl apply -f multi-label-deployment.yaml

# Create a service that selects on multiple labels
kubectl apply -f multi-label-service.yaml

# Test the service
kubectl exec -it test-client -- wget -qO- multi-label-service
```

Now, let's deploy a v2 version and see how we can target specific versions:

```bash
# Create a v2 deployment
kubectl apply -f multi-label-deployment-v2.yaml

# Create a service that targets only v2
kubectl apply -f multi-label-service-v2.yaml

# Test both services
kubectl exec -it test-client -- wget -qO- multi-label-service
kubectl exec -it test-client -- wget -qO- multi-label-service-v2
```

Notice how the first service (without the version selector) sends traffic to all pods matching app=multi-label and tier=backend (both v1 and v2), while the second service only sends traffic to v2 pods.

### Task 8: Headless Services

Sometimes you need direct access to specific pods rather than load-balanced access. Headless services provide this capability:

```bash
# Create a headless service (with clusterIP: None)
kubectl apply -f backend-headless-service.yaml

# Examine the service
kubectl get service backend-headless
kubectl describe service backend-headless
```

Notice that the service has no cluster IP. Let's see how DNS works with a headless service:

```bash
# Create a test pod
kubectl run dns-test --image=busybox:1.28 --rm -it -- sh
```

Inside the pod, run:

```bash
# Look up the headless service
nslookup backend-headless

# You should see individual A records for each pod
exit
```

Unlike a regular service, DNS for a headless service:

- Returns the IP addresses of all the individual pods, not a single service IP.

### Task 9: Cleanup

Before moving on to the next lab, let's clean up the resources we created:

```bash
# Delete all resources created in this lab
kubectl delete pod --all
kubectl delete service --all
kubectl delete deployment --all

# Verify cleanup
kubectl get services
kubectl get deployments
```

## Lab Validation

Let's confirm you've mastered the key concepts from this lab:

- You understand different service types and when to use each
- You can create services to expose applications internally and externally
- You understand how services use label selectors to target pods
- You know how DNS-based service discovery works in Kubernetes
- You can implement service-to-service communication patterns
- You understand the load-balancing behaviour of services

## Summary

Congratulations! You have completed Lab 4 of the Kubernetes Fundamentals Workshop. In this lab, you've learned:

1. How to create different types of Services (ClusterIP, NodePort)
2. How to expose applications within and outside the cluster
3. How service-to-service communication works
4. The role of DNS in service discovery
5. How services use labels and selectors to target pods
6. How to create headless services for direct pod access

Services are a fundamental building block of Kubernetes networking, providing stable endpoints that enable reliable communication between application components and users.

## Next Steps

Proceed to [Lab 5: Horizontal Pod Autoscaling](5-autoscaling.md) to learn how to automatically scale your applications based on resource usage.
