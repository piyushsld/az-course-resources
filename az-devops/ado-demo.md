# ADO Demo Instructions

## Import a repo
```
Step 1 - Create a PAT token(classic) specifically for this use case in Github. Following the instructions in
recording, allow access to the PAT token and store it in a local note along with the https url of
the az-course-resources repo.
```  
Step 2 - Setup service connection with Github

Go to the Project setting of your ADO Project and look for service connections under pipelines
Click on New Service Connection from the top right button, and search for github.
Now in Authentication Method, select Personal Access Token and paste the PAT token from Step 1.
Give a name to the service connection that describes the Github org.

Step 3 - Now, select the repos option from the left panel, and from the drop-down lever at the top, select Import Repository.
Select Git as the type, and enter the url from Step 1. You will now see the repo populated in ADO along with all the branches

## Demo 1 - Docker build and push
```
Go to pipelines and create a new pipeline
Create a public acr and create a service connection for acr.
```
## Demo 2 - Azure artifact & feeds
```
Create a new repo from the Repos section
Step 1- Setup dir structure - You can directly upload the zip files from demo2.zip for this setup and skip the setup below

This is how the directory structure should look like -

ado-artifacts-demo/
├── azure-pipelines.yml
├── README.md
└── src/
    └── DemoPackage/
        ├── DemoPackage.csproj
        └── Class1.cs

Class1.cs -
namespace DemoPackage;

public class Class1
{
    public string Hello()
    {
        return "Hello from DemoPackage";
    }
}

DemoPackage.csproj -
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <PackageId>LivingADO.DemoPackage</PackageId>
    <Authors>Demo User</Authors>
    <Company>Demo Company</Company>
    <Description>Minimal NuGet package for Azure Artifacts demo</Description>
    <PackageTags>azure-devops;azure-artifacts;nuget;demo</PackageTags>
  </PropertyGroup>

</Project>

azure-pipelines.yml -
trigger:
- main

pool:
  vmImage: ubuntu-latest

variables:
- name: buildConfiguration
  value: Release
- name: packageVersion
  value: 1.0.$(Build.BuildId)
- group: ado-shared-vars

steps:
- checkout: self

- task: UseDotNet@2
  displayName: Install .NET SDK
  inputs:
    packageType: sdk
    version: '8.0.x'

- task: NuGetAuthenticate@1
  displayName: Authenticate to Azure Artifacts

- task: DotNetCoreCLI@2
  displayName: Restore
  inputs:
    command: restore
    projects: 'src/**/*.csproj'
    feedsToUse: select
    vstsFeed: '$(AZ_ARTIFACTS_FEED)'

- task: DotNetCoreCLI@2
  displayName: Build
  inputs:
    command: build
    projects: 'src/**/*.csproj'
    arguments: '--configuration $(buildConfiguration)'

- task: DotNetCoreCLI@2
  displayName: Pack
  inputs:
    command: pack
    packagesToPack: 'src/**/*.csproj'
    configuration: '$(buildConfiguration)'
    versioningScheme: byEnvVar
    versionEnvVar: packageVersion
    outputDir: '$(Build.ArtifactStagingDirectory)/packages'

- task: DotNetCoreCLI@2
  displayName: Push package
  inputs:
    command: push
    packagesToPush: '$(Build.ArtifactStagingDirectory)/packages/*.nupkg'
    nuGetFeedType: internal
    publishVstsFeed: '$(AZ_ARTIFACTS_FEED)'
    arguments: '--skip-duplicate'

Step 2 - variable group values - create variable group ado-shared-vars from the library option in pipelines

ado-shared-vars
├── AZ_ARTIFACTS_FEED = DemoProject/<name-of-your-feed>
└── AZURE_SERVICE_CONNECTION = <name-of-your-service-connection> # To be added later in demo 3. Skip for now

Step 3 - Create a feed
In Azure DevOps, go to your project, open Artifacts, then select Create Feed. Give the feed a name, choose project-scoped visibility

Grant feed contributor permissions to identities that look like -
- DemoProject Build Service (<Your-org-name>)
- Project Collection Build Service (Your-org-name) - you may need to search for the name in Add user/group

Create a pipeline and select the path of your pipeline and then run the pipeline.

```
## Demo 3 - Azure login
```
Step 1 - Service connection setup
In Azure DevOps, create a new Azure Resource Manager service connection and choose Workload identity federation with the manual flow. The documented manual process is: create the identity, create the draft service connection, copy Issuer and Subject identifier, add them as a federated credential in Azure, assign RBAC, and then verify/save the service connection.
RBAC roles - 
	•	Reader on subscription or resource group if you only want login with listing commands.
	•	Contributor only if you want to create/update Azure resources through pipeline

Step 2 - Add a variable to group var with the name AZURE_SERVICE_CONNECTION. Value must be what you defined in the name of service connection created above in step 1

Step 3 - add this to the existing pipeline 
- task: AzureCLI@2
  displayName: Azure login
  inputs:
    azureSubscription: '$(AZURE_SERVICE_CONNECTION)'
    scriptType: bash
    scriptLocation: inlineScript
    inlineScript: |
      az --version
      az account show
```