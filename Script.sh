#!/bin/bash
# Script to delete old Helm charts and verify new ones
# Usage: ./helm-cleanup.sh <namespace>

set -e
NAMESPACE=$1

if [ -z "$NAMESPACE" ]; then
    echo "Usage: ./helm-cleanup.sh <namespace>"
    echo "Example: ./helm-cleanup.sh my-app-ns"
    exit 1
fi

# Function to check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        echo "kubectl is not installed. Please install it first."
        exit 1
    fi
}

# Function to check if helm is available
check_helm() {
    if ! command -v helm &> /dev/null; then
        echo "helm is not installed. Please install it first."
        exit 1
    fi
}

# Function to backup current state
backup_state() {
    echo "📦 Backing up current state..."
    mkdir -p "./helm-backup-${NAMESPACE}"
    kubectl get all -n "$NAMESPACE" -l "app=old-helm-chart-here" -o yaml > "./helm-backup-${NAMESPACE}/backup-$(date +%Y%m%d-%H%M%S).yaml"
    echo "✅ Backup completed"
}

# Function to delete old resources
delete_old_resources() {
    echo "🗑️ Removing old Helm charts..."
    
    # List and uninstall old Helm releases
    helm list -n "$NAMESPACE" | grep "old-chart-name" | while read -r line; do
        RELEASE_NAME=$(echo "$line" | awk '{print $1}')
        echo "Uninstalling Helm release: $RELEASE_NAME"
        helm uninstall "$RELEASE_NAME" -n "$NAMESPACE" || true
    done
    
    echo "✅ Old Helm charts removed"
}

# Function to verify new charts
verify_new_charts() {
    echo "🔍 Verifying new charts..."
    
    NEW_CHARTS=$(helm list -n "$NAMESPACE" | grep "new-chart-name")
    if [ -z "$NEW_CHARTS" ]; then
        echo "❌ No new charts found in namespace $NAMESPACE"
        exit 1
    else
        echo "✅ New charts found and verified:"
        echo "$NEW_CHARTS"
    fi
}

# Main execution
echo "🏁 Starting Helm chart cleanup for namespace: $NAMESPACE"
check_kubectl
check_helm

# Ask for confirmation
read -p "Are you sure you want to delete old Helm charts? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Operation cancelled"
    exit 1
fi

# Execute steps
backup_state
delete_old_resources
verify_new_charts

echo "🎉 Cleanup completed successfully!"
