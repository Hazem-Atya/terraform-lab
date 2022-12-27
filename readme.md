# 1- [Installing terraform](https://developer.hashicorp.com/terraform/downloads?product_intent=terraform) 

# 2- Provisioning a VM on azure

* [Copying definition from docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine)
*  Creating main.tf and terraform.tf (configuring the required providers (terraform.tf) and provisioning the vm (main.tf)) <br>
*  structure of a resource creation the a .tf file:
  ```terraform
  resource "resrouce type" "resource name"{
    name = "name of the resource in the cloud"
    resource configuration 
  }
  ```
Note: the name of the resource in the terraform project is not the same as the name of the resource name in azure.

* `terraform init`: initializes a working directory containing configuration files and installs plugins for required providers (terraform detects the needed installation from the .tf files). We can use more than one cloud provider.<br>
You can browse the different providers in the [official docs](https://registry.terraform.io/browse/providers).
* `terraform version`: Displays the version of Terraform and all installed plugins.
* `terraform fmt`: Formatting the .tf files.
* `az login` 
* `ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -q -N ''`: generate a key locally (if we don't possess one)
* `terraform plan`
* `terraform validate`
* `terraform apply` <br>

<b>Important note</b>: The order of resource creating is not the same as they appear in the .tf file. Terraform constructs a dependency graph between the resources to know the order in which they will be created. (a resource is dependant on another one if it uses one or more of its attributes<br>
```resource "azurerm_virtual_network" "example" {
  name                = "example-network" # name in the cloud
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}
```
In the previous example, the virtual network depends on the resource group. <br>
Independent resources can be created in parallel.
If we want to specify explicity that a resource depends on another resrouce we can use `depends on` block. 
```
resource "azurerm_subnet" "example" {
  depends_on = [
    azurerm_virtual_network.example
  ]
  ........
}
```
<br>

* If we want to use a resource that already exists in the cloud we can use `data` instead of `resource` (this resource lifecycel is not managed by terraform), e.g: <br>
```
data "azurerm_resource_group" "dev"{
  name = "my existing resource group"
}
```
If we want to use atrributes of this resrouce: `data.azurerm_resource_group.dev.name` (by default, writing the resource type means that we're going to use a resrouce that's managed by terraform, if we want to use a resource we got from using ``data`` wehave to specify that before the resource type).<br>




### <b>Important note: </b> 

Terraform does <b>NOT</b> support rollback. If an error occurs terraform stops without rollback :(.
## Creating many VMs:
We just need to add these config in the resource definition: (we also need to create the same number of network interfaces)
```
  count = = 20
  name                = "example-machine ${count.index}"
  network_interface_ids = [
    azurerm_network_interface.example[count.index].id,
  ]
```
Another solution is using count in the creation of the network interfaces and ``for each`` when we create the vms.
# Terraform state
To track the state of the creation (what was created, what should be created,..), terraform uses a json file `terraform.tfstate` which is stored locally by default. <br>
However, if we want to collaborate in the same terraform project, the state file should be shared. One of the ways of sharing the file is using ``terraform backend``. In azure this the available backend is [blob storage](https://developer.hashicorp.com/terraform/language/settings/backends/azurerm). <br>
This backend supports <b>state locking</b> (using a semaphore that let's only one user edits the state: one apply at the same time).

# Variables
### Defining a variable
```
variable "resource_group_name"{
type= string
description = "resource group name"
}
```
### Using a variable
```
resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = "West Europe"
}
```
#### <br>Option 1
When we use terraform.apply, we will be asked to type the used variables, which is kinda tidious. <br>
#### <br>Option 2
Exporting the variables `export TF_VAR_VARIALBE_NAME=value`, <br> e.g. `export TF_VAR_resource_group_name=example-resources` => We we do `terraform.apply` we won'tbe asked to type the values of the vars (they will automatically read from the env variables).
#### <br>Option 3
`terraform apply -var resource_group_name=example-resources`
#### <br>Option 4
Creating a file named `terraform.tfvars` that contains a key value pairs
```
resource_group_name = "example-resources"
```
