# Ingress setup and demo app
## Pre-requisites for Shop api app  

## Install NGINX Ingress Controller  
```
# Add NGINX repo
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install (creates LoadBalancer)
helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.service.type=LoadBalancer
```
  
### Get external IP  
```
kubectl get svc -n ingress-nginx nginx-ingress-ingress-nginx-controller
# EXTERNAL-IP = your-load-balancer-ip
```

## Install Cert-Manager (Let’s Encrypt)
```
# Install cert-manager
helm repo add jetstack https://charts.jetstack.io
helm repo update

helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace \
  --version v1.15.3 \
  --set installCRDs=true
```

### Let’s Encrypt ClusterIssuer
```
# letsencrypt-prod.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
meta
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
meta
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-staging
    solvers:
    - http01:
        ingress:
          class: nginx
```
  
# Demo app  
```
Dir Structure
shop-demo/
├── Chart.yaml
├── values.yaml
├── values-dev.yaml
├── values-prod.yaml
└── templates/
    ├── _helpers.tpl
    ├── frontend-deployment.yaml
    ├── frontend-service.yaml
    ├── api-deployment.yaml
    ├── api-service.yaml
    ├── admin-deployment.yaml
    ├── admin-service.yaml
    └── ingress.yaml
```
## frontend-deployment.yaml  
```
# Frontend
apiVersion: apps/v1
kind: Deployment
meta
  name: frontend
  namespace: shop-demo
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
        image: nginx:alpine
        ports:
        - containerPort: 80
```
## frontend-service.yaml  
```
apiVersion: v1
kind: Service
meta
  name: frontend
  namespace: shop-demo
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
```
  
## backend-api-deployment.yaml  
```
apiVersion: apps/v1
kind: Deployment
meta
  name: api
  namespace: shop-demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api
  template:
    meta
      labels:
        app: api
    spec:
      containers:
      - name: api
        image: httpd:alpine
        ports:
        - containerPort: 80
```
## backend-api-service.yaml  
```
apiVersion: v1
kind: Service
meta
  name: api
  namespace: shop-demo
spec:
  selector:
    app: api
  ports:
  - port: 80
    targetPort: 80
```
  
## backend-admin-deployment.yaml
```
apiVersion: apps/v1
kind: Deployment
meta
  name: admin
  namespace: shop-demo
spec:
  replicas: 2
  selector:
    matchLabels:
      app: admin
  template:
    meta
      labels:
        app: admin
    spec:
      containers:
      - name: admin
        image: nginx:alpine
        ports:
        - containerPort: 80
``` 
## backend-admin-service.yaml
```
apiVersion: v1
kind: Service
meta
  name: admin
  namespace: shop-demo
spec:
  selector:
    app: admin
  ports:
  - port: 80
    targetPort: 80
```
## Common ingress
```
# host-routing.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: api-ingress
  namespace: shop-demo
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-staging"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - api.shop.com
    secretName: shop-tls
  rules:
  - host: api.shop.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: api
            port:
              number: 80
---
# path-routing.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: frontend-ingress
  namespace: shop-demo
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-staging"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - shop.com
    secretName: shop-tls
  rules:
  - host: shop.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend
            port:
              number: 80
      - path: /admin
        pathType: Prefix
        backend:
          service:
            name: admin
            port:
              number: 80
---
```
# Verify Setup  

## Test Routing + TLS  
```
Edit  /etc/hosts  (Local Testing): 
<NGINX-IP> shop.com api.shop.com

Test L7 Routing: 
curl -k http://shop.demo.local     # Frontend (nginx welcome)
curl -k http://shop.demo.local/admin  # Admin (nginx welcome)  
curl -k http://api.shop.demo.local    # API (Apache welcome)

Verify TLS:
openssl s_client -connect shop.com:443 -servername shop.com
echo | openssl s_client -connect api.shop.com:443 -servername api.shop.com 2>/dev/null | openssl x509 -noout -subject

Verify Certificates:
kubectl get certificate -n shop-demo
kubectl get secret shop-tls -n shop-demo -o yaml
kubectl describe certificate shop-tls -n shop-demo

test redirect:
# 1. Get NGINX IP
INGRESS_IP=$(kubectl get svc -n ingress-nginx nginx-ingress-ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# 2. Edit /etc/hosts
echo "$INGRESS_IP shop.com" | sudo tee -a /etc/hosts

# 3. Test HTTP → HTTPS redirect
curl -I http://shop.demo.local
# HTTP/1.1 308 Permanent Redirect
# Location: http://shop.demo.local

# 4. Test HTTPS works
curl -k https://api-aksingressdemo.duckdns.org

```
  
# Setup Summary  
```
1. Install NGINX Ingress → LoadBalancer IP
2. Deploy 3 apps → Services ready
3. Host-based Ingress → api.shop.com
4. Path-based Ingress → shop.com + /admin
5. Cert-Manager → Auto TLS certs
6. Test with curl + /etc/hosts
7. Verify cert-manager events
```

# Helm cheat sheet for this exercise
```
helm create shop-demo # No need to do this when you already have the dir structure
helm lint shop-demo
helm template demo-release shop-demo -f shop-demo/values-dev.yaml
helm install demo-release ./shop-demo -n demo --create-namespace -f shop-demo/values-dev.yaml
helm upgrade demo-release ./shop-demo -n demo -f shop-demo/values-prod.yaml
helm package shop-demo # create package release for distribution
helm uninstall demo-release -n demo
```