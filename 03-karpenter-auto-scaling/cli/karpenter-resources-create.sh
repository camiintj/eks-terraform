#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESOURCES_DIR="$SCRIPT_DIR/../resources"
TEMP_DIR=$(mktemp -d)

function enableKubernetesClusterConnection(){
    aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME
}

function createKarpenterResources(){
    # Create temp copies to avoid modifying originals
    cp "$RESOURCES_DIR/karpenter-node-class.yml" "$TEMP_DIR/karpenter-node-class.yml"
    cp "$RESOURCES_DIR/karpenter-node-pool.yml" "$TEMP_DIR/karpenter-node-pool.yml"

    # Replace placeholders in temp copies
    sed -i "s|\${CLUSTER_NAME}|$CLUSTER_NAME|g" "$TEMP_DIR/karpenter-node-class.yml"
    sed -i "s|\${KARPENTER_NODE_ROLE}|$KARPENTER_NODE_ROLE|g" "$TEMP_DIR/karpenter-node-class.yml"

    kubectl apply -f "$TEMP_DIR/karpenter-node-class.yml"
    kubectl apply -f "$TEMP_DIR/karpenter-node-pool.yml"

    rm -rf "$TEMP_DIR"
}

enableKubernetesClusterConnection
createKarpenterResources
