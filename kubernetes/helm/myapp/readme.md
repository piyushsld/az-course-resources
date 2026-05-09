# Create a custom Helm chart  
  
## Helm chart structure -
```
myapp/
├── Chart.yaml          # Metadata (name, version, description)
├── values-dev.yaml     # DEFAULT values (dev-friendly)
├── values-prod.yaml    # Production overrides
├── charts/             # Sub-charts/dependencies
├── templates/          # Kubernetes manifests with {{ templates }}
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── hpa.yaml
│   ├── networkpolicy.yaml
│   └── pdb.yaml
└── README.md
```

## Step 1: Build & Push  
```
# Run below commands in myapp dir
# npm install
# npm ci
# docker build -t yourregistry/todo-api:v1.0.0 .
# docker push yourregistry/todo-api:v1.0.0
```

## Step 2: Setup custom chart structure
```
helm create todo-app
cd todo-app
```

### chart.yaml
```
apiVersion: v2
name: todo-app
description: Complete Todo API with HPA, VPA, NetworkPolicy, PDB
version: 1.0.0
appVersion: "1.0.0"
```

### values-dev.yaml (Dev Environment)
```
replicaCount: 2

image:
  repository: yourregistry/todo-api
  pullPolicy: IfNotPresent
  tag: "v1.0.0"

service:
  type: ClusterIP
  port: 3000

hpa:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 70

vpa:
  enabled: true
  updateMode: "Auto"

networkPolicy:
  enabled: true

pdb:
  enabled: true
  minAvailable: 1

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 128Mi

env: "dev"
```

### values-prod.yaml (Production)  
```
replicaCount: 5

image:
  repository: yourregistry/todo-api
  tag: "v1.0.0"

hpa:
  minReplicas: 5
  maxReplicas: 20

resources:
  limits:
    cpu: 1
    memory: 1Gi
  requests:
    cpu: 500m
    memory: 512Mi

env: "prod"
```

## Step 3: Templates  

### templates/deployment.yaml  
```
apiVersion: apps/v1
kind: Deployment
meta
  name: {{ include "todo-app.fullname" . }}
  labels:
    {{- include "todo-app.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "todo-app.selectorLabels" . | nindent 6 }}
  template:
    meta
      labels:
        {{- include "todo-app.selectorLabels" . | nindent 8 }}
    spec:
      containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        ports:
        - name: http
          containerPort: {{ .Values.service.port }}
          protocol: TCP
        resources:
{{ toYaml .Values.resources | nindent 10 }}
        env:
        - name: ENV
          value: {{ .Values.env | quote }}
---
```

### templates/hpa.yaml
```
{{- if .Values.hpa.enabled }}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
meta
  name: {{ include "todo-app.fullname" . }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ include "todo-app.fullname" . }}
  minReplicas: {{ .Values.hpa.minReplicas }}
  maxReplicas: {{ .Values.hpa.maxReplicas }}
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: {{ .Values.hpa.targetCPUUtilizationPercentage }}
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: {{ .Values.hpa.targetMemoryUtilizationPercentage }}
{{- end }}
```

### templates/networkpolicy.yaml  
```
{{- if .Values.networkPolicy.enabled }}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
meta
  name: {{ include "todo-app.fullname" . }}-allow-same-namespace
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector: {}
  egress:
  - to:
    - podSelector: {}
{{- end }}
```

### templates/pdb.yaml
```
{{- if .Values.pdb.enabled }}
apiVersion: policy/v1
kind: PodDisruptionBudget
meta
  name: {{ include "todo-app.fullname" . }}
spec:
  minAvailable: {{ .Values.pdb.minAvailable }}
  selector:
    matchLabels:
      {{- include "todo-app.selectorLabels" . | nindent 6 }}
{{- end }}
```

### templates/service.yaml
```
apiVersion: v1
kind: Service
meta
  name: {{ include "todo-app.fullname" . }}
  labels:
    {{- include "todo-app.labels" . | nindent 4 }}
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: http
      protocol: TCP
      name: http
  selector:
    {{- include "todo-app.selectorLabels" . | nindent 4 }}
```

### _helpers.tpl
```
{{/*
Expand the name of the chart.
*/}}
{{- define "todo-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "todo-app.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "todo-app.labels" -}}
helm.sh/chart: {{ include "todo-app.chart" . }}
{{ include "todo-app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "todo-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "todo-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "todo-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}
```

## Step 4: Deploy & Test  
### Install Dev Environment  
```
# Package chart
helm package .

# Install dev release
helm install todo-dev ./todo-app-1.0.0.tgz --namespace dev --create-namespace --values values.yaml

# Check deployment
kubectl get pods -n dev
kubectl get hpa -n dev
```
### Verify deployment
```
# Install chart
helm install todo-dev ./todo-app-1.0.0.tgz --namespace dev --create-namespace

# Check ALL resources
kubectl get all -n dev

# Port-forward to test service
kubectl port-forward svc/todo-dev -n dev 3000:3000
curl http://localhost:3000/health  # Should return {"status":"OK"}
```

### Load Test (Observe HPA)  
```
# Install Apache Bench (ab)
sudo apt-get install apache2-utils

# Stress test (generates CPU load)
ab -n 10000 -c 50 http://localhost:3000/health/
```

### Watch autoscaling  
```
kubectl get hpa -n dev -w
```  
**Note**: DESIRED REPLICAS jumps from 2 → 10 when CPU > 70%  
  
### Upgrade to Production  
```
helm upgrade todo-dev ./todo-app-1.0.0.tgz \
  --values values-prod.yaml \
  --namespace dev --install
```
## Verify upgrade 
``` 
helm list -n dev
kubectl get hpa -n dev
```
## Chart Versioning & Releases
```
# Version chart (update Chart.yaml)
helm package . --version 1.1.0

# List releases
helm list --all-namespaces

# Rollback
helm rollback todo-dev 1

# Uninstall
helm uninstall todo-dev -n dev
```

## Flow  
```
1. Deploy dev → Load test → Watch HPA scale 2→10 pods
2. Show `helm upgrade` with prod values → 5→20 replicas  
3. Deploy NetworkPolicy → Block external traffic
4. Show PDB protecting during node drain
5. VPA demo → Watch resource requests auto-adjust
6. Rollback demo → Safety net
```

