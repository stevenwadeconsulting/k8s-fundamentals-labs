# Kubernetes Fundamentals Workshop

Welcome to the Kubernetes Fundamentals Workshop! This hands-on workshop will guide you through the essential parts and concepts of Kubernetes, from fundamental architecture to production-ready implementations.

## Workshop Overview

This workshop provides a comprehensive introduction to Kubernetes - the industry-standard platform for container orchestration.
Through a series of hands-on labs, you'll gain practical experience working with the key parts of Kubernetes and learn how to deploy, manage, and scale applications in a cloud-native environment.

### What You'll Learn

- Kubernetes architecture and core components
- Deploying and managing applications with Deployments
- Networking and service discovery fundamentals
- Working with persistent storage solutions
- Implementing auto-scaling configurations
- Securing your applications with RBAC and Network Policies
- Real-world best practices for production environments

## Prerequisites

- Basic familiarity with containers and containerisation concepts
- Comfort using command-line interfaces
- Basic understanding of YAML syntax
- All other necessary resources will be provided during the workshop

## Lab Environment

Each participant will have access to a pre-configured two-node Kubernetes cluster running in Digital Ocean. The environment comes with all necessary tools installed, including:

- kubectl CLI
- A fully functioning Kubernetes cluster
- Access to required images and resources
- This lab guide and associated YAML files

## Getting Started

1. Log in to your assigned workshop environment using the credentials provided
2. Verify your access to the Kubernetes cluster with:
   ```bash
   kubectl cluster-info
   kubectl get nodes
   ```
3. Clone this repository to access lab files:
   ```bash
   git clone https://github.com/stevenwadeconsulting/k8s-fundamentals-labs.git
   cd k8s-fundamentals-labs
   cd examples
   ```

## Workshop Labs

The workshop consists of eight hands-on labs, each focusing on different aspects of Kubernetes:

1. **[Initial Kubernetes Exploration](labs/1-essentials.md)**
    - Connecting to your cluster
    - Essential kubectl commands
    - Understanding namespaces
    - Working with your first Pod

2. **[Deployments and Rolling Updates](labs/2-deployments.md)**
    - Creating basic Deployments
    - Performing rolling updates
    - Working with ConfigMaps and Secrets
    - Scaling and rollback procedures

3. **[DaemonSets](labs/3-daemonsets.md)**
    - DaemonSet use cases
    - Creating and managing DaemonSets
    - Understanding DaemonSet scheduling

4. **[Services and Networking](labs/4-services.md)**
    - Service types and usages
    - Service-to-service communication
    - DNS-based service discovery
    - Exposing applications to external traffic

5. **[Horizontal Pod Autoscaling](labs/5-autoscaling.md)**
    - Resource requests and limits
    - Creating Horizontal Pod Autoscalers
    - Testing scaling behavior
    - Advanced configuration options

6. **[Persistent Storage](labs/6-storage.md)**
    - Storage Classes
    - Persistent Volumes and Claims
    - Stateful applications with persistent storage
    - Volume resize operations

7. **[Network Policies](labs/7-networkpolicies.md)**
    - Securing pod-to-pod communication
    - Implementing default deny policies
    - Allowing specific traffic patterns
    - Testing and validating policies

8. **[RBAC and Security](labs/8-rbac.md)**
    - Service Accounts and permissions
    - Creating Roles and RoleBindings
    - Testing RBAC enforcement
    - Security best practices

9. **[Comprehensive Final Exercise](labs/9-complete-app.md)**
    - Deploying a complete three-tier application
    - Combining all workshop concepts
    - Real-world deployment patterns

## Workshop Flow

Each lab includes four key sections:

1. **Objective**: What you'll learn in the lab
2. **Tasks**: Step-by-step instructions with explanations
3. **Validation**: How to verify your work
4. **Clean-up**: Instructions to reset your environment after each exercise

**Important**: Please follow the clean-up instructions at the end of each lab to ensure your cluster resources remain available for later exercises.

## Additional Resources

- [Kubernetes Official Documentation](https://kubernetes.io/docs/home/){target="_blank"}
- [Kubernetes Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/){target="_blank"}
- [CNCF Cloud Native Interactive Landscape](https://landscape.cncf.io/){target="_blank"}

## Troubleshooting

If you encounter any issues during the labs:

1. Check the pod status and logs:
   ```bash
   kubectl get pods
   kubectl describe pod <pod-name>
   kubectl logs <pod-name>
   ```

2. Verify your YAML syntax:
   ```bash
   kubectl apply --validate=true --dry-run=client -f your-file.yaml
   ```

3. Ask for assistance from the workshop instructor

## Feedback

Your feedback is valuable! At the end of the workshop, please take a few minutes to share your thoughts by completing our [feedback form](https://forms.gle/HxoVhSZRNk49BweS9){target="_blank"}.

Your input helps us improve future workshops and develop new content based on your needs and interests.

## License

This workshop material is available under the [MIT License](LICENSE).
