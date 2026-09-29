module "naming" {
  source  = "codectl/naming/azure"
  version = "~> 0.1"

  suffix = ["demo", "dev"]
}

module "regions" {
  source  = "codectl/locations/azure"
  version = "~> 1.0"

  location = {
    primary = "westeurope"
  }
}

module "rg" {
  source  = "codectl/rg/azure"
  version = "~> 1.0"

  groups = {
    demo = {
      name     = module.naming.resource_group.name_unique
      location = module.regions.location.primary.name
    }
  }
}

module "appi" {
  source  = "codectl/appi/azure"
  version = "~> 1.0"

  insights = {
    name                = module.naming.application_insights.name
    resource_group_name = module.rg.groups.demo.name
    location            = module.rg.groups.demo.location
    application_type    = "web"

    api_keys = {
      read_only_key = {
        name             = "ReadOnlyKey"
        read_permissions = ["api"]
      }

      write_annotations_key = {
        name              = "WriteAnnotationsKey"
        write_permissions = ["annotations"]
      }
    }
  }
}
