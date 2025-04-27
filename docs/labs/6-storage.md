# Lab 6: Persistent Storage

## Introduction

In this lab, you'll learn how to use persistent storage in Kubernetes. By default, storage in Kubernetes pods is ephemeral—when a pod is restarted or rescheduled, any data written to the container's filesystem is lost. For applications that need to persist data (databases, file servers, etc.), Kubernetes provides persistent storage solutions.

You'll explore Storage Classes, Persistent Volumes (PVs), and Persistent Volume Claims (PVCs), which together form Kubernetes' storage abstraction system. This abstraction allows applications to request and use storage resources without needing to know the specific details of the underlying storage infrastructure.

## Objectives

By the end of this lab, you will be able to:

- Understand the Kubernetes storage architecture
- Explore and use Storage Classes
- Create and manage Persistent Volume Claims
- Use persistent storage with pods and deployments
- Resize volumes when needed
- Implement stateful applications with persistent storage

## Prerequisites

- Completion of [Lab 5: Horizontal Pod Autoscaling](5-autoscaling.md)
- Basic understanding of storage concepts

!!! warning
    Execute `cd ../006-storage` to navigate to this lab directory

## Lab Tasks

### Task 1: Understanding the Kubernetes Storage Architecture

Before we start creating resources, let's understand the key components of Kubernetes storage:

1. **Storage Classes**: Define the types of storage available in the cluster
2. **Persistent Volumes (PVs)**: Represent physical storage resources provisioned in the cluster
3. **Persistent Volume Claims (PVCs)**: Requests for storage resources by applications
4. **Volume Mounts**: How containers access the persistent storage

Let's explore the storage classes available in your cluster:

```bash
# List available storage classes
kubectl get storageclass

# Get details about the default storage class
kubectl describe storageclass do-block-storage
```

In this lab environment, you have several Digital Ocean storage classes available:

- `do-block-storage` (default): Uses ext4 filesystem with Delete reclaim policy
- `do-block-storage-retain`: Uses ext4 filesystem with Retain reclaim policy
- `do-block-storage-xfs`: Uses XFS filesystem with Delete reclaim policy
- `do-block-storage-xfs-retain`: Uses XFS filesystem with Retain reclaim policy

Note these key attributes for each storage class:

- **Provisioner**: The plugin that creates the actual storage
- **ReclaimPolicy**: What happens to the storage when a PVC is deleted (Delete or Retain)
- **VolumeBindingMode**: When the actual storage is provisioned
- **AllowVolumeExpansion**: Whether volumes can be expanded after creation

### Task 2: Creating Your First Persistent Volume Claim

Let's create a simple PVC using the default storage class:

```bash
# Create a basic PVC
kubectl apply -f basic-pvc.yaml

# Check the status of your PVC
kubectl get pvc
```

Notice the PVC's status should be "Bound," indicating that a Persistent Volume (PV) has been automatically provisioned for your claim. Let's examine this PV:

```bash
# List all PVs
kubectl get pv

# Get details about the PV that was created
export PV_NAME=$(kubectl get pvc my-first-pvc -o jsonpath='{.spec.volumeName}')
kubectl describe pv $PV_NAME
```

!!! note
    Key points:

    - The PV was dynamically provisioned by the storage class
    - It has the same size as requested in the PVC
    - The access mode is ReadWriteOnce (RWO), meaning it can be mounted as read-write by a single node
    - It's bound to your specific PVC

### Task 3: Using a PVC with a Pod

Now let's create a pod that uses our PVC:

```bash
# Create a pod that mounts the PVC
kubectl apply -f pvc-demo-pod.yaml

# Verify the pod is running
kubectl get pod pvc-demo-pod
```

Now let's write some data to the persistent volume:

```bash
# Write a file to the persistent volume
kubectl exec -it pvc-demo-pod -- bash -c "echo 'Hello from Kubernetes storage' > /usr/share/nginx/html/index.html"

# Verify the file was created
kubectl exec -it pvc-demo-pod -- cat /usr/share/nginx/html/index.html
```

### Task 4: Testing Persistence Across Pod Restarts

Let's delete the pod and create a new one to verify that our data persists:

```bash
# Delete the pod
kubectl delete pod pvc-demo-pod

# Create a new pod that uses the same PVC
kubectl apply -f pvc-demo-pod-2.yaml

# Wait for the pod to be ready
kubectl wait --for=condition=Ready pod/pvc-demo-pod-2 --timeout=60s

# Check if our data is still there
kubectl exec -it pvc-demo-pod-2 -- cat /usr/share/nginx/html/index.html
```

You should see "Hello from Kubernetes storage" in the output, confirming that our data persisted even when the pod was deleted and recreated.

### Task 5: Using Different Storage Classes

Now, let's explore using different storage classes for specific needs:

```bash
# Create a PVC with XFS file system
kubectl apply -f xfs-pvc.yaml

# Create a PVC with Retain policy
kubectl apply -f retain-pvc.yaml

# Check all PVCs
kubectl get pvc
```

Let's create a pod to verify the file system type:

```bash
# Create a pod to check the XFS file system
kubectl apply -f xfs-demo-pod.yaml

# Wait for the pod to be ready
kubectl wait --for=condition=Ready pod/xfs-demo-pod --timeout=60s

# Check the file system type
kubectl exec -it xfs-demo-pod -- df -T /data
```

You should see that the file system is XFS, as specified by the storage class.

### Task 6: Volume Expansion

One of the advantages of cloud-based storage is the ability to resize volumes. Let's expand one of our PVCs:

```bash
# First check if your storage class supports expansion
kubectl get storageclass do-block-storage -o jsonpath='{.allowVolumeExpansion}'

# Should return "true"

# Resize the PVC
kubectl patch pvc my-first-pvc -p '{"spec":{"resources":{"requests":{"storage":"2Gi"}}}}'

# Check the status of the PVC
kubectl get pvc my-first-pvc
```

The PVC should now show 2Gi for storage. Let's verify the resize in the pod:

```bash
# Create a new pod to access the resized volume
kubectl apply -f resize-check-pod.yaml

# Wait for the pod to be ready
kubectl wait --for=condition=Ready pod/resize-check-pod --timeout=60s

# Check the volume size
kubectl exec -it resize-check-pod -- df -h /data
```

You should see that the volume now has approximately 2GB of space.

### Task 7: Working with StatefulSets

StatefulSets are designed for stateful applications that need stable, persistent storage.

Let's deploy a StatefulSet that uses PVCs:

```bash
# Create a headless service for the StatefulSet
kubectl apply -f nginx-headless-service.yaml

# Create a StatefulSet with persistent storage
kubectl apply -f statefulset.yaml

# Check the created StatefulSet
kubectl get statefulset web

# Check the automatically created PVCs
kubectl get pvc
```

You should see two new PVCs created automatically, one for each StatefulSet replica, with names like `www-web-0` and `www-web-1`.

Let's write unique data to each StatefulSet pod:

```bash
# Write data to the first pod
kubectl exec -it web-0 -- bash -c "echo 'Data from pod 0' > /usr/share/nginx/html/index.html"

# Write data to the second pod
kubectl exec -it web-1 -- bash -c "echo 'Data from pod 1' > /usr/share/nginx/html/index.html"

# Verify the data
kubectl exec -it web-0 -- cat /usr/share/nginx/html/index.html
kubectl exec -it web-1 -- cat /usr/share/nginx/html/index.html
```

Now, let's delete the pods and verify that the data persists:

```bash
# Delete the pods
kubectl delete pod web-0 web-1

# Wait for the pods to be recreated
kubectl get pods
# Wait until both pods are Running again

# Verify the data still exists
kubectl exec -it web-0 -- cat /usr/share/nginx/html/index.html
kubectl exec -it web-1 -- cat /usr/share/nginx/html/index.html
```

The pods should still contain their unique data, demonstrating how StatefulSets provide stable storage for stateful applications.

### Task 8: Understanding StorageClass Reclaim Policies

Let's explore what happens when you delete a PVC with different reclaim policies:

```bash
# First, create a pod using the retain-pvc
kubectl apply -f retain-pod.yaml

# Write some data to the volume
kubectl exec -it retain-pod -- sh -c "echo 'Important data' > /data/important.txt"

# Delete the pod
kubectl delete pod retain-pod

# Now delete the PVC
kubectl delete pvc retain-pvc

# Check the status of PVs
kubectl get pv
```

!!! note
    You should notice that the PV associated with the retain-pvc still exists but in the "Released" state.

    This is because the storage class uses the "Retain" reclaim policy, which preserves the data even after the PVC is deleted.

### Task 9: Cleanup

Before moving on to the next lab, let's clean up the resources we created:

```bash
# Delete all resources created in this lab
kubectl delete statefulset --all
kubectl delete service --all
kubectl delete deployment --all
kubectl delete pod --all
kubectl delete secret mysql-pass
kubectl delete pvc --all
kubectl delete pv --all

# Verify cleanup
kubectl get pvc
kubectl get pods
```

## Lab Validation

Let's confirm you've mastered the key concepts from this lab:

- You understand the Kubernetes storage architecture
- You can create and manage Persistent Volume Claims
- You know how to use persistent storage with pods
- You can resize volumes when needed
- You understand how StatefulSets use persistent storage
- You know the difference between Delete and Retain reclaim policies

## Summary

Congratulations! You have completed Lab 6 of the Kubernetes Fundamentals Workshop. In this lab, you've learned:

1. How the Kubernetes storage system works with Storage Classes, PVs, and PVCs
2. How to create and use Persistent Volume Claims
3. How to ensure data persists across pod restarts and reschedules
4. How to use different storage classes for different needs
5. How to resize volumes when applications need more space
6. How StatefulSets manage persistent storage for stateful applications
7. The difference between Delete and Retain reclaim policies
8. How to deploy a database with persistent storage

These skills are essential for running stateful applications in Kubernetes, ensuring that your critical data remains safe and available even as pods come and go.

## Next Steps

Proceed to [Lab 7: Network Policies](7-network-policies.md) to learn how to secure communication between your pods.
