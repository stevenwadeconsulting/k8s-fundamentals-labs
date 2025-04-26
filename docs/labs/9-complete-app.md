# Lab 9: Comprehensive Final Exercise

## Introduction

This final lab brings together all the concepts you've learned throughout the workshop into a single, comprehensive exercise. You'll deploy a complete three-tier application architecture with a frontend, backend API, and database—implementing best practices for configuration, security, networking, storage, and scaling.

This real-world scenario will help solidify your understanding of how various Kubernetes components work together to create a resilient, secure, and scalable application. By the end of this exercise, you'll have hands-on experience with applying Kubernetes in a production-like environment.

## Objectives

By the end of this lab, you will be able to:

- Deploy a complete three-tier application on Kubernetes
- Apply best practices for configuration management using ConfigMaps and Secrets
- Implement secure networking with appropriate Service types and Network Policies
- Configure persistent storage for stateful components
- Set up automated scaling based on demand
- Secure applications using RBAC and service accounts
- Understand how all Kubernetes components work together in a real-world scenario

## Prerequisites

- Completion of all previous labs in the workshop
- Understanding of all core Kubernetes concepts

## Lab Environment Validation

Let's create a dedicated namespace for our final exercise:

```bash
# Create a namespace for our complete application
kubectl create namespace final-app

# Use this namespace for subsequent commands
kubectl config set-context --current --namespace=final-app
```

## Lab Tasks

### Task 1: Planning Our Application Architecture

Before diving into implementation, let's understand the architecture we'll be deploying:

1. **Frontend Tier**: Web interface for users
   - NGINX serving static content
   - Exposed to external traffic
   - Connects to the backend API

2. **Backend API Tier**: Business logic layer
   - Simple API service
   - Internal only (not directly exposed)
   - Connects to the database

3. **Database Tier**: Data storage layer
   - MySQL database
   - Internal only
   - Requires persistent storage

Let's start by creating our configuration resources.

### Task 2: Creating Configuration Resources

First, let's create ConfigMaps and Secrets to manage our application's configuration:

```bash
# Create a ConfigMap for application configuration
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  app.properties: |
    title=Kubernetes Workshop Demo
    color=blue
    message=Hello from ConfigMap!
  nginx.conf: |
    server {
      listen 80;
      location / {
        root /usr/share/nginx/html;
        index index.html;
      }
      location /api {
        proxy_pass http://backend-service;
      }
    }
EOF

# Create a Secret for sensitive data
kubectl create secret generic app-secrets \
  --from-literal=api-key=QWxhZGRpbjpvcGVuIHNlc2FtZQ== \
  --from-literal=db-password=VGhpcyBpcyB0aGUgc2VjcmV0IQ==

# Verify our configuration resources
kubectl get configmaps,secrets
```

### Task 3: Setting Up Storage Resources

Our database will need persistent storage:

```bash
# Create a PVC for database storage
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-data
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: do-block-storage-xfs-retain
  resources:
    requests:
      storage: 1Gi
EOF

# Verify the PVC is created
kubectl get pvc
```

### Task 4: Creating Service Accounts and RBAC

Let's set up proper RBAC permissions:

```bash
# Create a ServiceAccount
kubectl create serviceaccount app-sa

# Create a Role with limited permissions
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: app-role
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps", "secrets"]
  verbs: ["get", "list", "watch"]
EOF

# Create a RoleBinding for the ServiceAccount
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-rolebinding
subjects:
- kind: ServiceAccount
  name: app-sa
  namespace: final-app
roleRef:
  kind: Role
  name: app-role
  apiGroup: rbac.authorization.k8s.io
EOF

# Verify RBAC resources
kubectl get serviceaccounts,roles,rolebindings
```

### Task 5: Deploying the Database Tier

Now let's deploy our MySQL database:

```bash
# Create the MySQL Deployment with persistent storage
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
spec:
  selector:
    matchLabels:
      app: mysql
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: mysql
    spec:
      serviceAccountName: app-sa
      containers:
      - name: mysql
        image: mysql:5.7
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: db-password
        - name: MYSQL_DATABASE
          value: appdb
        ports:
        - containerPort: 3306
          name: mysql
        volumeMounts:
        - name: mysql-storage
          mountPath: /var/lib/mysql
        resources:
          limits:
            memory: "512Mi"
            cpu: "500m"
          requests:
            memory: "256Mi"
            cpu: "200m"
        livenessProbe:
          tcpSocket:
            port: 3306
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          tcpSocket:
            port: 3306
          initialDelaySeconds: 5
          periodSeconds: 10
      volumes:
      - name: mysql-storage
        persistentVolumeClaim:
          claimName: mysql-data
EOF

# Create a headless service for MySQL
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: mysql
spec:
  ports:
  - port: 3306
  selector:
    app: mysql
  clusterIP: None
EOF

# Verify database deployment
kubectl get pods,services -l app=mysql
```

### Task 6: Deploying the Backend API Tier

Next, let's deploy our backend API service:

```bash
# Deploy the backend API
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      serviceAccountName: app-sa
      containers:
      - name: api
        image: hashicorp/http-echo:latest
        args:
        - "-text=API Response: Connected to database at \${DB_HOST}, API Key: \${API_KEY}"
        ports:
        - containerPort: 5678
        env:
        - name: DB_HOST
          value: mysql
        - name: API_KEY
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: api-key
        resources:
          limits:
            memory: "256Mi"
            cpu: "300m"
          requests:
            memory: "128Mi"
            cpu: "150m"
        readinessProbe:
          httpGet:
            path: /
            port: 5678
          initialDelaySeconds: 5
          periodSeconds: 10
EOF

# Create a service for the backend (ClusterIP - internal only)
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  selector:
    app: backend
  ports:
  - port: 80
    targetPort: 5678
EOF

# Verify backend deployment
kubectl get pods,services -l app=backend
```

### Task 7: Implementing Horizontal Pod Autoscaling for Backend

Let's set up autoscaling for our backend tier:

```bash
# Create an HPA for the backend
cat <<EOF | kubectl apply -f -
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: backend-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: backend
  minReplicas: 2
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
EOF

# Verify the HPA
kubectl get hpa
```

### Task 8: Deploying the Frontend Tier

Now, let's deploy our frontend:

```bash
# Create frontend content ConfigMap
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: frontend-content
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head>
      <title>Kubernetes Workshop Complete App</title>
      <style>
        body {
          background-color: #3498db;
          color: white;
          font-family: Arial, sans-serif;
          text-align: center;
          padding-top: 100px;
        }
        .container {
          max-width: 800px;
          margin: 0 auto;
          padding: 20px;
          background-color: rgba(0,0,0,0.3);
          border-radius: 10px;
        }
        button {
          background-color: #2ecc71;
          color: white;
          border: none;
          padding: 10px 20px;
          border-radius: 5px;
          cursor: pointer;
          font-size: 16px;
          margin-top: 20px;
        }
        #result {
          margin-top: 20px;
          padding: 10px;
          background-color: rgba(0,0,0,0.2);
          border-radius: 5px;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>Kubernetes Workshop Complete App</h1>
        <p>This application demonstrates concepts from this workshop:</p>
        <ul style="text-align: left; display: inline-block;">
          <li>Multi-tier architecture with frontend, backend, and database</li>
          <li>ConfigMaps and Secrets for configuration</li>
          <li>Persistent storage with PVCs</li>
          <li>Service networking between components</li>
          <li>RBAC with ServiceAccounts</li>
          <li>Horizontal Pod Autoscaling</li>
        </ul>
        <button onclick="callApi()">Call Backend API</button>
        <div id="result"></div>
      </div>
      <script>
        function callApi() {
          document.getElementById('result').innerHTML = 'Loading...';
          fetch('/api')
            .then(response => response.text())
            .then(data => {
              document.getElementById('result').innerHTML = data;
            })
            .catch(error => {
              document.getElementById('result').innerHTML = 'Error: ' + error;
            });
        }
      </script>
    </body>
    </html>
EOF

# Deploy the frontend
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      serviceAccountName: app-sa
      containers:
      - name: nginx
        image: nginx:1.21
        ports:
        - containerPort: 80
        volumeMounts:
        - name: nginx-config
          mountPath: /etc/nginx/conf.d/default.conf
          subPath: nginx.conf
        - name: content
          mountPath: /usr/share/nginx/html/index.html
          subPath: index.html
        resources:
          limits:
            memory: "128Mi"
            cpu: "200m"
          requests:
            memory: "64Mi"
            cpu: "100m"
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 10
      volumes:
      - name: nginx-config
        configMap:
          name: app-config
          items:
          - key: nginx.conf
            path: nginx.conf
      - name: content
        configMap:
          name: frontend-content
          items:
          - key: index.html
            path: index.html
EOF

# Create a NodePort service for the frontend
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
  type: NodePort
EOF

# Verify frontend deployment
kubectl get pods,services -l app=frontend
```

### Task 9: Implementing Network Policies

Let's secure our application with Network Policies:

```bash
# Create a policy to restrict database access
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: mysql-policy
spec:
  podSelector:
    matchLabels:
      app: mysql
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: backend
    ports:
    - protocol: TCP
      port: 3306
EOF

# Create a policy for backend access
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-policy
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
          app: frontend
    ports:
    - protocol: TCP
      port: 5678
EOF

# Create a policy allowing all ingress to frontend
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-policy
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
  - Ingress
  ingress:
  - {}  # Allow all ingress to frontend
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

# Verify Network Policies
kubectl get networkpolicies
```

### Task 10: Testing the Complete Application

Now let's verify that our complete application is functioning:

```bash
# Get the NodePort service details
kubectl get service frontend-service

# For local minikube, get the node IP
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}')
NODE_PORT=30080

echo "You can access the application at: http://$NODE_IP:$NODE_PORT"

# Check all resources
kubectl get all

# Check pods in each tier
kubectl get pods -l app=frontend
kubectl get pods -l app=backend
kubectl get pods -l app=mysql
```

For a cloud-based workshop environment, your instructor will provide the appropriate IP address or hostname to access the application.

### Task 11: Troubleshooting and Verification

Let's verify that our application tiers can communicate with each other properly:

```bash
# Get a frontend pod
FRONTEND_POD=$(kubectl get pod -l app=frontend -o jsonpath='{.items[0].metadata.name}')

# Test connectivity to backend service
kubectl exec -it $FRONTEND_POD -- curl backend-service

# Get a backend pod
BACKEND_POD=$(kubectl get pod -l app=backend -o jsonpath='{.items[0].metadata.name}')

# Check environment variables
kubectl exec -it $BACKEND_POD -- env | grep DB_HOST
kubectl exec -it $BACKEND_POD -- env | grep API_KEY

# Verify MySQL is running
kubectl get pods -l app=mysql
MYSQL_POD=$(kubectl get pod -l app=mysql -o jsonpath='{.items[0].metadata.name}')
kubectl logs $MYSQL_POD
```

### Task 12: Experimenting with Autoscaling

Let's test the autoscaling functionality:

```bash
# Create a load generator to test autoscaling
kubectl run load-generator --image=busybox -- /bin/sh -c "while true; do wget -q -O- http://backend-service; done"

# Monitor the HPA and pods
kubectl get hpa backend-hpa --watch

# In a separate terminal, monitor the backend pods
kubectl get pods -l app=backend --watch
```

After observing the scaling behavior, stop the load test:

```bash
# Delete the load generator
kubectl delete pod load-generator
```

### Task 13: Practicing Disaster Recovery

Let's practice some disaster recovery scenarios:

```bash
# Simulate a pod failure by deleting a backend pod
BACKEND_POD=$(kubectl get pod -l app=backend -o jsonpath='{.items[0].metadata.name}')
kubectl delete pod $BACKEND_POD

# Watch the Deployment recreate the pod
kubectl get pods -l app=backend --watch

# Simulate a database failure
MYSQL_POD=$(kubectl get pod -l app=mysql -o jsonpath='{.items[0].metadata.name}')
kubectl delete pod $MYSQL_POD

# Watch the database pod being recreated
kubectl get pods -l app=mysql --watch

# Verify data persistence
kubectl exec -it $(kubectl get pod -l app=mysql -o jsonpath='{.items[0].metadata.name}') -- mysql -u root -p$MYSQL_ROOT_PASSWORD -e "SHOW DATABASES;"
```

### Task 14: Cleanup

After completing all exercises, clean up the resources:

```bash
# Delete all resources in the namespace
kubectl delete all --all

# Delete the ConfigMaps and Secrets
kubectl delete configmap app-config frontend-content
kubectl delete secret app-secrets

# Delete Network Policies
kubectl delete networkpolicy --all

# Delete PVCs
kubectl delete pvc mysql-data

# Delete RBAC resources
kubectl delete serviceaccount app-sa
kubectl delete role app-role
kubectl delete rolebinding app-rolebinding

# Delete HPA
kubectl delete hpa backend-hpa

# Change back to default namespace
kubectl config set-context --current --namespace=default

# Delete the namespace
kubectl delete namespace final-app
```

## Lab Validation

Let's confirm you've mastered the key concepts from this comprehensive exercise:

- You can design and deploy a multi-tier application in Kubernetes
- You understand how to use ConfigMaps and Secrets for configuration management
- You can implement NetworkPolicies for secure service communication
- You know how to use persistent storage for stateful applications
- You can set up Horizontal Pod Autoscalers for automated scaling
- You understand how to apply RBAC for securing application permissions
- You can diagnose and troubleshoot multi-tier applications in Kubernetes

## Summary

Congratulations! You have completed the final lab of the Kubernetes Fundamentals Workshop. In this comprehensive exercise, you've applied all the concepts learned throughout the workshop to deploy a complete three-tier application with:

1. Proper configuration management using ConfigMaps and Secrets
2. Secure networking with appropriate service types
3. Network isolation using NetworkPolicies
4. Persistent storage for the database tier
5. Horizontal scaling for the backend tier
6. RBAC security with ServiceAccounts
7. Readiness and liveness probes for reliability
8. Resource requests and limits for proper scheduling

This exercise demonstrates how the various Kubernetes components work together to create a resilient, secure, and scalable application architecture. The skills you've practiced in this workshop provide a solid foundation for designing and deploying real-world applications on Kubernetes.

## Next Steps

Now that you've completed the Kubernetes Fundamentals Workshop, consider these next steps for continuing your Kubernetes journey:

1. **Explore Advanced Topics**:
   - Kubernetes Operators and Custom Resources
   - GitOps and CI/CD for Kubernetes
   - Service Mesh technologies (like Istio or Linkerd)
   - Advanced observability and monitoring

2. **Certifications**:
   - Certified Kubernetes Administrator (CKA)
   - Certified Kubernetes Application Developer (CKAD)
   - Certified Kubernetes Security Specialist (CKS)

3. **Practice and Build**:
   - Deploy your own applications on Kubernetes
   - Contribute to open-source Kubernetes projects
   - Set up a personal Kubernetes lab environment

## Your Feedback Matters!

Please take a moment to complete our workshop feedback form. Your insights are invaluable in helping us improve future workshops and develop content that best serves your learning needs.

Finally, thank you for participating in this workshop!
