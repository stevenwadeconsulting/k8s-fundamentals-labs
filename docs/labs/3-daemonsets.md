# Lab 3: DaemonSets

## Introduction

In this lab, you'll explore DaemonSets, a specialized Kubernetes workload resource that ensures that a copy of a Pod runs on every node in the cluster (or a subset of nodes). Unlike Deployments, which are designed to run a specified number of replicas, DaemonSets are node-centric.

DaemonSets are particularly useful for infrastructure-related workloads like monitoring agents, log collectors, and network plugins—cases where you need exactly one instance of a service per node.

## Objectives

By the end of this lab, you will be able to:

- Understand the purpose and use cases for DaemonSets
- Create and manage basic DaemonSets
- Update DaemonSets with rolling updates
- Use node selectors to control DaemonSet scheduling
- Compare the behavior of DaemonSets with Deployments

## Prerequisites

- Completion of Lab 2: Deployments and Rolling Updates
- Understanding of basic Kubernetes concepts

## Lab Environment Validation

Ensure you're in your assigned namespace:

```bash
# Verify your current namespace
kubectl config view --minify | grep namespace:

# If needed, set your namespace
kubectl config set-context --current --namespace=workshop-$USER
```

## Lab Tasks

### Task 1: Understanding DaemonSet Use Cases

Before we dive into creating DaemonSets, let's understand their common use cases:

1. **Node Monitoring**: Running monitoring agents on every node
2. **Log Collection**: Collecting logs from all nodes
3. **Network Plugins**: Ensuring network services run on all nodes
4. **Storage Plugins**: Running storage daemons on eligible nodes

In this lab, we'll simulate a monitoring agent that should run on all nodes.

### Task 2: Creating a Basic DaemonSet

Let's create a DaemonSet that simulates a node monitoring agent:

```bash
# Create a simple DaemonSet
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-monitor
  labels:
    app: node-monitor
spec:
  selector:
    matchLabels:
      app: node-monitor
  template:
    metadata:
      labels:
        app: node-monitor
    spec:
      containers:
      - name: node-monitor
        image: busybox:1.28
        command:
        - /bin/sh
        - -c
        - >
          while true; do
            echo "Monitoring node $(hostname) at $(date)"
            sleep 300
          done
        resources:
          limits:
            memory: "64Mi"
            cpu: "100m"
          requests:
            memory: "32Mi"
            cpu: "50m"
EOF
```

Now, let's verify that the DaemonSet was created and that it deployed pods to all nodes:

```bash
# Check the DaemonSet status
kubectl get daemonsets

# See the pods created by the DaemonSet
kubectl get pods -l app=node-monitor -o wide
```

Notice how there is exactly one pod per node. This is the key characteristic of DaemonSets.

Let's examine the DaemonSet in more detail:

```bash
# Describe the DaemonSet
kubectl describe daemonset node-monitor
```

Pay attention to these sections:
- Desired Number of Nodes Scheduled (should match your node count)
- Current Number of Nodes Scheduled
- Selector (how it identifies which pods belong to it)
- Pod Template (the pod specification)

### Task 3: Examining DaemonSet Behavior

Let's look more closely at how the DaemonSet manages its pods:

```bash
# Check one of the pods created by the DaemonSet
POD_NAME=$(kubectl get pods -l app=node-monitor -o jsonpath='{.items[0].metadata.name}')
kubectl describe pod $POD_NAME
```

Note the "Controlled By" field, which shows that this pod is managed by the DaemonSet.

Let's check the logs to see our monitoring message:

```bash
# Check the logs of one of the DaemonSet pods
kubectl logs $POD_NAME
```

Now, let's try to delete one of the pods and observe what happens:

```bash
# Delete one of the DaemonSet pods
kubectl delete pod $POD_NAME

# Quickly check if a new pod is created
kubectl get pods -l app=node-monitor
```

You'll notice that Kubernetes immediately creates a replacement pod. This is because the DaemonSet controller constantly ensures that a pod matching its specification runs on every node.

### Task 4: Updating a DaemonSet

Like Deployments, DaemonSets support rolling updates. Let's update our DaemonSet:

```bash
# Update the DaemonSet to use a newer image
kubectl set image daemonset/node-monitor node-monitor=busybox:1.29

# Watch the rolling update status
kubectl rollout status daemonset/node-monitor
```

Let's verify the update:

```bash
# Check the DaemonSet status
kubectl get daemonset node-monitor

# Check the image version in a pod
POD_NAME=$(kubectl get pods -l app=node-monitor -o jsonpath='{.items[0].metadata.name}')
kubectl describe pod $POD_NAME | grep Image:
```

You can also view the update history:

```bash
# Check the rollout history
kubectl rollout history daemonset/node-monitor
```

If needed, you can roll back to a previous version:

```bash
# Roll back to the previous version
kubectl rollout undo daemonset/node-monitor

# Verify the rollback
kubectl rollout status daemonset/node-monitor
kubectl describe pod $POD_NAME | grep Image:
```

### Task 5: DaemonSet Scheduling with Node Selectors

Sometimes you may want to run a DaemonSet only on a subset of nodes. Let's modify our DaemonSet to use node selectors:

First, let's identify one of our nodes to target:

```bash
# Get the name of one of your nodes
NODE_NAME=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
echo $NODE_NAME
```

Now, let's update our DaemonSet to only run on this specific node:

```bash
# Update the DaemonSet to use a nodeSelector
kubectl patch daemonset node-monitor --type=json -p='[{"op": "add", "path": "/spec/template/spec/nodeSelector", "value": {"kubernetes.io/hostname": "'$NODE_NAME'"}}]'
```

Let's verify that the DaemonSet now only runs on the selected node:

```bash
# Check where the pods are running
kubectl get pods -l app=node-monitor -o wide
```

You should now see that the DaemonSet pods are only running on the node that matches our selector.

### Task 6: DaemonSets vs. Deployments Comparison

Let's create a Deployment with the same number of replicas as we have nodes to compare the behavior:

```bash
# First, count our nodes
NODE_COUNT=$(kubectl get nodes --no-headers | wc -l)
echo "Node count: $NODE_COUNT"

# Create a Deployment with the same replica count as nodes
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: comparison-deployment
  labels:
    app: comparison
spec:
  replicas: $NODE_COUNT
  selector:
    matchLabels:
      app: comparison
  template:
    metadata:
      labels:
        app: comparison
    spec:
      containers:
      - name: busybox
        image: busybox:1.28
        command:
        - /bin/sh
        - -c
        - "while true; do echo Running on \$(hostname); sleep 300; done"
        resources:
          limits:
            memory: "64Mi"
            cpu: "100m"
          requests:
            memory: "32Mi"
            cpu: "50m"
EOF
```

Now, let's compare where the pods are scheduled:

```bash
# Check where the DaemonSet pods are running
echo "DaemonSet pod locations:"
kubectl get pods -l app=node-monitor -o wide

# Check where the Deployment pods are running
echo "Deployment pod locations:"
kubectl get pods -l app=comparison -o wide
```

Notice the key differences:
1. The DaemonSet ensures exactly one pod per selected node
2. The Deployment distributes pods across nodes based on available resources, which might mean multiple pods on some nodes and none on others

Let's simulate a node failure by cordoning a node (marking it as unschedulable):

```bash
# Cordon the first node (mark as unschedulable)
kubectl cordon $NODE_NAME

# Scale up our deployment by 1
kubectl scale deployment comparison-deployment --replicas=$((NODE_COUNT+1))

# Check where the new pod is scheduled
kubectl get pods -l app=comparison -o wide
```

The new Deployment pod will avoid the cordoned node. But what about our DaemonSet?

```bash
# Uncordon the node
kubectl uncordon $NODE_NAME
```

### Task 7: Creating a Practical DaemonSet

Let's create a more realistic DaemonSet example that simulates a log collector:

```bash
# Create a log collector DaemonSet
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: log-collector
  labels:
    app: log-collector
spec:
  selector:
    matchLabels:
      app: log-collector
  template:
    metadata:
      labels:
        app: log-collector
    spec:
      containers:
      - name: collector
        image: busybox:1.28
        command:
        - /bin/sh
        - -c
        - >
          while true; do
            echo "Collecting logs from node $(hostname) at $(date)"
            # In a real scenario, we'd collect logs here
            sleep 60
          done
        volumeMounts:
        - name: varlog
          mountPath: /var/log
          readOnly: true
        resources:
          limits:
            memory: "100Mi"
            cpu: "100m"
          requests:
            memory: "50Mi"
            cpu: "50m"
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
EOF
```

This DaemonSet simulates a log collector that mounts the host's `/var/log` directory.

Let's verify it's working:

```bash
# Check that the DaemonSet is created
kubectl get daemonset log-collector

# Check the pods
kubectl get pods -l app=log-collector -o wide

# Look at logs from one of the collector pods
POD_NAME=$(kubectl get pods -l app=log-collector -o jsonpath='{.items[0].metadata.name}')
kubectl logs $POD_NAME
```

### Task 8: Cleanup

Before moving to the next lab, let's clean up the resources we created:

```bash
# Delete the DaemonSets
kubectl delete daemonset node-monitor
kubectl delete daemonset log-collector

# Delete the Deployment
kubectl delete deployment comparison-deployment

# Verify cleanup
kubectl get daemonsets
kubectl get deployments
```

## Lab Validation

Let's confirm you've mastered the key concepts from this lab:

- You understand the purpose and use cases for DaemonSets
- You can create and update DaemonSets
- You know how to use node selectors with DaemonSets
- You understand how DaemonSets differ from Deployments
- You've created a practical DaemonSet example

## Summary

Congratulations! You have completed Lab 3 of the Kubernetes Fundamentals Workshop. In this lab, you've learned:

1. When and why to use DaemonSets
2. How to create and manage DaemonSets
3. How to update DaemonSets with rolling updates
4. How to control DaemonSet scheduling with node selectors
5. The key differences between DaemonSets and Deployments

DaemonSets are a powerful tool for running infrastructure-related workloads across your cluster nodes. Understanding when to use them instead of Deployments is an important skill for Kubernetes administrators.

## Next Steps

Proceed to [Lab 4: Services and Networking](4-services.md) to learn how to expose and connect your applications within and outside the cluster.
