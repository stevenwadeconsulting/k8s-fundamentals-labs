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

- Completion of Lab 6: Persistent Storage
- Understanding of basic Kubernetes concepts including namespaces and labels

## Lab Environment Validation

Ensure you're in your assigned namespace:

```bash
# Verify your current namespace
kubectl config view --minify | grep namespace:

# If needed, set your namespace
kubectl config set-context --current --namespace=workshop-$USER
```

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
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: nginx
        ports:
        - containerPort: 80
EOF

# Create a service for the backend
kubectl expose deployment backend --port=80

# Deploy a client app
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: client
spec:
  replicas: 1
  selector:
    matchLabels:
      app: client
  template:
    metadata:
      labels:
        app: client
    spec:
      containers:
      - name: client
        image: busybox
        command: ["/bin/sh", "-c", "while true; do wget -O- --timeout=2 http://backend; sleep 5; done"]
EOF

# Deploy another pod with different labels
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: other
spec:
  replicas: 1
  selector:
    matchLabels:
      app: other
  template:
    metadata:
      labels:
        app: other
    spec:
      containers:
      - name: other
        image: busybox
        command: ["/bin/sh", "-c", "while true; do wget -O- --timeout=2 http://backend; sleep 5; done"]
EOF

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
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
spec:
  podSelector: {}  # Matches all pods in the namespace
  policyTypes:
  - Ingress
EOF

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
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-client-to-backend
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: client
    ports:
    - protocol: TCP
      port: 80
EOF

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
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-default-namespace
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: default
    ports:
    - protocol: TCP
      port: 80
EOF

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
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: restrict-client-egress
spec:
  podSelector:
    matchLabels:
      app: client
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: backend
    ports:
    - protocol: TCP
      port: 80
  # Allow DNS resolution
  - to:
    - namespaceSelector: {}
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
EOF

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

### Task 12: Combining Multiple Policy Rules

Network Policies are additive, meaning if multiple policies select the same pod, all those policies' rules are combined. Let's see this in action:

```bash
# Create another policy for the client pod
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: additional-client-policy
spec:
  podSelector:
    matchLabels:
      app: client
  policyTypes:
  - Egress
  egress:
  - to:
    - ipBlock:
        cidr: 10.0.0.0/8
    ports:
    - protocol: TCP
      port: 443
EOF

# List all network policies
kubectl get networkpolicies
```

Now the client pod has two egress policies that apply to it: one allowing traffic to backend pods and DNS, and another allowing traffic to IPs in the 10.0.0.0/8 range on port 443.

### Task 13: Implementing a Practical Network Policy Set

Let's create a more comprehensive set of network policies for a typical three-tier application:

```bash
# First, remove existing policies
kubectl delete networkpolicy --all

# Create a web tier
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web
      tier: frontend
  template:
    metadata:
      labels:
        app: web
        tier: frontend
    spec:
      containers:
      - name: web
        image: nginx
        ports:
        - containerPort: 80
EOF

# Create an API tier
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api
      tier: backend
  template:
    metadata:
      labels:
        app: api
        tier: backend
    spec:
      containers:
      - name: api
        image: nginx
        ports:
        - containerPort: 80
EOF

# Create a database tier
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: db
spec:
  replicas: 1
  selector:
    matchLabels:
      app: db
      tier: database
  template:
    metadata:
      labels:
        app: db
        tier: database
    spec:
      containers:
      - name: db
        image: mysql:5.7
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: password
        ports:
        - containerPort: 3306
EOF

# Create services for each tier
kubectl expose deployment web --port=80
kubectl expose deployment api --port=80
kubectl expose deployment db --port=3306

# Allow ingress to web tier from anywhere
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: web-allow-external
spec:
  podSelector:
    matchLabels:
      app: web
      tier: frontend
  policyTypes:
  - Ingress
  ingress:
  - {}  # Empty rule allows all ingress traffic
EOF

# Restrict API tier to only allow traffic from web tier
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-allow-web
spec:
  podSelector:
    matchLabels:
      app: api
      tier: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: web
          tier: frontend
    ports:
    - protocol: TCP
      port: 80
EOF

# Restrict database tier to only allow traffic from API tier
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-allow-api
spec:
  podSelector:
    matchLabels:
      app: db
      tier: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: api
          tier: backend
    ports:
    - protocol: TCP
      port: 3306
EOF

# Create a default deny policy for anything not explicitly allowed
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF

# Allow DNS egress for all pods
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns-egress
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector: {}
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
EOF

# List all network policies
kubectl get networkpolicies
```

### Task 14: Testing the Three-Tier Network Policies

Let's verify our network policies are working as expected:

```bash
# Create a test pod
kubectl run test-pod --image=busybox --rm -it -- sh
```

Inside the test pod, run the following commands:

```bash
# Test connectivity to web tier (should succeed)
wget -O- --timeout=2 http://web

# Test connectivity to API tier (should fail)
wget -O- --timeout=2 http://api

# Test connectivity to database tier (should fail)
wget -O- --timeout=2 http://db:3306

# Exit the pod
exit
```

Next, let's create a pod with web tier labels and test from there:

```bash
# Create a test pod with web tier labels
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: web-test-pod
  labels:
    app: web
    tier: frontend
spec:
  containers:
  - name: busybox
    image: busybox
    command: ["sleep", "3600"]
EOF

# Wait for the pod to be ready
kubectl wait --for=condition=ready pod/web-test-pod --timeout=60s

# Exec into the web tier test pod
kubectl exec -it web-test-pod -- sh

# Test connectivity to API tier (should succeed)
wget -O- --timeout=2 http://api

# Test connectivity to database tier (should fail)
wget -O- --timeout=2 http://db:3306

# Exit the pod
exit
```

Finally, let's create a pod with API tier labels and test from there:

```bash
# Create a test pod with API tier labels
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: api-test-pod
  labels:
    app: api
    tier: backend
spec:
  containers:
  - name: busybox
    image: busybox
    command: ["sleep", "3600"]
EOF

# Wait for the pod to be ready
kubectl wait --for=condition=ready pod/api-test-pod --timeout=60s

# Exec into the API tier test pod
kubectl exec -it api-test-pod -- sh

# Test connectivity to database tier (should succeed)
wget -O- --timeout=2 http://db:3306

# Test connectivity to web tier (should fail)
wget -O- --timeout=2 http://web

# Exit the pod
exit
```

### Task 15: Cleanup

Before moving on to the next lab, let's clean up the resources we created:

```bash
# Delete test pods
kubectl delete pod web-test-pod api-test-pod

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
- You understand how multiple policies combine
- You can implement a comprehensive network security strategy for a multi-tier application

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
