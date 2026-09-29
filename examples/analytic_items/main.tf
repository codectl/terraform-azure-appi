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

module "analytics" {
  source  = "codectl/law/azure"
  version = "~> 1.0"

  workspace = {
    name                = module.naming.log_analytics_workspace.name_unique
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name
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
    workspace_id        = module.analytics.workspace.id

    analytics_items = {
      request_volume_by_endpoint = {
        name    = "Request Volume by Endpoint"
        content = <<KQL
        requests
        | summarize RequestCount = count() by name
        | order by RequestCount desc
        KQL
        scope   = "shared"
        type    = "query"
      }

      failed_requests_by_status_code = {
        name    = "Failed Requests by Status Code"
        content = <<KQL
        requests
        | where success == false
        | summarize FailedRequests = count() by resultCode
        | order by FailedRequests desc
        KQL
        scope   = "shared"
        type    = "query"
      }

      average_server_response_time = {
        name    = "Average Server Response Time"
        content = <<KQL
        requests
        | summarize AvgResponseTime = avg(duration) by bin(timestamp, 1h)
        | order by timestamp asc
        KQL
        scope   = "shared"
        type    = "query"
      }
    }
  }
}
