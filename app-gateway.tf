provider "azurerm" {
  features {}
  skip_provider_registration = true
}

#---------------------------------------------------------------------------------------------
#  read certificate data from keyvault
#---------------------------------------------------------------------------------------------

data "azurerm_key_vault" "keyvault" {
  for_each              = {for k, v in var.authentication_certificate: v.certificate_key => v }
  name                  = each.value.certificate_key_vault_name
  resource_group_name   = each.value.certificate_key_vault_resource_group_name
}

data "azurerm_key_vault_certificate" "cert" {
  for_each              = {for k, v in var.authentication_certificate: v.certificate_key => v }
  name                  = each.value.certificate_key
  key_vault_id          = data.azurerm_key_vault.keyvault[each.key].id
}


data "azurerm_key_vault" "trusted_cert_kv" {
  for_each              = {for k, v in var.trusted_root_certificate: v.certificate_key => v }
  name                  = each.value.certificate_key_vault_name
  resource_group_name   = each.value.certificate_key_vault_resource_group_name
}

data "azurerm_key_vault_certificate" "trusted_cert" {
  for_each              = {for k, v in var.trusted_root_certificate: v.certificate_key => v }
  name                  = each.value.certificate_key
  key_vault_id          = data.azurerm_key_vault.trusted_cert_kv[each.key].id
}

#---------------------------------------------------------------------------------------------
#  create application gateway public ip
#---------------------------------------------------------------------------------------------

# Public Ip
resource "azurerm_public_ip" "appgw_public_ip" {
  name                = format("%s-pip",var.application_gateway_name)
  resource_group_name = var.resource_group_name
  location            = var.location
  
  allocation_method   = var.sku_tier == "Standard" ? "Dynamic" : "Static"
  sku                 = var.sku_tier == "Standard" ? "Basic" : "Standard"

  tags = var.tags
}

# Create Azure Application Gateway


resource "azurerm_application_gateway" "app_gateway" {
  name                = var.application_gateway_name
  resource_group_name = var.resource_group_name
  location            = var.location
  
  # app gateway SKU
    sku{
            name     = var.sku_name
            tier     = var.sku_tier
      }
  
  
  # following settings configures firewall policy with application gateway
  firewall_policy_id = var.firewall_policy_id ==""?null : var.firewall_policy_id

  # app gateway standard WAF setting, applicable if firewall policy Id not configured
  dynamic "waf_configuration"  {
    for_each =  var.waf_configuration #var.firewall_policy_id == ""  ?: []
      content{
          #  name                     = waf_configuration.value.name
            enabled                  = lookup(waf_configuration.value,"enabled",false)
            file_upload_limit_mb     = lookup(waf_configuration.value,"file_upload_limit_mb",30)
            firewall_mode            = lookup(waf_configuration.value,"firewall_mode","Detection")
            max_request_body_size_kb = lookup(waf_configuration.value,"max_request_body_size_kb",128)
            request_body_check       = lookup(waf_configuration.value,"request_body_check",true)
            rule_set_type            = lookup(waf_configuration.value,"rule_set_type","OWASP")
            rule_set_version         = lookup(waf_configuration.value,"rule_set_version", "3.1")
      }
  }

  # Application gateway auto-scale confguration
  dynamic "autoscale_configuration" {
    for_each = var.autoscale_configuration
    content{
        max_capacity = autoscale_configuration.value.max_capacity
        min_capacity = autoscale_configuration.value.min_capacity
    }
  }

  # One or more Backend address pool
  dynamic "backend_address_pool"  {
    for_each = var.backend_address_pool
    content{
      name         = backend_address_pool.value.name
      ip_addresses = backend_address_pool.value.ip_addresses
    }
  }

  # One or more Backend http settings configuration
  dynamic "backend_http_settings"  {
    for_each = var.backend_http_settings
    content{
        cookie_based_affinity               = lookup(backend_http_settings.value,"cookie_based_affinity","Disabled")
        host_name                           = lookup(backend_http_settings.value,"pick_host_name_from_backend_address",false) == true? null: backend_http_settings.value.host_name
        name                                = backend_http_settings.value.name
        pick_host_name_from_backend_address = lookup(backend_http_settings.value,"pick_host_name_from_backend_address",false)
        port                                = lookup(backend_http_settings.value,"port",443)
        probe_name                          = backend_http_settings.value.probe_name #"backend-compute-probe"
        protocol                            = lookup(backend_http_settings.value,"protocol","Http") #"Https"
        request_timeout                     = lookup(backend_http_settings.value,"request_timeout",20)
        trusted_root_certificate_names      = lookup(backend_http_settings.value,"trusted_root_certificate_names",[])

        dynamic "authentication_certificate" {
            for_each = lookup(backend_http_settings.value,"authentication_certificate",[])
            content {
                  name         = authentication_certificate.value.name
            }
        }
    }
  }


  # Application gateway Frontend IP configuration
 frontend_ip_configuration  {
        name                          = format("%s-%s",var.application_gateway_name,"pip") 
        public_ip_address_id          = azurerm_public_ip.appgw_public_ip.id
  }
  

  # One or more frontend ip configuration
dynamic "frontend_ip_configuration"  {
    for_each = var.frontend_ip_configuration
    content{
        name                          = frontend_ip_configuration.value.name
        public_ip_address_id          = lookup(frontend_ip_configuration.value,"public_ip_address_id",null)
        private_ip_address            = lookup(frontend_ip_configuration.value,"private_ip_address",null)   
        subnet_id                     = lookup(frontend_ip_configuration.value,"subnet_id ",null)    
        private_ip_address_allocation = lookup(frontend_ip_configuration.value,"private_ip_address_allocation","Dynamic")                   
    }
  }

  # One or more frontend port configuration
dynamic "frontend_port"  {
    for_each = var.frontend_port
    content{
        name  = frontend_port.value.name
        port  = lookup(frontend_port.value,"port",443)                
    }
  }

  # One or more gateway ip configuration
dynamic "gateway_ip_configuration"  {
    for_each = var.gateway_ip_configuration
    content{
        name       = gateway_ip_configuration.value.name
        subnet_id  = gateway_ip_configuration.value.subnet_id             
    }
  }

  # (optional) define TLS settings if requires
  dynamic "ssl_policy"{
    for_each = var.ssl_policy
    content{
              policy_type    = ssl_policy.value.policy_type
              policy_name    = ssl_policy.value.policy_name
      }
  }     


  # One or more http listener settings configuration
  dynamic "http_listener"  {
      for_each = var.http_listener
      content{
          name                            =  http_listener.value.name
          frontend_ip_configuration_name  = http_listener.value.frontend_ip_configuration_name
          frontend_port_name              = http_listener.value.frontend_port_name
          host_name                       =  lookup(http_listener.value,"host_name",null)  
          host_names                      =  lookup(http_listener.value,"host_names",[])   
          protocol                        =  lookup(http_listener.value,"protocol","Http")
          require_sni                     =  lookup(http_listener.value,"require_sni",false)
          ssl_certificate_name            =  lookup(http_listener.value,"ssl_certificate_name",null)
          firewall_policy_id              =  lookup(http_listener.value,"firewall_policy_id",null)
      }
    }

  # application gateway manage Identity
  dynamic "identity"  {
      for_each = var.user_managed_identity
      content{
         identity_ids = var.user_managed_identity
          type        = "UserAssigned"
      }
  }

  # One or more probe configuration

  dynamic "probe"  {
      for_each = var.probe
      content{
         
            host                                      = lookup(probe.value,"pick_host_name_from_backend_http_settings",false) == true? null: probe.value.host
            name                                      = probe.value.name
            pick_host_name_from_backend_http_settings = lookup(probe.value,"pick_host_name_from_backend_http_settings",false)
            port                                      = lookup(probe.value,"port",null)

            interval                                  = lookup(probe.value,"interval",30)
            minimum_servers                           = lookup(probe.value,"minimum_servers",0)
            path                                      = probe.value.path
          #  port                                      = 0
            protocol                                  = lookup(probe.value,"protocol","Http")
            unhealthy_threshold                       = lookup(probe.value,"unhealthy_threshold",3)
            timeout                                   = lookup(probe.value,"timeout",180)
            match {
                status_code = lookup(probe.value,"use_probe_matching_conditions",false)==false? []: lookup(probe.value,"http_response_status_codes",[])
            }
      }
    }

  # One or more app gateway  route rule configuration
  dynamic "request_routing_rule"  {
        for_each = var.request_routing_rule
        content{
          
              name                        = request_routing_rule.value.name
              backend_address_pool_name   = lookup(request_routing_rule.value,"redirect_configuration_name",null)!=null?null: lookup(request_routing_rule.value,"backend_address_pool_name",null)
              backend_http_settings_name  = lookup(request_routing_rule.value,"redirect_configuration_name",null)!=null?null: lookup(request_routing_rule.value,"backend_http_settings_name",null)
              http_listener_name          = request_routing_rule.value.http_listener_name
              rule_type                   = lookup(request_routing_rule.value,"rule_type","Basic")
              rewrite_rule_set_name       = lookup(request_routing_rule.value,"rewrite_rule_set_name",null)
              url_path_map_name           = lookup(request_routing_rule.value,"url_path_map_name",null)
        }
  }

  # One or more URL path map of app gateway this must be linked with routing_rule 
  dynamic "url_path_map"  {
      for_each = var.url_path_maps
        content {
                    default_backend_address_pool_name   =  lookup(url_path_map.value,"backend_address_pool_name",null) #"sinkpool"
                    default_backend_http_settings_name  =  lookup(url_path_map.value,"backend_http_settings_name",null) #"api-http-setting"
                    name                                =  url_path_map.value.name  #"api-rule"
                    
                    default_redirect_configuration_name =  lookup(url_path_map.value,"redirect_configuration_name",null) #"sinkpool"
                    default_rewrite_rule_set_name       =  lookup(url_path_map.value,"rewrite_rule_set_name",null) #"api-http-setting"

                    dynamic "path_rule"  {
                            for_each = lookup(url_path_map.value,"path_rules",[])
                            content {
                                      name                       = path_rule.value.name
                                      backend_address_pool_name  = lookup(path_rule.value,"backend_address_pool_name",null) # "uatbepool"
                                      backend_http_settings_name = lookup(path_rule.value,"backend_http_settings_name",null) #"api-http-setting"
                                      
                                      paths                      = path_rule.value.paths # ["/external/*",]
                                      redirect_configuration_name= lookup(path_rule.value,"redirect_configuration_name",null)
                                }
                        }
            }
    }
  # One or more app gateway  route rule set 
  dynamic "rewrite_rule_set"  {
        for_each = var.rewrite_rule_set !=null ? [1]:[]
        content{
              name  = var.rewrite_rule_set.name
              dynamic "rewrite_rule"  {
                  for_each = lookup(var.rewrite_rule_set,"rewrite_rules",[])
                content{
                    name          = rewrite_rule.value.name
                    rule_sequence = rewrite_rule.value.rule_sequence
                     dynamic "response_header_configuration" {
                        for_each = lookup(rewrite_rule.value,"response_header_configuration",[])
                        content{
                          header_name  = response_header_configuration.value.header_name
                          header_value = response_header_configuration.value.header_value
                        }
                     }

                     dynamic "request_header_configuration" {
                        for_each = lookup(rewrite_rule.value,"request_header_configuration",[])
                        content{
                          header_name  = request_header_configuration.value.header_name
                          header_value = request_header_configuration.value.header_value
                        }
                     }
              }
            }
    }
  }

  dynamic "authentication_certificate"  {
    for_each = var.authentication_certificate
      content{
            name    = authentication_certificate.value.certificate_name
            data    = data.azurerm_key_vault_certificate.cert[authentication_certificate.value.certificate_key].certificate_data_base64
      }
  }

  # One or more app gateway SSL certificate configuration
  dynamic "ssl_certificate"  {
    for_each = var.ssl_certificate
      content{
            name                = ssl_certificate.value.name
            key_vault_secret_id = lookup(ssl_certificate.value,"keyvault_certificate_secret_id",null)
      }
  }

  # One or more app gateway trusted certification configuration
  dynamic "trusted_root_certificate"  {
    for_each = var.trusted_root_certificate
      content{
            name    = trusted_root_certificate.value.certificate_name
            data    = data.azurerm_key_vault_certificate.trusted_cert[trusted_root_certificate.value.certificate_key].certificate_data_base64
      }
  }

  tags = var.tags

}
