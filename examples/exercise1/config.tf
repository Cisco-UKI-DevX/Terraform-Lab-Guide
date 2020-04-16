# Configure provider with your Cisco ACI credentials
provider "aci" {
  # Cisco ACI user name
  username = "admin"
  # Cisco ACI password
  password = "C1sco12345"
  # Cisco ACI URL
  url      = "https://198.18.133.200"
  insecure = true
}

resource "aci_tenant" "terraform_tenant" {
  name        = "terraform_tenant"
  name_alias  = "tenant_for_terraform"
  description = "This tenant is created by terraform ACI provider"
}

resource "aci_bridge_domain" "bd_for_subnet" {
  tenant_dn   = "${aci_tenant.terraform_tenant.id}"
  name        = "bd_for_subnet"
  description = "This bridge domain is created by terraform ACI provider"
  mac         = "00:22:BD:F8:19:FF"
}

resource "aci_subnet" "demosubnet" {
  bridge_domain_dn                    = "${aci_bridge_domain.bd_for_subnet.id}"
  ip                                  = "10.0.3.28/27"
  scope                               = "private"
  description                         = "This subject is created by terraform"
  ctrl                                = "unspecified"
  preferred                           = "no"
  virtual                             = "yes"
}

resource "aci_application_profile" "terraform_app" {
  tenant_dn  = "${aci_tenant.terraform_tenant.id}"
  name       = "terraform_app"
  name_alias = "demo_ap"
  prio       = "level1"
}

resource "aci_application_epg" "application_epg1" {
    application_profile_dn  = "${aci_application_profile.terraform_app.id}"
    name                          = "db_epg"
  }

resource "aci_application_epg" "application_epg2" {
    application_profile_dn  = "${aci_application_profile.terraform_app.id}"
    name                          = "web_epg"
  }

resource "aci_application_epg" "application_epg3" {
    application_profile_dn  = "${aci_application_profile.terraform_app.id}"
    name                          = "log_epg"
  }
