# Ingress Setup Guide

Complete guide for setting up Kubernetes Ingress controllers using various methods.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Method 1: NGINX Ingress Controller (Helm)](#method-1-nginx-ingress-controller-helm)
- [Method 2: NGINX Ingress Controller (Manifest)](#method-2-nginx-ingress-controller-manifest)
- [Method 3: Traefik Ingress](#method-3-traefik-ingress)
- [Method 4: AWS Load Balancer Controller](#method-4-aws-load-balancer-controller)
- [Basic Ingress Resource](#basic-ingress-resource)
- [Verification](#verification)

## Prerequisites

```bash
# Verify kubectl access
kubectl cluster-info

# Create namespace (optional)
kubectl create namespace ingress-nginx
```

## Method 1: NGINX Ingress Controller (Helm)

```bash
# Add Helm repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install NGINX Ingress
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer

# Verify installation
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
```

## Method 2: NGINX Ingress Controller (Manifest)

```bash
# Deploy using official manifest
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/cloud/deploy.yaml

# For bare-metal/on-premise
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/baremetal/deploy.yaml

# Check status
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

## Method 3: Traefik Ingress

```bash
# Add Traefik Helm repository
helm repo add traefik https://traefik.github.io/charts
helm repo update

# Install Traefik
helm install traefik traefik/traefik \
  --namespace traefik \
  --create-namespace \
  --set service.type=LoadBalancer

# Verify
kubectl get all -n traefik
```

## Method 4: AWS Load Balancer Controller

```bash
# Create IAM policy
curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json
aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam-policy.json

# Create service account
eksctl create iamserviceaccount \
  --cluster=<cluster-name> \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::<account-id>:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve

# Install controller
helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=<cluster-name> \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

## Basic Ingress Resource

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: example.com
    http:
      paths:
      - path: /app
        pathType: Prefix
        backend:
          service:
            name: app-service
            port:
              number: 80
  tls:
  - hosts:
    - example.com
    secretName: example-tls
```

## Verification

```bash
# Get Ingress controller external IP
kubectl get svc -n ingress-nginx

# List all ingress resources
kubectl get ingress --all-namespaces

# Describe specific ingress
kubectl describe ingress <ingress-name>

# Check controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller

# Test ingress
curl -H "Host: example.com" http://<EXTERNAL-IP>/app
```

## Common Annotations

```yaml
# SSL redirect
nginx.ingress.kubernetes.io/ssl-redirect: "true"

# Rate limiting
nginx.ingress.kubernetes.io/limit-rps: "10"

# CORS
nginx.ingress.kubernetes.io/enable-cors: "true"

# Custom timeout
nginx.ingress.kubernetes.io/proxy-connect-timeout: "60"

# AWS ALB specific
alb.ingress.kubernetes.io/scheme: internet-facing
alb.ingress.kubernetes.io/target-type: ip
```

## Troubleshooting

```bash
# Check controller status
kubectl get pods -n ingress-nginx -w

# View events
kubectl get events -n ingress-nginx --sort-by='.lastTimestamp'

# Test DNS resolution
nslookup example.com

# Uninstall (Helm)
helm uninstall ingress-nginx -n ingress-nginx
```
