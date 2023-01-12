# Provisionning an AKS cluster

* Creating terraform.tf, main.tf
* Creating outputs.tf to get the necessary outputs (such as kube config)
* `terraform apply`
* `terraform output -raw kube_config > ~/.kube/config ` :  save the kube config certificate needed to authenticate to the cluster.

# Basic setup (modules/basic_setup)
We will use modules to do basic setups inside our cluster.
Declare our module in main.tf: 
```yaml
module "basic_setup" {
  source = "./modules/basic_setup"
} 
```
* `terraform init` (because be declared a new provider inside our module).
* `terraform apply`

## Using variables inside a module
Variable declaration is the same as in the main project (we declare the variables in the `variabes.tf`).
But the values needed to be passed in the module declaration in `main.tf` <br>
Example: passing a value for the variable 'environment' we declared in `modules/basic_setup/variables.tf` (we can see that we can do validations for the variables).
```yaml
module "basic_setup" {
  source      = "./modules/basic_setup"
  environment = "dev"
}
```
If we pass a value other than 'dev' or 'prod' we'll get an error (we can test this then `terraform valdiate`), since that we specified that they are the only accepted values.

## Pass the kube config dynamically
To avoid saving the kube_config under `~/.kube/config` (avoid manual interaction). We declare a `kubernetes provider`in `main.ts` (in the root project)  containing all the data from the kubernetes cluster created there and we pass it as a parameter in the module declaration. (informally: inside the module declaration, we told the module that the kubernetes provider it is waiting for is the kubernetes provider points on our declared kubernetes provider ).
## Getting outputs from the module to the root project
* Declare the outputs in modules/basic_setup/outputs.tf, for example namespace id:
```yaml
output "namespace_id" {
  description = "namsepace ID"
  value       = kubernetes_namespace.example.id
}
```
Now, get declare it as an output in `outputs.tf` in the root project:
```yaml
output "namespace_id" {
  description = "Namespace ID"
  value       = module.basic_setup.namespace_id  # MODULE.MODULE_NAME.OUTPUT_NAME
}
```

# GitOps
* Create a helm provider in `main.tf` (under the root project)
```yaml

```
