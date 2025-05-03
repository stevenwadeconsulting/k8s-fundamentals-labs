# Accessing Your Kubernetes Environment

This guide explains how to access your dedicated Kubernetes environment for the workshop.

## Access Overview

Each participant has been assigned their own environment consisting of:

- A bastion host (jump server) in Digital Ocean
- A 2-node Kubernetes cluster running in Digital Ocean

## 1️⃣ Find Your Participant Number

Locate the participant number provided on your desk. You will need this number to access your unique environment.

## 2️⃣ Access Your Instructions Page

Open your web browser and navigate to the following URL, replacing `<participant number>` with your assigned number:

```
https://devops-pro-europe-2025-k8s-workshop.lon1.digitaloceanspaces.com/<participant number>/instructions.html
```

For example, if your participant number is 042, you would navigate to:
```
https://devops-pro-europe-2025-k8s-workshop.lon1.digitaloceanspaces.com/participant-042/instructions.html
```

## 3️⃣ Follow the Web Instructions

On the instructions page, you will find:

- SSH credentials for your bastion host
- Details about your Kubernetes environment
- Initial access instructions

Follow all steps provided on this page to connect to your bastion host.

## 4️⃣ Set Up Your Workshop Environment

Once you have successfully connected to your bastion host, run the following commands to set up your workshop environment:

```bash
git clone https://github.com/stevenwadeconsulting/k8s-fundamentals-labs.git
cd k8s-fundamentals-labs
cd examples
```

## Troubleshooting

If you encounter any issues:

1. Double-check your participant number
2. Ensure you're using the correct SSH credentials from your instructions page
3. Ask one of the workshop facilitators for assistance

Your environment will remain available throughout the duration of the workshop.
