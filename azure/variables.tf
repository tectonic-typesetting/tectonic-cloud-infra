# Copyright 2021 the Tectonic Project
# Licensed under the MIT License

variable "env" {
  description = "An environment label, like ttdev, for uniquifying public resource names"
}

variable "location" {
  description = "The Azure location (region) where resources will be created"
}

variable "permanentDataName" {
  description = "The name of the permanent data storage account"
}

variable "assetsDomain" {
  description = "The top-level domain name of the assets website"
}
