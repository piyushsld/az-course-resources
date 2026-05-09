# Step 1: Deploy Multi-Service App
```
# Create test namespace
kubectl create namespace netpol-demo

# Deploy Backend API
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
meta
  name: backend
  namespace: netpol-demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    meta
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: nginx:alpine
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
meta
  name: backend
  namespace: netpol-demo
spec:
  selector:
    app: backend
  ports:
  - port: 80
    targetPort: 80
EOF

# Deploy Frontend
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
meta
  name: frontend
  namespace: netpol-demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    meta
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: busybox:1.35
        command: ['sh', '-c', 'wget -q -O- --timeout=5 backend:80 || echo "CANNOT REACH BACKEND"']
        args:
        - 'while true; do sleep 10; done'
EOF

# Deploy Attacker (BusyBox)
kubectl run attacker --image=busybox:1.35 -n netpol-demo --restart=Never --rm -it -- /bin/sh
```
## Demo 1: NO NetworkPolicy (Everything Allowed)  
### From Frontend → Backend
```
# In frontend pod
kubectl exec -n netpol-demo deploy/frontend -- wget -q -O- backend:80
# ✅ SUCCESS (200 OK)
```

### From Attacker → Backend
```
kubectl exec -n netpol-demo attacker -- wget -q -O- backend:80
# ✅ SUCCESS (200 OK) ← BAD! Attacker can access backend
```

## Demo 2: Apply DENY-ALL Policy  
```
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
meta
  name: deny-all
  namespace: netpol-demo
spec:
  podSelector: {}  # ALL pods in namespace
  policyTypes:
  - Ingress
  - Egress
EOF
```

### Test again:
```
# Frontend → Backend
kubectl exec -n netpol-demo deploy/frontend -- wget -q -O- backend:80
# ❌ FAILS (timeout/connection refused)

# Attacker → Backend  
kubectl exec -n netpol-demo attacker -- wget -q -O- backend:80
# ❌ FAILS (good!)
```

### Demo 3: ALLOW Frontend → Backend Only  
```
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
meta
  name: allow-frontend-backend
  namespace: netpol-demo
spec:
  podSelector:
    matchLabels:
      app: backend  # ← PROTECTS backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend  # ← ALLOW frontend only
    ports:
    - protocol: TCP
      port: 80
EOF
```
  
### Test selectively
```
# Frontend → Backend
kubectl exec -n netpol-demo deploy/frontend -- wget -q -O- backend:80
# ✅ SUCCESS (frontend allowed)

# Attacker → Backend
kubectl exec -n netpol-demo attacker -- wget -q -O- backend:80  
# ❌ FAILS (attacker blocked) ← SECURITY!
```


