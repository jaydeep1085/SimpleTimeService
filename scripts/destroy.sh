#!/bin/bash
# Cleanup and destroy AWS infrastructure

set -e

echo "=================================================="
echo "SimpleTimeService - Infrastructure Cleanup"
echo "=================================================="
echo ""
echo "WARNING: This will destroy all AWS resources!"
echo ""
read -p "Are you sure? Type 'yes' to confirm: " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo "Destroying infrastructure..."
terraform -chdir=terraform destroy

echo ""
echo "✓ Infrastructure destroyed"
