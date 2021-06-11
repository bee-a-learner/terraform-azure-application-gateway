
#---------------------------------------------------------
# RESOURCE GROUP
#---------------------------------------------------------

variable "public_ip_name" {
  default = ""
}

variable "public_ip_allocation_method" {
  default = ""
}

variable "public_ip_sku" {
  default = ""
}

variable "tags" {
    description = "(optional) describe your variable"
    default = {}
}

variable "application_gateway_name" {
    type = string
    description = "(optional) describe your variable"
    default = "appgateway-dev-01"
}
variable "location" {
    type = string
    description = "(optional) describe your variable"
    default = "westeurope"
}
variable "resource_group_name" {
    type = string
    description = "(optional) describe your variable"
    default = "rg-appgateway-dev-01"
}

#---------------------------------------------------------
# APPGW
#---------------------------------------------------------
variable "backend_address_pool" {
  description = "list of application gateway backend pool"
}
	
variable "backend_http_settings" {
  description = "list of application gateway backend http settings"
}

variable "frontend_port" {
  description = "list of application gateway frontend port"
  
}

variable "frontend_ip_configuration" {
   default = []
   description = "list of frontend ip configuration"
}

variable "gateway_ip_configuration" {
  description = "list of application gateway ip configuration"
}

variable "autoscale_configuration" {
  description = "list of autoscale configuration"
}	
	
variable "http_listener" {
    default = "list of http listener configuration"
}


variable "ssl_policy" {
  description = "(optional) define TLS settings if requires"
  default = []
}

variable "requires_identity" {
    type    = bool
    default = true
}

variable "user_managed_identity" {
   description    = "(optional) user manage identity Id, requires if 'requires_identity' field set to true"
   type           = list
}

variable "probe" {
  description = "(required) list of application gateway probe"
}

variable "use_probe_matching_conditions" {
  type = bool
  description = "(optional) set if gateway probe wants to use probe matching condition, in this case you need to provde value in 'http_response_status_codes' variable"
  default = false
}

variable "http_response_status_codes" {
  type = list
  description = "(optional) set if gateway probe wants to use probe matching condition, if requires to use then 'use_probe_matching_conditions' must be set to true"
  default = []
}

variable "request_routing_rule" {
  default = []
  description = "(optional) list of application gateway routing rule"
}

variable "url_path_maps" {
  default = []
  description = "(optional) One or more url_path_map blocks"
}

variable "sku" {
  description = "(required) applicatin gateway sku"
}

variable "ssl_certificate" {
   description = "(required) list applicatin gateway ssl_certificate"
}
#

variable "authentication_certificate" {
  description = "(optional) list applicatin gateway authentication_certificate"
  default = []
}

variable "trusted_root_certificate" {
  description = "(optional) list applicatin gateway trusted_root_certificate"
  default = []
}

variable "waf_configuration" {
  description = "(required) list applicatin gateway waf_configuration"
  default = []
}


variable "firewall_policy_id" {
  default = ""
}

variable "rewrite_rule_set" {
  default = null
}
#
variable "frontend_ip_configuration_name" {
  default = ""
  description = "(optional) application gateway frontend ip configuration, if not provided default name would be [app gateway name]-ip "
}