variable "location" {
  description = "Azure regija"
  default     = "eastus"
}

variable "project_tag" {
  description = "Tag projekta"
  default     = "techsprint"
}

variable "environment_tag" {
  description = "Tag okoline"
  default     = "testing"
}

variable "csv_path" {
  description = "Putanja do CSV datoteke s korisnicima"
  type        = string
}