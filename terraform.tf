terraform {
  required_version = "~>1.3.6"
  required_providers {
    azurerm = {
      # issuer of the provider 
      source  = "hashicorp/azurerm"
      version = "~>3.37.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "sensitive-data"
    storage_account_name = "laykidi"
    container_name       = "infra-state"
    key                  = "dev.terraform.tfstate"
  }
}


# configuration of the provider, we can authenticate here but it's not a good practice (since the code is shared and
# we want everyone to authenticate using their credentials )
provider "azurerm" {
  features {}
}
