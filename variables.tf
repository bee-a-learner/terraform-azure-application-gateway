
#---------------------------------------------------------
# RESOURCE GROUP
#---------------------------------------------------------

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


variable "user_managed_identity" {
   description    = "(optional) user manage identity Id, requires if 'requires_identity' field set to true"
   type           = list
}

variable "probe" {
  description = "(required) list of application gateway probe"
}

variable "request_routing_rule" {
  default = []
  description = "(optional) list of application gateway routing rule"
}

variable "url_path_maps" {
  default = []
  description = "(optional) One or more url_path_map blocks"
}

variable "sku_name" {
  type  = string 
  description = "(required) applicatin gateway sku name"
}

variable "sku_tier" {
  type  = string 
  description = "application gateway sku tier"
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
  description = "firewall policy Id which can be associated with app gateway"
}

variable "rewrite_rule_set" {
  default = null
  description = "collection of rule set id"
}
