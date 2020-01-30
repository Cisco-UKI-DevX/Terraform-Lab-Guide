*This lab is part of a series of guides from the [Network Automation and Tooling workshop series](https://github.com/sttrayno/Network-Automation-Tooling)*

# Infrastructure as Code with Terraform - Crawl / Walk / Run

Terraform is an increasingly popular open-source infrastructure as code software tool built by HashiCorp. It enables administrators to define and provision manage infrastructure across multiple cloud and datacenter resources. Terraform takes an infrastructure as code approach by using using a high-level configuration language known as Hashicorp Configuration Language or JSON to define the resources. Terraform differs from traditional configuraiton management tools such as Ansible as it is known for keeping state, once you define your desired state Terraform looks to build your infrastucture then records its current state and always looks to maintain the desired state the use specifies

While Terraform has been increasingly used in the cloud space to provision infrastructure such as VMWare, AWS and Azure we're starting to see more and more usage of this with Cisco infrastructure with support today for ASA firewalls and Cisco ACI in the data centre (Application Centric Infrastructure) within these exercises we'll look to focus on how Terraform can be used to configure ACI and provision resources in todays enterprise IT environment.

## Exercise 0 - Installing Terraform

Terraform is supported across Windows, Linux/Unix and MacOS. The downloads for the latest version can be found from [here.](https://www.terraform.io/downloads.html)
Terraform is distributed as a single binary. Install Terraform by unzipping it and moving it to a directory included in your system's executable PATH. On Linux and MacOS systems you can do this through the command `$PATH` For more information on the install I'd recommend [this handy guide](https://www.vasos-koupparis.com/terraform-getting-started-install/)

To verify Terraform is installed use the command `Terraform` in the shell. Terraform should return a list of available commands.

![](images/terraform-install.gif)

To run these exercises you will need an instance of ACI. dcloud.cisco.com has a couple of instances of ACI that you can reserve and use in this lab we'll be using the "Cisco ACI 4.1 Automation v1" demo. Alternatively you can also use your own instance of ACI if you have one available or use the DevNet sandbox, the only drawback of using the sandbox is you cannot get direct API access to the ACI sim and must go through an RDP client to get access, which makes getting started a bit more convuluted, but feel free to use the sandbox if you'd prefer.

## Exercise 1 - Dipping our toe in the water, creating our first resources on ACI with Terraform

In this exercise we're going to look at understanding an example terraform config file thats defines the resources we're looking to privision. In this case our configuration file looks to provision a tenant, bridge domain, subnet, application profile and a couple of example Endpoint groupss related to the application. These are common tasks you'd look to do anytime your deploying a new application. 

It is important to note that within a single terraform configuration file we can configure resources on ACI, VMWare, AWS, Azure or any other infrastructure which Terraform has a provider for. This makes Terraform a very important tool for orchestrating the multiple parts of infrastructure that currently exist within enterprise environments, we'll look to cover these more advanced deployments as we go through the exercises but for now let's master the basics.

First thing you'll want to do is navigate to the examples/exercise1 folder within this project and have a look at the config.tf file. Open the file and have a look inside.

```Note: All Terraform configuration files will have the suffix .tf```

First off in the file you'll notice that we define the username, password and url of the ACI instance in order that Terraform can authenticate with ACI. We can authenticate through using a private key or through username or password as shown here, storing credentials in plain text isn't recommended but we'll make an exception and use it here so we can get up and running quickly. We'll cover other methods of authentication in later exercises. 

```
#configure provider with your cisco aci credentials.
provider "aci" {
  # cisco-aci user name
  username = "admin"
  # cisco-aci password
  password = "C1sco12345"
  # cisco-aci url
  url      = "https://198.18.133.200"
  insecure = true
}
```

Following the declaration of the ACI credentials the rest of the file looks to define the resources, in this initial configuration file you can see it defines a Tenant called "terraform_tenant", a bridge domain associated to that tenant and an example subnet. It then define an application profile for our "demo_ap" and 3 endpoint groups for our database, web and logic tiers for our 3 tier application. Study the file and make sure you understand it. If you're looking to understand more of the capabilities we have available from the ACI provider refer to the excellent documentation which exists on the Terraform [website](https://www.terraform.io/docs/providers/aci/index.html)

Before we can apply our state we must initialise Terraform. This will examine our config files and install the necessary providers, in this case ACI, this can be done by using the ```Terraform init``` command.

![](images/terraform-init.gif)

After Terraform is initialised all commands should now work. The next stage is to examine the changes that will be required to our infrastructure to implement our config files do this through excecuting the ```Terraform plan``` command.

![](images/terraform-plan.gif)

Examine the output of the command and look to understand it, if it has been sucessful it should list everything outlined in our configuration file as the infrastructure as it stands shouldn't have any of the config already applied and no current state exists. Terraform also provides a handy summary of how many adds, changes and destroys it will carry out when the testplan is executed. For example this scenario should outline:

```Plan: 7 to add, 0 to change, 0 to destroy.```

All thats left to do now we're happy with our changes that will be applied is to run the ```Terraform apply``` command, this will now go out and make the changes to our infrastructure that's been defined.

![](images/terraform-apply.gif)

Give the execution a few moments to run, it will ask you to type "yes" to confirm the changes that are about to happen. When its done you should get a nice confirmation at the bottom that the apply has been complete with 7 resources added, 0 changed and 0 destroyed. You can see from the output below that the resources are created sequentially as outlined in the configuration file. This is particuarly important in ACI as certain resources will have dependancies on others.

```
aci_tenant.terraform_tenant: Creating...
aci_tenant.terraform_tenant: Creation complete after 2s [id=uni/tn-tenant_for_terraform]
aci_application_profile.terraform_app: Creating...
aci_bridge_domain.bd_for_subnet: Creating...
aci_application_profile.terraform_app: Creation complete after 0s [id=uni/tn-tenant_for_terraform/ap-demo_ap]
aci_application_epg.application_epg2: Creating...
aci_application_epg.application_epg3: Creating...
aci_application_epg.application_epg1: Creating...
aci_bridge_domain.bd_for_subnet: Creation complete after 2s [id=uni/tn-tenant_for_terraform/BD-bd_for_subnet]
aci_subnet.demosubnet: Creating...
aci_subnet.demosubnet: Creation complete after 1s [id=uni/tn-tenant_for_terraform/BD-bd_for_subnet/subnet-[10.0.3.28/27]]
aci_application_epg.application_epg2: Creation complete after 3s [id=uni/tn-tenant_for_terraform/ap-demo_ap/epg-web_epg]
aci_application_epg.application_epg1: Creation complete after 3s [id=uni/tn-tenant_for_terraform/ap-demo_ap/epg-db_epg]
aci_application_epg.application_epg3: Creation complete after 4s [id=uni/tn-tenant_for_terraform/ap-demo_ap/epg-log_epg]
```

Lets now verify in ACI that the resources we requested have been created by following the animation below.

![](images/ACI-check.gif)

Congratuations, you've just completed your first exercise on using Terraform!

## Exercise 2 - Network as code, building a CI/CD pipeline with ACI and Terraform

After exercise 1 you should now have a good grasph on what Terraform is, how you can define your intent for the infrastructure and how it works with ACI.

An increasingly popular way to use Terraform today is through Terraform cloud. Terraform Cloud is an SaaS application that helps teams use Terraform together. It manages Terraform runs in a consistent and reliable environment, and includes ways to share state and secret data, access controls for approving changes to infrastructure, a private registry for sharing Terraform modules, detailed policy controls for governing the contents of Terraform configurations, and more. For more information on Terraform cloud please view the excellent documentation [here](https://www.terraform.io/docs/cloud/index.html).

### Step 1 - Create our repository on Github and Terraform cloud

### Step 2 - Configure your Terraform cloud workspace

### Step 3 - Create your Terraform config and build a configuration pipeline
