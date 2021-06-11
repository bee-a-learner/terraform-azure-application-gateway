
# Azure Application Gateway
Azure application gateway terraform code


  #---------------------------------------------------------
  ## Application gateway parameter sample
  #---------------------------------------------------------

    ### application gateway resource group name
    resource_group_name = "rg-appgateway-dev"

    ### application gateway location
    location            = "westeurope"

    ### application gateway name
    app_gateway_name                    = "dev-app-gateway"
    
    ### list of application gateway backend pool

    ```
    app_gateway_backend_address_pool    = [
            {
                #### backend pool ip address
                ip_addresses = [
                    "10.238.0.165",
                ]

                #### backend pool name
                name         = "apim-be-pool"
            },
            {
                ip_addresses = []
                name         = "sinkpool"
            }
        ]

    ```


    ### list of application gateway http settings

    ```

    app_gateway_backend_http_settings = [ 
        {
            # (Optional) cookie_based_affinity 
            cookie_based_affinity               = "Disabled"

            # (Optional) set true if host name provided 
            pick_host_name_from_backend_address = false

            # (Optional) host name    
            host_name                           = "dev-portal.contoso.com"

            # (required) http settings name
            name                                = "portal-http-setting"
            
            # (required) http settings port default port is 443
            port                                = 443

            # (required) http settings probe name (must match the probe name which is set below)
            probe_name                          = "portal-probe"

            # (Optional) protocol name default is Https    
            protocol                            = "Https"

            # (Optional) request timeout default is 20    
            request_timeout                     = 180

            # (Optional) list(string) of trusted root certificate, must match with list of trusted_root_certificate defined below    
            trusted_root_certificate_names      = [
                        "wild-card-cert"
                ]

            # (Optional) list(string) of authentication certificate, must match with list of authentication_certificate defined below    
             authentication_certificate =[]
        }
    ]

    ```

    ### application gateway frontend port

    ```
    # (Optional) list of frontend port    
    app_gateway_frontend_port =[

        {
            #### (Optional) list of frontend port name   
            name = "frontend-ip-port-443"

            #### (Optional) list of frontend port
            port = 443
        }
    ]

    ```

    #application gateway ip configuration
	
    ```
	app_gateway_gateway_ip_configuration = [
        {
            ### gateway ip configuration name
            name      = "appgwipcfg"

            ### gateway ip configuration subnet name
            subnet_id = "/subscriptions/[subscriptionid]/resourceGroups/[resource_group_name]/providers/Microsoft.Network/virtualNetworks/[vnet_name]/subnets/[subnet_name]"
        }
    ]

    ```

    #(optional) application gateway ip configuration

    app_gateway_autoscale_configuration =  [
        {
            max_capacity = 5
            min_capacity = 0
        }
    ]

    #(optional) application gateway ssl policy
    
    app_gateway_ssl_policy  = [
        {
            policy_type    = "Predefined"
            policy_name    = "AppGwSslPolicy20170401S"
        }
    ]

    # (Required) list of application gateway http listner block

    ```
    app_gateway_http_listener=[ 
            {
                # (requires) application gateway configuration name
                frontend_ip_configuration_name  = "appgw-dev-pip"

                # (requires) application gateway port name

                frontend_port_name              = "frontend-ip-port-443"

                # (optional) list of application gateway one or more host name
                host_names                      = []

                # (optional) application gateway one or more host name
                host_name                       = "dev-api.contoso.com"

                # (optional) application gateway http_listener name
                name                            = "api-listener"

                # (optional) application gateway portocol
                protocol                        = "Https"

                # (optional) application gateway requires_sni, default false
                require_sni                     = true

                # (optional) application gateway ssl_certificate_name, should match from the list of ssl cert
                ssl_certificate_name            = "wild-card-ssl"

                #firewall_policy_id              ="/subscriptions/[subscriptionsId]/resourceGroups/[resourceGroups_name]/providers/Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies/[policy_name]"
            }
        ]

    ```

    # User manage identity this is requires if app gateway certificate requires to manage from keyvault, 
    #[NOTE] :: user manage identity must have get certificate/secret access to the keyvault where the certificates are stored

    app_gateway_user_managed_identity = ["/subscriptions/[subscriptionsId]/resourceGroups/[resourceGroups_id]/providers/Microsoft.ManagedIdentity/userAssignedIdentities/[identity_name]"]

    # (optional) list application gateway probe

    ```
    app_gateway_probe = [
                {
                    # (reuqires) host
                    host                                      = "dev-api.contoso.com"
                    # (reuqires) probe name
                    name                                      = "api-probe"

                    # (reuqires) probe path
                    path                                      = "/status-0123456789abcdef"

                    # (optional) probe protocol default is Https
                    protocol                                  = "Https"

                    # (option) probe matching condition, default is false
                    use_probe_matching_conditions             = true

                    # (option) if use_probe_matching_conditions set to true the status_codes, list requires
                    http_response_status_codes                = ["200-399"]
                }
        ]

    ```
    # application gateway routing rules collection

    app_gateway_request_routing_rule = [ 
            {
                # http listener name
                http_listener_name         = "api-listener"
                name                       = "api-rule"
                rule_type                  = "PathBasedRouting",
                url_path_map_name          = "api-rule-path-map"
            },
            {
                backend_address_pool_name  = "apim-be-pool"
                backend_http_settings_name = "management-http-setting"
                http_listener_name         = "management-listener"
                name                       = "management-rule"
                rule_type                  = "Basic"
            }
        ]

    app_gateway_url_path_map = [
        
        {
            backend_address_pool_name                       = "sinkpool"
            backend_http_settings_name                      = "api-http-setting"
            name                                            = "api-rule-path-map"
            path_rules =[
                            {
                                backend_address_pool_name   = "apim-be-pool"
                                backend_http_settings_name  = "api-http-setting"
                                name                        = "external"
                                paths                       = [
                                    "/external/*",
                                ]
                            }
                        ]   
        }
        
    ]

    app_gateway_app_gateway_sku = [{
        capacity = 0
        name     = "WAF_v2"
        tier     = "WAF_v2"
    }]

    app_gateway_ssl_certificate = [ 
    {
        name                            = "wild-card-cert"
        keyvault_certificate_secret_id  = "https://[keyvault].vault.azure.net/secrets/[secret_name]/secret_id"
       
    }]

    app_gateway_trusted_root_certificate = [ 
        #  { 
        #     certificate_name                            = "wild-card-authentication-cert"
        #     certificate_key                             = "wildcard-cert"
        #     certificate_key_vault_name                  = "keyvault_name"
        #     certificate_key_vault_resource_group_name   = "keyvault_resource_group_name"
        # }
    ]

    app_gateway_authentication_certificate = [
       
    ]

    app_gateway_waf_configuration = [
         {
            enabled                  = true
            file_upload_limit_mb     = 100
            firewall_mode            = "Detection"
            max_request_body_size_kb = 128
            request_body_check       = true
            rule_set_type            = "OWASP"
            rule_set_version         = "3.1"
        }
    ]

    app_gateway_public_ip_allocation_method   = "Static"
    app_gateway_public_ip_sku                 = "Standard"
    app_gateway_public_ip_name                = "appgateway-dev-pip01"


    #  Tags 
     tag = {
            Resource_Type       = "Application"
            Data_Classification = "Standard"
        }




  terraform init

  terraform plan

 

![azure-application-gateway](https://user-images.githubusercontent.com/67486994/121694847-69a7c180-cac2-11eb-8c5e-fe226fd3033a.png)
