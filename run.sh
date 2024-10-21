#!/bin/bash

# Initialize Terraform
terraform init
if [[ $? -ne 0 ]]; then
    echo "Error: Terraform init failed."
    exit 1
fi

# Format Terraform files
terraform fmt
if [[ $? -ne 0 ]]; then
    echo "Error: Terraform fmt failed."
    exit 1
fi

# Validate Terraform configuration
terraform validate
if [[ $? -ne 0 ]]; then
    echo "Error: Terraform validate failed."
    exit 1
fi

# Apply Terraform configuration
terraform apply -auto-approve
if [[ $? -ne 0 ]]; then
    echo "Error: Terraform apply failed."
    exit 1
fi

echo "Terraform commands executed successfully."