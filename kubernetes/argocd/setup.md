# Setup for argocd
## Pre-requisites for argocd ingress  

## Install NGINX Ingress Controller  
```
# Add NGINX repo
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install (creates LoadBalancer)
helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.service.type=LoadBalancer \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"="/healthz"
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
metadata:
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
metadata:
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
## Register a free sub-domain with freedns
```
1. Sign up with https://freedns.afraid.org/
2. Register a sub-domain with any publicly available domain like moo.com. Click on the name.
```
![Domains list](./Domain-List.png)
```
4. Add A type DNS record for argocd as in the diagram, complete the captcha and hit save.
```
![DNS Instructions](./DNS-Record-Instructions.png)
![DNS Records list](./DNS-A-Record.png)
```
5. Wait for this DNS entry to propagate
6. Run command dig <DNS address> and look for the STATUS field. should be NOERROR
```
## Deploy argocd using helm
```
Run below commands from the ghrunner vm to first setup az aks credentials.

az aks get-credentials --resource-group <your-rg> --name <your-aks-cluster-name> --overwrite-existing

kubelogin convert-kubeconfig -l azurecli

Then run helm commands to setup argocd controller -

helm repo add argo https://argoproj.github.io/argo-helm

helm repo update

helm install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  --set crds.install=true

Fetch the argocd password from the command -

kubectl -n argocd \
get secret \
argocd-initial-admin-secret \
-o jsonpath="{.data.password}" | base64 -d

Apply argo-ingress.yaml and now you can access the argo endpoint using your dns
