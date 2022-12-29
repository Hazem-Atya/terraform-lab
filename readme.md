# 1- [Installing terraform](https://developer.hashicorp.com/terraform/downloads?product_intent=terraform) 
Terraform is a provisionning tool (IAC).  <br>
The language used by terraform is HCL.
# 2- Provisioning a VM on azure

* [Copying definition from docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine)
*  Creating main.tf and terraform.tf (configuring the required providers (terraform.tf) and provisioning the vm (main.tf)) <br>
*  structure of a resource creation in a .tf file:
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
* `terraform plan`: change set (what will happen if we apply the changes)
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
If we want to use atrributes of this resrouce: `data.azurerm_resource_group.dev.name` (by default, writing the resource type means that we're going to use a resrouce that's managed by terraform, if we want to use a resource we got from using ``data`` we have to specify that before the resource type).<br>




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

# 4- Variables
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
#### <b>Option 1</b>
When we use terraform.apply, we will be asked to type the used variables, which is kinda tidious.
#### <b>Option 2</b>
Exporting the variables `export TF_VAR_VARIALBE_NAME=value`, <br> e.g. `export TF_VAR_resource_group_name=example-resources` => When we do `terraform.apply` we won'tbe asked to type the values of the vars (it will automatically read from the env variables).
#### <b>Option 3</b>
`terraform apply -var resource_group_name=example-resources`
#### <b>Option 4</b>
Creating a file named `terraform.tfvars` that contains a key value pairs
```
resource_group_name = "example-resources"
```
# 5- Outputs
OUtputs some values from our resources.
We first create a file named `output.tf`, where we specify the desired outputs (for example athe public ip address)
```
output "public_ip"{
    value= azurerm_public_ip.my_public_ip.ip_address
}
```
When we do `terraform apply`, we will get the list of the outputs. <br>
We can also display the outputs using the command `terraform output` or displaying a signle value by `terraform output public_ip`

# 6- Generate a key pair using terraform
[private tls key ](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key)
* Key generation
```
resource "tls_private_key" "new-key" {
  algorithm   = "RSA"
}
```
* Passing the <b>public</b>key to `admin ssh key` (inside vm creation):
 ```
    public_key = tls_private_key.new-key.public_key_openssh
 ```
* Output the <b>private</b> key (output.tf)
```
output "private_key"{
    value = tls_private_key.new-key.private_key_pem
    sensitive = true
}
```
<b>Note:</b>senstitive tells terraform not to output the value in the terminal unless asked explicitly by the user. `terraform output -raw private_key`.
<b>Note:</b>The private key is stored in the tfstate.

# 3- Terraform state
To track the state of the creation (what was created, what should be created,..), terraform uses a json file `terraform.tfstate` which is stored locally by default. <br>
However, if we want to collaborate in the same terraform project, the state file should be shared. One of the ways of sharing the file is using ``terraform backend``. In azure this the available backend is [blob storage](https://developer.hashicorp.com/terraform/language/settings/backends/azurerm). <br>
This backend supports <b>state locking</b> (using a semaphore that let's only one user edits the state: one apply at the same time).

## How does terraform work in the backgound?
When we do ``plan`` or ``apply`` terraform compares the content of the .tf files and comapres them it the state:
* If the HCL code in the .tf files is the same as in the state file => No action is needed
* If a resource exists in the .tf code and does not exist in the state => creation
* If a resource exists in the state but it's no longer existing in the HCL code => deletion

## Terraform azurerm backend
* Create a resource group `sensitive-data` from web portal.
* Create a storage account from teh web portal 
* Create a container inside the storage account
* Add the backend block in ``terraform.tf```:
```
  backend "azurerm" {
    resource_group_name  = "sensitive-data"
    storage_account_name = "laykidi"
    container_name       = "infra-state"
    key                  = "dev.terraform.tfstate"
  }
```
* After running `terraform init`, our `terraform.tfstate` file will be moved to the container inside the storage account. (the local file will become empty)
NB: Since the state file contains all data about our resources such as private keys, it's a good practice to dedicate to put it in a storage account that belongs to a resource group which is not public (accessbile only by devops  engineers foe example).

# Terraform provisioners
You can use provisioners to model specific actions on the local machine or on a remote machine in order to prepare servers or other infrastructure objects for service.<br> 
Informally, executes a definition on a resource when this resource is created and ready. (for e.g. executing a command remotely, copying a file from one location to another,.. )<br>
E.g: Connecting to the created vm via ssh and executing a simple bash command: (this code was added inside teh vm definition in main.tf):
```
  connection {
    type        = "ssh"
    user        = "adminuser"
    private_key = tls_private_key.new-key.private_key_openssh
    host        = self.public_ip_address
  }
  provisioner "remote-exec" {
    inline = [
      "bash -c \"echo 'hello Hazem!' > ~/file.txt\""
    ]
  }
```
* If we just apply, our provisioner won't be executed since the resource (vm) is already marked as created: 
  * `terraform taint azurerm_linux_virtual_machine.example`: mark our resource for deletion (this will force the resrouce to be recreated in the next apply), the syntax of the taint command is `terraform taint RESOURCE_TYPE.RESOURCE_NAME`.
  * `terraform apply`, we will get the following output `  # azurerm_linux_virtual_machine.example is tainted, so must be replaced`.
  * We can output our private key in order to manually ssh to the machine and verify that our `remote-exec` worked. 