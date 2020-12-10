# Configure provider with your Cisco ACI credentials
provider "aci" {
  version = "0.3.4"
  # Cisco ACI user name
  username = "admin"
  # Cisco ACI password
  password = "C1sco12345"
  # Cisco ACI URL
  url      = "https://10.10.20.14"
  insecure = true
}

# Variables
locals {
  vmm_vcenter        = "uni/vmmp-VMware/dom-My-vCenter"
  phys_db            = "uni/phys-phys"
}

# Tenant Definition
resource "aci_tenant" "terraform_tenant" {
  # Note the names cannot be modified in ACI, use the name_alias instead
  # The name becomes the distinguished named with the model, this is the reference name
  # The model can be deployed A/B if the name, aka the model, must change
  name        = "terraform_tenant"
  name_alias  = "tenant_for_terraform"
  description = "This tenant is created by terraform ACI provider"
}

# Networking Definition
resource "aci_vrf" "default" {
  tenant_dn              = "${aci_tenant.terraform_tenant.id}"
  name                   = "default"
  name_alias             = "default"
}

resource "aci_bridge_domain" "bd_for_subnet" {
  tenant_dn   = "${aci_tenant.terraform_tenant.id}"
  name        = "bd_for_subnet"
  description = "This bridge domain is created by terraform ACI provider"
  relation_fv_rs_ctx = "${aci_vrf.default.name}"
}

resource "aci_subnet" "demosubnet" {
  bridge_domain_dn                    = "${aci_bridge_domain.bd_for_subnet.id}"
  ip                                  = "10.0.0.1/16"
  scope                               = "private"
  description                         = "This subject is created by terraform"
}

# App Profile Definition
resource "aci_application_profile" "terraform_app" {
  tenant_dn  = "${aci_tenant.terraform_tenant.id}"
  name       = "terraform_app"
  name_alias = "demo_ap"
  prio       = "level1"
}

# EPG Definitions
resource "aci_application_epg" "web" {
  application_profile_dn  = "${aci_application_profile.terraform_app.id}"
  name                    = "web"
  name_alias              = "Nginx"
  relation_fv_rs_cons     = ["${aci_contract.web_to_app.name}", 
                             "${aci_contract.any_to_log.name}"]
  relation_fv_rs_dom_att  = ["${local.vmm_vcenter}"]
  relation_fv_rs_bd       = "${aci_bridge_domain.bd_for_subnet.name}"
}

resource "aci_application_epg" "app" {
  application_profile_dn  = "${aci_application_profile.terraform_app.id}"
  name                    = "app"
  name_alias              = "NodeJS"
  relation_fv_rs_prov     = ["${aci_contract.web_to_app.name}"]
  relation_fv_rs_cons     = ["${aci_contract.app_to_db.name}",
                             "${aci_contract.app_to_auth.name}",
                             "${aci_contract.any_to_log.name}"]
  relation_fv_rs_dom_att  = ["${local.vmm_vcenter}"]
  relation_fv_rs_bd       = "${aci_bridge_domain.bd_for_subnet.name}"
}

resource "aci_application_epg" "db_cache" {
  application_profile_dn  = "${aci_application_profile.terraform_app.id}"
  name                    = "db_cache"
  name_alias              = "DB_Cache"
  relation_fv_rs_prov     = ["${aci_contract.app_to_db.name}"]
  relation_fv_rs_cons     = ["${aci_contract.cache_to_db.name}",
                             "${aci_contract.any_to_log.name}"]
  relation_fv_rs_dom_att  = ["${local.vmm_vcenter}"]
  relation_fv_rs_bd       = "${aci_bridge_domain.bd_for_subnet.name}"
}
resource "aci_application_epg" "db" {
  application_profile_dn  = "${aci_application_profile.terraform_app.id}"
  name                    = "db"
  name_alias              = "MariaDB"
  relation_fv_rs_prov     = ["${aci_contract.cache_to_db.name}"]
  relation_fv_rs_cons     = ["${aci_contract.any_to_log.name}"]     
  relation_fv_rs_dom_att  = ["${local.phys_db}"]
  relation_fv_rs_bd       = "${aci_bridge_domain.bd_for_subnet.name}"
}
resource "aci_application_epg" "log" {
  application_profile_dn  = "${aci_application_profile.terraform_app.id}"
  name                    = "log"
  name_alias              = "Logstash"
  relation_fv_rs_prov     = ["${aci_contract.any_to_log.name}"]
  relation_fv_rs_dom_att  = ["${local.vmm_vcenter}"]
  relation_fv_rs_bd       = "${aci_bridge_domain.bd_for_subnet.name}"
}
resource "aci_application_epg" "auth" {
  application_profile_dn  = "${aci_application_profile.terraform_app.id}"
  name                    = "auth"
  name_alias              = "Auth"
  relation_fv_rs_prov     = ["${aci_contract.app_to_auth.name}"]
  relation_fv_rs_cons     = ["${aci_contract.any_to_log.name}"]
  relation_fv_rs_dom_att  = ["${local.vmm_vcenter}"]
  relation_fv_rs_bd       = "${aci_bridge_domain.bd_for_subnet.name}"
}

# Contract Definitions
resource "aci_contract" "web_to_app" {
  tenant_dn = "${aci_tenant.terraform_tenant.id}"
  name      = "web_to_app"
  scope     = "tenant"
}

resource "aci_contract" "app_to_db" {
  tenant_dn = "${aci_tenant.terraform_tenant.id}"
  name      = "app_to_db"
  scope     = "tenant"
}

resource "aci_contract" "app_to_auth" {
  tenant_dn = "${aci_tenant.terraform_tenant.id}"
  name      = "app_to_auth"
  scope     = "tenant"
}

resource "aci_contract" "cache_to_db" {
  tenant_dn = "${aci_tenant.terraform_tenant.id}"
  name      = "cache_to_db"
  scope     = "tenant"
}

resource "aci_contract" "any_to_log" {
  tenant_dn = "${aci_tenant.terraform_tenant.id}"
  name      = "any_to_log"
  scope     = "tenant"
}

# Subject Definitions
resource "aci_contract_subject" "only_web_secure_traffic" {
  contract_dn                  = "${aci_contract.web_to_app.id}"
  name                         = "only_web_secure_traffic"
  relation_vz_rs_subj_filt_att = ["${aci_filter.https_traffic.name}"]
}

resource "aci_contract_subject" "only_db_traffic" {
  contract_dn                  = "${aci_contract.app_to_db.id}"
  name                         = "only_db_traffic"
  relation_vz_rs_subj_filt_att = ["${aci_filter.db_traffic.name}"]
}

resource "aci_contract_subject" "only_auth_traffic" {
  contract_dn                  = "${aci_contract.app_to_auth.id}"
  name                         = "only_auth_traffic"
  relation_vz_rs_subj_filt_att = ["${aci_filter.https_traffic.name}"]
}

resource "aci_contract_subject" "only_log_traffic" {
  contract_dn                  = "${aci_contract.any_to_log.id}"
  name                         = "only_log_traffic"
  relation_vz_rs_subj_filt_att = ["${aci_filter.https_traffic.name}"]
}

resource "aci_contract_subject" "only_db_cache_traffic" {
  contract_dn                  = "${aci_contract.cache_to_db.id}"
  name                         = "only_db_cache_traffic"
  relation_vz_rs_subj_filt_att = ["${aci_filter.db_traffic.name}"]
}

# Contract Filters
## HTTPS Traffic
resource "aci_filter" "https_traffic" {
  tenant_dn = "${aci_tenant.terraform_tenant.id}"
  name      = "https_traffic"
}

resource "aci_filter_entry" "https" {
  filter_dn   = "${aci_filter.https_traffic.id}"
  name        = "https"
  ether_t     = "ip"
  prot        = "tcp"
  # Note using `443` here works, but is represented as `https` in the model
  # Using `https` prevents TF trying to set it to `443` every run
  d_from_port = "https"
  d_to_port   = "https"
}
## DB Traffic
resource "aci_filter" "db_traffic" {
  tenant_dn = "${aci_tenant.terraform_tenant.id}"
  name      = "db_traffic"
}

resource "aci_filter_entry" "mariadb" {
  filter_dn   = "${aci_filter.db_traffic.id}"
  name        = "mariadb"
  ether_t     = "ip"
  prot        = "tcp"
  d_from_port = "3306"
  d_to_port   = "3306"
}
