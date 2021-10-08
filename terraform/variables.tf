# Copyright 2021 Peter Williams and collaborators
# Licensed under the MIT License

variable "env" {
  description = "An environment label, like ttdev, for uniquifying public resource names"
}

variable "location" {
  description = "The location where resources will be created"
}

variable "permanentDataName" {
  description = "The name of the permanent data storage account"
}
