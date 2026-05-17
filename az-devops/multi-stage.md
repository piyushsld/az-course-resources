# Pre-requisites 
```
Use this mapping:[3][7][4]

| Item | Example |
|---|---|
| Agent pool | `self-hosted-agent` [5] |
| Agent name | `ado-agent-01` [5] |
| Docker service connection | `acr-name-sconn` [3] |
| ARM service connection | `sc-azure-arm` [7] |
| Dev environment | `dev` [4] |
| Prod environment | `prod` [4] |
| Environment resources | `aks-dev`, `aks-prod` [4] |

Step 1 - Create a private SKU acr.
Step 2 - Create service connection to acr created in step 1 (WIF to establish).
Step 3 - use the existing or create a new ARM service connection (WIF based App registration) keyless [Client ID, subscription ID, no secrets]
Step 4 - add variables in variable group for ACR and ARM service connection [not used for this demo case]

```
## Step 5 - creating an agent pool in
```
Go to project settings > Agent Pools > Create a Agent pool [VM instance, VMSS ]
```
## Step 6 - rg > vnet > subnets > NSG > NAT Gateway

## Step 7 - create agent
```
Connectivity model --
The key idea is that the self-hosted agent runs on a VM or VMSS instance in your Azure network, registers to an agent pool, and then keeps an outbound session to Azure DevOps. Microsoft’s agent docs describe self-hosted agents as machines you manage yourself, while the firewall guidance says to open  dev.azure.com  and related Azure DevOps endpoints rather than expecting Azure DevOps to initiate inbound traffic to the agent.
For VM Scale Set agents, Microsoft also notes that the agent extension on the instance must be able to download agent files from  https://download.agent.dev.azure.com  and the build agent must be able to register with Azure DevOps Services. That is why a private subnet with outbound internet or proxy egress works, while inbound from Azure DevOps is unnecessary

Recommended network layout --
A simple and safe design is one VNet with separate subnets for agent VMs and private services, then controlled outbound egress via NAT Gateway, Azure Firewall, or a corporate proxy. Microsoft specifically calls out VMSS agents as useful when you need to deploy to private targets inside a private VNet or when you need to restrict connectivity and allow only approved sites.
Use a layout like this:
	•	 vnet-devops-demo  with address space such as  10.20.0.0/16 .
	•	 snet-agents  for self-hosted agent VMs or VMSS, for example  10.20.1.0/24 .
	•	 snet-private-endpoints  for ACR private endpoint, Key Vault private endpoint, or AKS private endpoint, for example  10.20.2.0/24 .
	•	Optional  AzureBastionSubnet  if you want secure admin access without public IPs.
	•	Optional firewall or proxy subnet if you centralize outbound control.
A practical rule is to avoid putting agent VMs and private endpoints in the same subnet, because private endpoints are easier to manage and troubleshoot when isolated. Also size the agent subnet with future scale in mind; Microsoft warns that scale-set agent pools can fail to scale if the subnet lacks enough IP addresses.

Create the VM --
Use Ubuntu 22.04 or 24.04, place it in  snet-agents , and attach an NSG that allows only the admin traffic you need, such as SSH from Bastion or a jump box. Azure DevOps itself does not need inbound NSG rules to the VM because the agent connects outbound.

Provide outbound internet ---
Your VM needs outbound access to Azure DevOps endpoints and agent download endpoints, plus Azure/ACR endpoints if you build and push images. Microsoft explicitly states the agent extension must reach  download.agent.dev.azure.com , and the firewall guidance requires Azure DevOps URLs such as  dev.azure.com  and related IP ranges to be open.
Good options are:
	•	NAT Gateway on  snet-agents 
	•	Azure Firewall with application/network rules
	•	Corporate proxy; Azure DevOps agents support proxy configuration via  --proxyurl ,  --proxyusername , and  --proxypassword 

Create an agent pool in Azure DevOps ---
In Azure DevOps, go to Organization settings -> Agent pools -> Add pool, choose Self-hosted, and create a pool such as  self-hosted-acr . Self-hosted agents register to pools and run one job at a time

If the VM sits behind a proxy, add proxy parameters during configuration because Azure DevOps documents proxy support directly in the agent setup.

NSG and routing guidance ---
Keep NSGs simple: deny inbound by default, allow only admin paths you actually use, and permit outbound to required destinations. Since the agent initiates communication, the important rules are outbound rather than inbound.
Typical NSG stance:
	•	Inbound: allow Bastion or jump-box SSH only, deny everything else.
	•	Outbound: allow HTTPS 443 to Azure DevOps and agent download domains.
	•	Outbound: allow Azure resource destinations such as ACR, Key Vault, AKS API server, package repositories, and Linux update mirrors if your build uses them.
If you use UDRs, route  snet-agents  outbound traffic through NAT Gateway or Azure Firewall. The more locked-down your egress path is, the more important it is to maintain allow rules for Azure DevOps URLs and agent download endpoints.

Private ACR design ---
If your goal is to push images into a private ACR, the cleanest layout is to put a private endpoint for ACR in  snet-private-endpoints  and link a private DNS zone so the agent VM resolves the ACR login server privately. This keeps image pushes inside your private Azure network path while the agent still maintains outbound HTTPS connectivity to Azure DevOps Services.
In practice that means:
	•	ACR with public network access disabled or restricted.
	•	Private endpoint in  snet-private-endpoints .
	•	Private DNS zone linked to the VNet.
	•	Agent VM in  snet-agents  resolves  <acrname>.azurecr.io  to the private endpoint IP.

Execute these steps inside the linux host

mkdir -p ~/azdo-agent && cd ~/azdo-agent
curl -L -o agent.tar.gz https://download.agent.dev.azure.com/agent/4.255.0/vsts-agent-linux-x64-4.255.0.tar.gz
tar zxvf agent.tar.gz

./config.sh --unattended \
  --url https://dev.azure.com/LivingADO \
  --auth pat \
  --token <your-token-here> \
  --pool self-hosted-agent \
  --agent ado-agent-01 \
  --work _work \
  --replace

sudo ./svc.sh install $(whoami)
sudo ./svc.sh start

sudo apt-get update
sudo apt-get install -y curl ca-certificates git jq docker.io wget apt-transport-https gnupg lsb-release
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker "$USER"

curl -fsSL 'https://azurecliprod.blob.core.windows.net/$root/deb_install.sh' | sudo bash

sudo apt install python3.12-venv

Also install Docker and make the agent user able to run Docker, because the Docker task needs a working Docker engine on the agent host. After installing new software, restart the agent so capabilities are refreshed in the pool

What not to do
Do not design the network expecting Azure DevOps to connect inbound to your VM over SSH or any custom port, because that is not how self-hosted agents work. The agent reaches out to Azure DevOps, registers, and polls for jobs, so opening inbound access from the internet is unnecessary unless you need it for your own administration.
Also, for VMSS agents, do not enable Azure autoscale or overprovisioning on the scale set; Microsoft explicitly says Azure Pipelines does not support those settings for VMSS agent pools.

```

## Step - setup repo
```
Dir structure -
ado-aks-trivy-demo/
├── app/
│   ├── __init__.py - blank
│   └── main.py
├── tests/
│   └── test_app.py [developers create tests for their api]
├── scripts/
│   └── bootstrap-self-hosted-agent.sh [Required for VMSS]
├── requirements.txt [python application dependencies]
├── Dockerfile
├── .dockerignore
├── pytest.ini [instructions for running tests]
├── azure-pipelines.yml
└── README.md

main.py - 

from flask import Flask, jsonify

app = Flask(__name__)


@app.get("/")
def index():
    return jsonify({
        "message": "Azure DevOps ACR AKS Trivy demo app",
        "status": "ok"
    })


@app.get("/health")
def health():
    return jsonify({"status": "healthy"}), 200


@app.get("/version")
def version():
    return jsonify({"version": "1.0.0"})


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)


test_app.py - 

from app.main import app

def test_root_endpoint():
    client = app.test_client()
    response = client.get("/")
    assert response.status_code == 200

def test_health_endpoint():
    client = app.test_client()
    response = client.get("/health")
    assert response.status_code == 200


requirements.txt -

Flask==3.0.3
pytest==8.3.3
gunicorn==23.0.0

pytest.ini -

[pytest]
testpaths = tests
python_files = test_*.py

.dockerignore -

.git
.venv
__pycache__
.pytest_cache
*.pyc
*.pyo
*.pyd
.vscode

Dockerfile -

FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -fsS http://127.0.0.1:8000/health || exit 1

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "app.main:app"]


bootstrap-self-hosted-agent.sh -

#!/usr/bin/env bash
set -euo pipefail

AZP_URL="${AZP_URL:-https://dev.azure.com/LivingADO/"
AZP_POOL="${AZP_POOL:-self-hosted-agent}"
AZP_AGENT_NAME="${AZP_AGENT_NAME:-ado-agent-1}"
AZP_WORK="${AZP_WORK:-_work}"
AZP_TOKEN="${AZP_TOKEN:-}"
AGENT_VERSION="${AGENT_VERSION:-4.255.0}"

if [[ -z "$AZP_TOKEN" ]]; then
  echo "AZP_TOKEN is required"
  exit 1
fi

sudo apt-get update
sudo apt-get install -y curl ca-certificates git jq docker.io wget apt-transport-https gnupg lsb-release
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker "$USER"

curl -fsSL 'https://azurecliprod.blob.core.windows.net/$root/deb_install.sh' | sudo bash

sudo apt install python3.12-venv

mkdir -p "$HOME/azdo-agent"
cd "$HOME/azdo-agent"

curl -L -o agent.tar.gz "https://download.agent.dev.azure.com/agent/${AGENT_VERSION}/vsts-agent-linux-x64-${AGENT_VERSION}.tar.gz"
tar zxvf agent.tar.gz

./config.sh --unattended \
  --url "$AZP_URL" \
  --auth pat \
  --token "$AZP_TOKEN" \
  --pool "$AZP_POOL" \
  --agent "$AZP_AGENT_NAME" \
  --work "$AZP_WORK" \
  --replace

sudo ./svc.sh install "$USER"
sudo ./svc.sh start

echo "Agent installed. Re-login once so docker group membership applies to your shell."



```


## Step - setup pipeline
```
trigger:
- main

pr:
- main

variables:
  vmImageName: 'ubuntu-latest'
  selfHostedPool: 'self-hosted-agent'

  dockerRegistryServiceConnection: 'lddevopspvtacr-scon'
  azureSubscription: 'WIF-AZLogin'
  acrName: 'lddevopspvtacr'
  acrLoginServer: 'lddevopspvtacr.azurecr.io'
  imageRepository: 'demoapp'
  dockerfilePath: '$(Build.SourcesDirectory)/ado-aks-trivy-demo/Dockerfile'
  imageTag: '$(Build.BuildId)'
  fullImageName: '$(acrLoginServer)/$(imageRepository):$(imageTag)'

  # aksResourceGroup: 'rg-aks-demo'
  # aksClusterName: 'aks-demo'
  # k8sNamespaceDev: 'dev'
  # k8sNamespaceProd: 'prod'

stages:
- stage: Build_Test_Scan_Push
  displayName: Build, Test, Scan and Push
  jobs:
  - job: BuildAndScan
    displayName: Build on self-hosted agent
    pool:
      name: $(selfHostedPool)
    steps:
    - checkout: self

    - bash: |
        set -eux
        docker version
        az version || true
      displayName: Validate toolchain

    - bash: |
        set -eux
        cd ado-aks-trivy-demo
        export PYTHONPATH=$(pwd)
        python3 -m venv .venv
        . .venv/bin/activate
        pip install -r requirements.txt
        pytest -q --junitxml=$(Build.SourcesDirectory)/test-results.xml
      displayName: Run unit tests

    - task: PublishTestResults@2
      displayName: Publish test results
      condition: succeededOrFailed()
      inputs:
        testResultsFormat: JUnit
        testResultsFiles: '$(Build.SourcesDirectory)/test-results.xml'
        failTaskOnFailedTests: true

    - task: Docker@2
      displayName: Build image
      inputs:
        command: build
        repository: $(imageRepository)
        dockerfile: $(dockerfilePath)
        containerRegistry: $(dockerRegistryServiceConnection)
        tags: |
          $(imageTag)

    - bash: |
        set -eux
        mkdir -p $(Build.ArtifactStagingDirectory)/trivy

        if ! command -v trivy >/dev/null 2>&1; then
          sudo apt-get update
          sudo apt-get install -y wget apt-transport-https gnupg lsb-release
          wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | \
            gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg >/dev/null
          echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | \
            sudo tee /etc/apt/sources.list.d/trivy.list
          sudo apt-get update
          sudo apt-get install -y trivy
        fi

        trivy image \
          --scanners vuln \
          --exit-code 0 \
          --severity CRITICAL,HIGH \
          --format table \
          --output $(Build.ArtifactStagingDirectory)/trivy/trivy-report.txt \
          $(acrLoginServer)/$(imageRepository):$(imageTag)

        trivy image \
          --format json \
          --output $(Build.ArtifactStagingDirectory)/trivy/trivy-report.json \
          $(acrLoginServer)/$(imageRepository):$(imageTag)
      displayName: Scan image with Trivy

    - publish: $(Build.ArtifactStagingDirectory)/trivy
      artifact: trivy-scan
      displayName: Publish Trivy report

    - task: Docker@2
      displayName: Push image to private ACR
      inputs:
        command: push
        repository: $(imageRepository)
        containerRegistry: $(dockerRegistryServiceConnection)
        tags: |
          $(imageTag)

    # - bash: |
    #     set -eux
    #     mkdir -p $(Build.ArtifactStagingDirectory)/manifests
    #     sed "s#__IMAGE__#$(acrLoginServer)/$(imageRepository):$(imageTag)#g" k8s/deployment.yaml > $(Build.ArtifactStagingDirectory)/manifests/deployment.yaml
    #     cp k8s/service.yaml $(Build.ArtifactStagingDirectory)/manifests/service.yaml
    #   displayName: Prepare manifests

    # - publish: $(Build.ArtifactStagingDirectory)/manifests
    #   artifact: manifests
    #   displayName: Publish manifests

- stage: Deploy_Dev
  displayName: Deploy to Dev
  dependsOn: Build_Test_Scan_Push
  condition: succeeded()
  jobs:
  - deployment: DeployDev
    displayName: Deploy to dev environment
    pool:
      name: $(selfHostedPool)
    environment: 'dev'
    strategy:
      runOnce:
        deploy:
          steps:
          - checkout: self
          - script: |
              echo "Deploying to dev environment"
              echo "Image: $(acrLoginServer)/$(imageRepository):$(imageTag)"
            displayName: Mark dev deployment

          # - task: KubernetesManifest@1
          #   displayName: Deploy to AKS dev
          #   inputs:
          #     action: deploy
          #     azureSubscriptionConnection: $(azureSubscription)
          #     azureResourceGroup: $(aksResourceGroup)
          #     kubernetesCluster: $(aksClusterName)
          #     namespace: $(k8sNamespaceDev)
          #     manifests: |
          #       $(Pipeline.Workspace)/manifests/deployment.yaml
          #       $(Pipeline.Workspace)/manifests/service.yaml
          #     containers: |
          #       $(acrLoginServer)/$(imageRepository):$(imageTag)

- stage: Deploy_Prod
  displayName: Deploy to Prod
  dependsOn: Deploy_Dev
  condition: succeeded()
  jobs:
  - deployment: ReleaseProd
    displayName: Deploy to prod environment
    pool:
      name: $(selfHostedPool)
    environment: 'prod'
    strategy:
      runOnce:
        deploy:
          steps:
          - checkout: self
          - script: |
              echo "Deploying to prod environment"
              echo "Image: $(acrLoginServer)/$(imageRepository):$(imageTag)"
            displayName: Mark prod deployment

          # - task: KubernetesManifest@1
          #   displayName: Deploy to AKS prod
          #   inputs:
          #     action: deploy
          #     azureSubscriptionConnection: $(azureSubscription)
          #     azureResourceGroup: $(aksResourceGroup)
          #     kubernetesCluster: $(aksClusterName)
          #     namespace: $(k8sNamespaceProd)
          #     manifests: |
          #       $(Pipeline.Workspace)/manifests/deployment.yaml
          #       $(Pipeline.Workspace)/manifests/service.yaml
          #     containers: |
          #       $(acrLoginServer)/$(imageRepository):$(imageTag)
        on:
          failure:
            steps:
            - script: echo "Rollback or notify here"
              displayName: Failure hook
          success:
            steps:
            - script: echo "Prod deployment succeeded"
              displayName: Success hook

```

## Step - Environment setup 
```
Environment setup in ADO
Create environments like  dev  and  prod , then either reference them directly in YAML so Azure DevOps creates them automatically, or pre-create them and add approvals/checks. Microsoft states the  environment  keyword targets the environment or resource used by the deployment job, and deployment history is recorded there.
For approvals, configure them in Pipelines -> Environments -> prod -> Approvals and checks. Once configured, the prod deployment job pauses until the approval completes, which is the cleanest way to control promotion through environments.

	•	 dev  environment: no manual approval, automatic deployment. Resources - aks-dev
	•	 prod  environment: approval required from a user group. Resources - aks-prod
	•	Show deployment history in the environment after each run.
```