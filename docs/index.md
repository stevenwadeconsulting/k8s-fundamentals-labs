# 🚢 Kubernetes Fundamentals Workshop

Welcome to the Kubernetes Fundamentals Workshop! This hands-on workshop will guide you through the essential parts and concepts of Kubernetes, from fundamental architecture to production-ready implementations.

<div style="padding: 15px; margin: 20px 0; background-color: #e1f5fe; border-left: 5px solid #03a9f4; border-radius: 4px;">
<h3 style="margin-top: 0; color: #0277bd;">👨‍🏫 Meet Your Instructor</h3>
<p>This workshop is led by an industry veteran with nearly a decade of hands-on Kubernetes experience, former Flux maintainer, and founder of the Cloud Native Club.</p>
<p><a href="about-instructor">Learn more about your instructor →</a></p>
</div>

## 🔍 Workshop Overview

This workshop provides a comprehensive introduction to Kubernetes - the industry-standard platform for container orchestration.
Through a series of hands-on labs, you'll gain practical experience working with the key parts of Kubernetes and learn how to deploy, manage, and scale applications in a cloud-native environment.

### 📚 What You Will Learn

- **🏗️ Kubernetes Architecture**: Core components and how they work together
- **🚀 Application Deployments**: Creating, updating, and scaling workloads
- **🌐 Networking**: Service discovery and communication patterns
- **💾 Persistent Storage**: Managing stateful applications and data
- **⚖️ Auto-scaling**: Dynamically adjusting resources based on demand
- **🔐 Security**: Implementing RBAC and network policies
- **🛠️ Production Practices**: Real-world deployment strategies and patterns

## ✅ Prerequisites

- Basic familiarity with containers and containerisation concepts
- Comfort using command-line interfaces
- Basic understanding of YAML syntax
- All other necessary resources will be provided during the workshop

## 💻 Lab Environment

Each participant will have access to a pre-configured two-node Kubernetes cluster running in Digital Ocean. The environment comes with all necessary tools installed.

To access your environment, follow the instructions provided [here](access.md).

## 🧪 Workshop Labs

The workshop consists of nine hands-on labs, each focusing on different aspects of Kubernetes:

1. **[🔰 Initial Kubernetes Exploration](labs/1-essentials.md)**
2. **[📦 Deployments and Rolling Updates](labs/2-deployments.md)**
3. **[🔄 DaemonSets](labs/3-daemonsets.md)**
4. **[🌐 Services and Networking](labs/4-services.md)**
5. **[⚖️ Horizontal Pod Autoscaling](labs/5-autoscaling.md)**
6. **[💾 Persistent Storage](labs/6-storage.md)**
7. **[🔒 Network Policies](labs/7-network-policies.md)**
8. **[🔑 RBAC and Security](labs/8-rbac.md)**
9. **[🏆 Comprehensive Final Exercise (Bonus)](labs/9-complete-app.md)**

## 🔄 Workshop Flow

<div style="padding: 15px; margin: 20px 0; background-color: #e3f2fd; border-left: 5px solid #2196f3; border-radius: 4px;">
<p>Each lab follows a consistent structure to enhance your learning:</p>
<ol>
  <li><strong>Objective</strong>: What you will learn in the lab</li>
  <li><strong>Tasks</strong>: Step-by-step instructions with explanations</li>
  <li><strong>Validation</strong>: How to verify your work</li>
  <li><strong>Clean-up</strong>: Instructions to reset your environment after each exercise</li>
</ol>
<p><strong>Important</strong>: Please follow the clean-up instructions at the end of each lab to ensure your cluster resources remain available for later exercises.</p>
</div>

## 📚 Additional Resources

- [Kubernetes Official Documentation](https://kubernetes.io/docs/home/)
- [Kubernetes Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [CNCF Cloud Native Interactive Landscape](https://landscape.cncf.io/)

## 🛠️ Troubleshooting

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

## 💬 Feedback

<div style="padding: 15px; margin: 20px 0; background-color: #fff8e1; border-left: 5px solid #ffc107; border-radius: 4px;">
<h3 style="margin-top: 0; color: #ff8f00;">📝 Your Feedback Matters!</h3>
<p>At the end of the workshop, please take a few minutes to share your thoughts by completing our <a href="https://forms.gle/HxoVhSZRNk49BweS9">feedback form</a>.</p>
<p>Your input helps us improve future workshops and develop new content based on your needs and interests.</p>
</div>
