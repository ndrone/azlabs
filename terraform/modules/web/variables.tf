variable "admin_password" {}
variable "environment" {}
variable "resource_prefix" {}
variable "terraform_script_version" {}
variable "web_server_address_space" {}
variable "web_server_count" {}
variable "web_server_location" {}
variable "web_server_name" {}
variable "web_server_rg" {}
variable "web_server_subnets" {
  type = list(string)
}
