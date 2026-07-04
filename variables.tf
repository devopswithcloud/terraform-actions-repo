variable "project_id" {
  description = "The ID of the GCP project."
  type        = string
}

variable "region" {
  description = "The GCP region to deploy resources in."
  type        = string
  default     = "us-central1"
}


variable "local_vpc_name" {
    description = "The name of the VPC to create."
    type        = string
}

variable "local_subnet_name" {
    description = "The name of the subnet to create."
    type        = string
}

variable "local_subnet_cidr" {
    description = "The CIDR block for the subnet."
    type        = string
}

variable "local_vm_name" {
    description = "The name of the VM instance to create."
    type        = string
}

variable "local_machine_type" {
    description = "The machine type for the VM instance."
    type        = string
}

variable "local_zone" {
    description = "Zone in which to be created"
    type = string
}