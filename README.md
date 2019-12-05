# Infrastructure as Code with Terraform - Crawl / Walk / Run

Terraform is an increasingly popular open-source infrastructure as code software tool built by HashiCorp. It enables administrators to define and provision a datacenter and cloud infrastructure using a high-level configuration language known as Hashicorp Configuration Language or JSON.

While Terraform has been increasingly used in the cloud space to provision infrastructure such as AWS and Azure we're starting to see more and more usage of this with Cisco tools including ASA and primarily ACI.

## Exercise 0 - Installing Terraform

Terraform is supported across Windows, Linux/Unix and MacOS. The downloads for the latest version can be found from [here.](https://www.terraform.io/downloads.html)
Terraform is distributed as a single binary. Install Terraform by unzipping it and moving it to a directory included in your system's executable PATH. On Linux and MacOS systems you can do this through the command `$PATH` For more information on the install I'd recommend [This handy guide](https://www.vasos-koupparis.com/terraform-getting-started-install/)

To verify Terraform is installed use the command `Terraform` in your shell. Terraform should return a list of available commands.

![](images/terraform-install.gif)

To run these exercises you will need an instance of ACI running. dcloud.cisco.com has a couple of instances of ACI that you can reserve and use in this lab we'll be using the "Cisco ACI 4.1 Automation v1" demo which can be reserved and used. Alternatively you can also use your own instance of ACI if you have one available.

## Exercise 1 - Dipping our toe in the water, creating our first resources on ACI with Terraform

