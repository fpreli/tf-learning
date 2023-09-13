variable "input_prefix" {
  description = "Prefix for all objects"
  type        = string
  default     = "fp"
}

variable "input_project" {
  description = "The project id"
  type        = string
  default     = "fp-prj"
}

variable "input_region" {
  description = "The selected region"
  type        = string
  default     = "europe-west8"
}

variable "create_instance" {
  description = "If True creates the instance"
  type        = bool
  default     = true
}

variable "tf_vms" {
  type        = map(any)
  description = "My VMs to create"
  default     = {}
}