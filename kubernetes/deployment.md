# Kubernetes Deployment Strategies on AKS

This document explains the most commonly used Kubernetes deployment strategies:

* Rolling Update (Rollout)
* Blue-Green Deployment
* Canary Deployment
* A/B Testing

It also compares:

* How applications are deployed
* How testing is performed
* How traffic is shifted
* AKS implementation examples

---

# Table of Contents

1. Introduction
2. Rolling Update (Rollout)
3. Blue-Green Deployment
4. Canary Deployment
5. A/B Testing
6. Comparison Table
7. When to Use What
8. AKS Examples
9. Tools Commonly Used in AKS

---

# 1. Introduction

Modern Kubernetes deployments aim to:

* Minimize downtime
* Reduce deployment risk
* Allow rollback
* Enable testing before full release

Kubernetes supports multiple deployment strategies depending on business and operational requirements.

---

# 2. Rolling Update (Rollout)

## Overview

Rolling update is the **default Kubernetes deployment strategy**.

Pods are updated gradually:

* Old pods are terminated
* New pods are created incrementally

Users continue accessing the application during deployment.

---

## How Rollout Works

Example:

Current deployment:

* 10 pods running v1

New deployment:

* v2 image deployed

Kubernetes:

1. Terminates 1–2 old pods
2. Creates 1–2 new pods
3. Waits for health checks
4. Continues until all pods are v2

---

## Traffic Flow

Traffic automatically shifts because:

* Service selector remains same
* New pods join service endpoints
* Old pods leave service endpoints

No manual traffic switching required.

---

## Tester Validation

Testing options:

* Validate staging before deployment
* Monitor logs/metrics during rollout
* Test few pods manually

But:

* Testers cannot fully isolate production traffic
* Old and new versions coexist temporarily

---

## Advantages

* Simple
* Native Kubernetes support
* No extra infrastructure
* Minimal downtime

---

## Disadvantages

* Rollback can take time
* Bad release partially affects users
* No isolated testing in production

---

## AKS Example

## deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
spec:
  replicas: 4

  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1

  selector:
    matchLabels:
      app: webapp

  template:
    metadata:
      labels:
        app: webapp

    spec:
      containers:
      - name: webapp
        image: myacr.azurecr.io/webapp:v2

        ports:
        - containerPort: 80
```

---

## Deploy in AKS

```bash
kubectl apply -f deployment.yaml
```

---

## Watch Rollout

```bash
kubectl rollout status deployment/webapp
```

---

## Rollback

```bash
kubectl rollout undo deployment/webapp
```

---

# 3. Blue-Green Deployment

## Overview

Blue-Green deployment maintains:

* Two separate environments

Example:

* Blue = current production
* Green = new version

Only one receives production traffic at a time.

---

## How Blue-Green Works

### Initial State

Production traffic → Blue (v1)

Green (v2) exists but receives no traffic.

---

### Deployment Steps

1. Deploy Green environment
2. Test Green completely
3. Switch traffic from Blue → Green
4. Keep Blue for rollback

---

## Traffic Flow

Traffic switch usually happens by:

* Changing Kubernetes Service selector
* Changing Ingress routing
* Updating load balancer target

Traffic shift is usually:

* Instant
* 100% switch

---

## Tester Validation

Testers can:

* Access Green environment directly
* Perform full production-like testing
* Validate before public exposure

This is a major advantage.

---

## Advantages

* Very safe rollback
* Zero downtime
* Full environment testing
* Instant rollback

---

## Disadvantages

* Double infrastructure cost
* More operational complexity
* Requires duplicate environment

---

# AKS Example

## Blue Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-blue

spec:
  replicas: 3

  selector:
    matchLabels:
      app: webapp
      version: blue

  template:
    metadata:
      labels:
        app: webapp
        version: blue

    spec:
      containers:
      - name: webapp
        image: myacr.azurecr.io/webapp:v1
```

---

## Green Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-green

spec:
  replicas: 3

  selector:
    matchLabels:
      app: webapp
      version: green

  template:
    metadata:
      labels:
        app: webapp
        version: green

    spec:
      containers:
      - name: webapp
        image: myacr.azurecr.io/webapp:v2
```

---

## Service Initially Pointing to Blue

```yaml
apiVersion: v1
kind: Service
metadata:
  name: webapp-service

spec:
  selector:
    app: webapp
    version: blue

  ports:
  - port: 80
    targetPort: 80
```

---

## Switch Traffic to Green

Update service selector:

```yaml
selector:
  app: webapp
  version: green
```

Apply:

```bash
kubectl apply -f service.yaml
```

Traffic instantly shifts.

---

## Rollback

Change selector back to:

```yaml
version: blue
```

---

# 4. Canary Deployment

## Overview

Canary deployment releases application gradually to a small percentage of users.

Example:

* 5% traffic → v2
* 95% traffic → v1

If stable:

* Increase to 20%
* Then 50%
* Then 100%

---

## How Canary Works

Both versions run simultaneously.

Traffic is split gradually.

Monitoring is critical:

* Errors
* Latency
* CPU/memory
* Business metrics

---

## Traffic Flow

Traffic shifting is progressive.

Example:

| Stage   | v1 Traffic | v2 Traffic |
| ------- | ---------: | ---------: |
| Initial |       100% |         0% |
| Step 1  |        95% |         5% |
| Step 2  |        80% |        20% |
| Step 3  |        50% |        50% |
| Final   |         0% |       100% |

---

## Tester Validation

Testers can:

* Access canary version directly
* Observe production behavior
* Validate metrics before full rollout

Real users help validate release quality.

---

## Advantages

* Reduced deployment risk
* Gradual exposure
* Better production validation
* Easy monitoring

---

## Disadvantages

* More complex
* Requires traffic management
* Needs observability tooling

---

# AKS Canary Example Using NGINX Ingress

---

## Stable Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-stable

spec:
  replicas: 5

  selector:
    matchLabels:
      app: webapp
      version: stable

  template:
    metadata:
      labels:
        app: webapp
        version: stable

    spec:
      containers:
      - name: webapp
        image: myacr.azurecr.io/webapp:v1
```

---

## Canary Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-canary

spec:
  replicas: 1

  selector:
    matchLabels:
      app: webapp
      version: canary

  template:
    metadata:
      labels:
        app: webapp
        version: canary

    spec:
      containers:
      - name: webapp
        image: myacr.azurecr.io/webapp:v2
```

---

## Stable Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: webapp-stable-service

spec:
  selector:
    app: webapp
    version: stable

  ports:
  - port: 80
```

---

## Canary Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: webapp-canary-service

spec:
  selector:
    app: webapp
    version: canary

  ports:
  - port: 80
```

---

## Main Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: webapp-ingress

spec:
  ingressClassName: nginx

  rules:
  - host: demo.example.com

    http:
      paths:
      - path: /
        pathType: Prefix

        backend:
          service:
            name: webapp-stable-service
            port:
              number: 80
```

---

## Canary Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: webapp-canary-ingress

  annotations:
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-weight: "10"

spec:
  ingressClassName: nginx

  rules:
  - host: demo.example.com

    http:
      paths:
      - path: /
        pathType: Prefix

        backend:
          service:
            name: webapp-canary-service
            port:
              number: 80
```

---

## Increase Canary Traffic

```yaml
nginx.ingress.kubernetes.io/canary-weight: "25"
```

Then:

```bash
kubectl apply -f canary-ingress.yaml
```

---

# 5. A/B Testing

## Overview

A/B testing routes different users to different application versions based on rules.

Unlike canary:

* Goal is experimentation
* Not deployment safety

---

## How A/B Testing Works

Example:

* Users from India → Version A
* Premium users → Version B
* Mobile users → Experimental UI

Traffic routing depends on:

* Headers
* Cookies
* Geography
* User groups

---

## Traffic Flow

Traffic is routed intentionally based on business rules.

Not percentage-based rollout.

---

## Tester Validation

Product teams validate:

* Conversion rates
* User engagement
* Click-through rates
* Business KPIs

This is heavily product-driven.

---

## Advantages

* Business experimentation
* Feature validation
* User behavior analysis

---

## Disadvantages

* Complex routing
* Requires analytics integration
* More application logic

---

# AKS A/B Testing Example with NGINX Header Routing

---

## Version A Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: webapp-a

spec:
  selector:
    version: a

  ports:
  - port: 80
```

---

## Version B Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: webapp-b

spec:
  selector:
    version: b

  ports:
  - port: 80
```

---

## A/B Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress

metadata:
  name: ab-testing

  annotations:
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-by-header: "x-experiment"

spec:
  ingressClassName: nginx

  rules:
  - host: demo.example.com

    http:
      paths:
      - path: /
        pathType: Prefix

        backend:
          service:
            name: webapp-b
            port:
              number: 80
```

---

## Request Header

Users with:

```http
x-experiment: beta
```

Can be routed to Version B.

Others continue using Version A.

---

# 6. Comparison Table

| Feature             | Rolling Update    | Blue-Green     | Canary         | A/B Testing             |
| ------------------- | ----------------- | -------------- | -------------- | ----------------------- |
| Kubernetes Native   | Yes               | Partially      | No             | No                      |
| Downtime            | Minimal           | None           | None           | None                    |
| Infrastructure Cost | Low               | High           | Medium         | Medium                  |
| Rollback Speed      | Medium            | Instant        | Fast           | Depends                 |
| Traffic Splitting   | Automatic         | Instant Switch | Gradual        | Rule-based              |
| Production Testing  | Limited           | Excellent      | Excellent      | Excellent               |
| Complexity          | Low               | Medium         | High           | High                    |
| Main Goal           | Simple Deployment | Safe Release   | Risk Reduction | Product Experimentation |

---

# 7. When to Use What

## Use Rolling Update When

* Small/medium applications
* Simplicity preferred
* Basic deployments sufficient

---

## Use Blue-Green When

* Zero downtime critical
* Fast rollback needed
* Financial/enterprise systems

---

## Use Canary When

* Large user base
* Frequent releases
* SRE/observability mature

---

## Use A/B Testing When

* Product experimentation required
* UX testing needed
* Marketing/product analytics important

---

# 8. Tools Commonly Used in AKS

| Tool                      | Purpose                      |
| ------------------------- | ---------------------------- |
| Kubernetes Deployment     | Rolling updates              |
| NGINX Ingress             | Canary/A-B routing           |
| Azure Application Gateway | Traffic routing              |
| Istio                     | Service mesh                 |
| Linkerd                   | Lightweight service mesh     |
| Argo Rollouts             | Progressive delivery         |
| Flagger                   | Automated canary deployments |

---

# 9. Recommended Enterprise Pattern

Most enterprises follow this model:

| Application Type        | Strategy       |
| ----------------------- | -------------- |
| Internal apps           | Rolling Update |
| Critical APIs           | Canary         |
| Banking/payment systems | Blue-Green     |
| Product experiments     | A/B Testing    |

---

# Conclusion

There is no single best deployment strategy.

Choice depends on:

* Risk tolerance
* Traffic volume
* Infrastructure budget
* Operational maturity
* Business requirements

In AKS:

* Rolling updates are easiest
* Blue-Green provides safest rollback
* Canary offers safest gradual rollout
* A/B testing enables business experimentation

Modern enterprise platforms often combine multiple strategies together.
