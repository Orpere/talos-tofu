#!/bin/bash

# Script to get all OpenBao operator init values
# This script retrieves the initialization keys and root token from OpenBao

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
NAMESPACE="default"
SECRET_NAME="openbao-keys"
OUTPUT_FORMAT="table"

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -n, --namespace NAMESPACE    Kubernetes namespace (default: default)"
    echo "  -s, --secret SECRET_NAME     Secret name containing keys (default: openbao-keys)"
    echo "  -f, --format FORMAT          Output format: table, json, yaml (default: table)"
    echo "  -h, --help                   Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                           # Get keys from default namespace"
    echo "  $0 -n openbao               # Get keys from openbao namespace"
    echo "  $0 -f json                   # Output in JSON format"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -s|--secret)
            SECRET_NAME="$2"
            shift 2
            ;;
        -f|--format)
            OUTPUT_FORMAT="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            exit 1
            ;;
    esac
done

# Function to check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}Error: kubectl is not installed or not in PATH${NC}"
        exit 1
    fi
}

# Function to check if the secret exists
check_secret_exists() {
    if ! kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" &> /dev/null; then
        echo -e "${RED}Error: Secret '$SECRET_NAME' not found in namespace '$NAMESPACE'${NC}"
        echo -e "${YELLOW}Available secrets in namespace '$NAMESPACE':${NC}"
        kubectl get secrets -n "$NAMESPACE" --no-headers | awk '{print "  - " $1}'
        exit 1
    fi
}

# Function to get secret data
get_secret_data() {
    kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" -o json | jq -r '.data'
}

# Function to decode base64 data
decode_data() {
    local key="$1"
    local data="$2"
    echo "$data" | jq -r ".$key // empty" | base64 -d 2>/dev/null || echo "N/A"
}

# Function to display data in table format
display_table() {
    local data="$1"
    
    echo -e "${GREEN}OpenBao Initialization Keys and Token${NC}"
    echo -e "${BLUE}Namespace: $NAMESPACE${NC}"
    echo -e "${BLUE}Secret: $SECRET_NAME${NC}"
    echo ""
    
    printf "%-20s | %s\n" "Key" "Value"
    printf "%-20s-+-%s\n" "--------------------" "----------------------------------------"
    
    # Get root token (try both naming conventions)
    local root_token=$(decode_data "root_token" "$data")
    if [[ "$root_token" == "N/A" ]]; then
        root_token=$(decode_data "root-token" "$data")
    fi
    if [[ "$root_token" != "N/A" ]]; then
        printf "%-20s | %s\n" "Root Token" "$root_token"
    fi
    
    # Get unseal keys (try both naming conventions)
    local i=0
    while true; do
        local key_name="unseal_key_$i"
        local key_value=$(decode_data "$key_name" "$data")
        if [[ "$key_value" == "N/A" ]]; then
            key_name="unseal-key-$i"
            key_value=$(decode_data "$key_name" "$data")
        fi
        if [[ "$key_value" == "N/A" ]]; then
            break
        fi
        printf "%-20s | %s\n" "Unseal Key $i" "$key_value"
        ((i++))
    done
    
    # Check for other common keys
    local recovery_key=$(decode_data "recovery-key" "$data")
    if [[ "$recovery_key" != "N/A" ]]; then
        printf "%-20s | %s\n" "Recovery Key" "$recovery_key"
    fi
    
    local recovery_token=$(decode_data "recovery-token" "$data")
    if [[ "$recovery_token" != "N/A" ]]; then
        printf "%-20s | %s\n" "Recovery Token" "$recovery_token"
    fi
}

# Function to display data in JSON format
display_json() {
    local data="$1"
    
    local json_output="{}"
    
    # Add root token (try both naming conventions)
    local root_token=$(decode_data "root_token" "$data")
    if [[ "$root_token" == "N/A" ]]; then
        root_token=$(decode_data "root-token" "$data")
    fi
    if [[ "$root_token" != "N/A" ]]; then
        json_output=$(echo "$json_output" | jq --arg token "$root_token" '. + {"root_token": $token}')
    fi
    
    # Add unseal keys (try both naming conventions)
    local unseal_keys="[]"
    local i=0
    while true; do
        local key_name="unseal_key_$i"
        local key_value=$(decode_data "$key_name" "$data")
        if [[ "$key_value" == "N/A" ]]; then
            key_name="unseal-key-$i"
            key_value=$(decode_data "$key_name" "$data")
        fi
        if [[ "$key_value" == "N/A" ]]; then
            break
        fi
        unseal_keys=$(echo "$unseal_keys" | jq --arg key "$key_value" '. + [$key]')
        ((i++))
    done
    
    if [[ $(echo "$unseal_keys" | jq 'length') -gt 0 ]]; then
        json_output=$(echo "$json_output" | jq --argjson keys "$unseal_keys" '. + {"unseal_keys": $keys}')
    fi
    
    # Add other keys
    local recovery_key=$(decode_data "recovery-key" "$data")
    if [[ "$recovery_key" != "N/A" ]]; then
        json_output=$(echo "$json_output" | jq --arg key "$recovery_key" '. + {"recovery_key": $key}')
    fi
    
    local recovery_token=$(decode_data "recovery-token" "$data")
    if [[ "$recovery_token" != "N/A" ]]; then
        json_output=$(echo "$json_output" | jq --arg token "$recovery_token" '. + {"recovery_token": $token}')
    fi
    
    echo "$json_output" | jq .
}

# Function to display data in YAML format
display_yaml() {
    local data="$1"
    
    echo "openbao_init:"
    echo "  namespace: $NAMESPACE"
    echo "  secret: $SECRET_NAME"
    
    # Add root token (try both naming conventions)
    local root_token=$(decode_data "root_token" "$data")
    if [[ "$root_token" == "N/A" ]]; then
        root_token=$(decode_data "root-token" "$data")
    fi
    if [[ "$root_token" != "N/A" ]]; then
        echo "  root_token: \"$root_token\""
    fi
    
    # Add unseal keys (try both naming conventions)
    local i=0
    local has_unseal_keys=false
    while true; do
        local key_name="unseal_key_$i"
        local key_value=$(decode_data "$key_name" "$data")
        if [[ "$key_value" == "N/A" ]]; then
            key_name="unseal-key-$i"
            key_value=$(decode_data "$key_name" "$data")
        fi
        if [[ "$key_value" == "N/A" ]]; then
            break
        fi
        if [[ "$has_unseal_keys" == "false" ]]; then
            echo "  unseal_keys:"
            has_unseal_keys=true
        fi
        echo "    - \"$key_value\""
        ((i++))
    done
    
    # Add other keys
    local recovery_key=$(decode_data "recovery-key" "$data")
    if [[ "$recovery_key" != "N/A" ]]; then
        echo "  recovery_key: \"$recovery_key\""
    fi
    
    local recovery_token=$(decode_data "recovery-token" "$data")
    if [[ "$recovery_token" != "N/A" ]]; then
        echo "  recovery_token: \"$recovery_token\""
    fi
}

# Main execution
main() {
    echo -e "${YELLOW}Retrieving OpenBao initialization keys...${NC}"
    
    # Check prerequisites
    check_kubectl
    
    # Check if secret exists
    check_secret_exists
    
    # Get secret data
    local secret_data=$(get_secret_data)
    
    # Display data based on format
    case "$OUTPUT_FORMAT" in
        "table")
            display_table "$secret_data"
            ;;
        "json")
            display_json "$secret_data"
            ;;
        "yaml")
            display_yaml "$secret_data"
            ;;
        *)
            echo -e "${RED}Error: Invalid output format '$OUTPUT_FORMAT'. Use: table, json, yaml${NC}"
            exit 1
            ;;
    esac
    
    echo ""
    echo -e "${GREEN}✓ OpenBao keys retrieved successfully${NC}"
}

# Run main function
main "$@"
