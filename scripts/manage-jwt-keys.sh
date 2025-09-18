#!/bin/bash

# JWT Key Management Script for Transportation Management System
# This script helps generate new JWT keys and manage Kubernetes secrets

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to generate new JWT key pair
generate_jwt_keys() {
    local key_id="${1:-primary-$(date +%Y-%m)}"
    local issuer="${2:-yatms-user-service}"
    
    print_info "Generating new JWT key pair..."
    print_info "Key ID: $key_id"
    print_info "Issuer: $issuer"
    
    # Create temporary directory
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    # Generate private key
    openssl genrsa -out private_key.pem 2048
    
    # Generate public key
    openssl rsa -in private_key.pem -pubout -out public_key.pem
    
    # Read keys
    local private_key=$(cat private_key.pem)
    local public_key=$(cat public_key.pem)
    
    # Base64 encode for Kubernetes secrets
    local private_key_b64=$(echo -n "$private_key" | base64 -w 0)
    local public_key_b64=$(echo -n "$public_key" | base64 -w 0)
    local kid_b64=$(echo -n "$key_id" | base64 -w 0)
    local issuer_b64=$(echo -n "$issuer" | base64 -w 0)
    
    # Create Kubernetes secret YAML
    cat > jwt-secrets.yml << EOF
apiVersion: v1
kind: Secret
metadata:
  name: jwt-keys
  namespace: default
type: Opaque
data:
  jwt-private-key: $private_key_b64
  jwt-public-key: $public_key_b64
  jwt-kid: $kid_b64
  jwt-issuer: $issuer_b64
EOF
    
    # Copy to project directory
    cp jwt-secrets.yml "$(dirname "$0")/../apps/infra/k8s/"
    
    # Cleanup
    cd - > /dev/null
    rm -rf "$temp_dir"
    
    print_success "JWT keys generated and saved to apps/infra/k8s/jwt-secrets.yml"
    print_warning "IMPORTANT: Store the private key securely and never commit it to version control!"
    
    # Display the keys for reference (in production, you'd want to store these securely)
    echo
    print_info "Generated Keys (for reference only):"
    echo "Private Key:"
    echo "$private_key"
    echo
    echo "Public Key:"
    echo "$public_key"
}

# Function to apply secrets to Kubernetes
apply_secrets() {
    local namespace="${1:-default}"
    
    print_info "Applying JWT secrets to Kubernetes namespace: $namespace"
    
    if kubectl get secret jwt-keys -n "$namespace" >/dev/null 2>&1; then
        print_warning "Secret 'jwt-keys' already exists. Updating..."
        kubectl apply -f apps/infra/k8s/jwt-secrets.yml -n "$namespace"
    else
        print_info "Creating new secret 'jwt-keys'..."
        kubectl apply -f apps/infra/k8s/jwt-secrets.yml -n "$namespace"
    fi
    
    print_success "JWT secrets applied successfully"
}

# Function to verify secrets
verify_secrets() {
    local namespace="${1:-default}"
    
    print_info "Verifying JWT secrets in namespace: $namespace"
    
    if kubectl get secret jwt-keys -n "$namespace" >/dev/null 2>&1; then
        print_success "Secret 'jwt-keys' exists"
        
        # Check if all required keys are present
        local keys=("jwt-private-key" "jwt-public-key" "jwt-kid" "jwt-issuer")
        for key in "${keys[@]}"; do
            if kubectl get secret jwt-keys -n "$namespace" -o jsonpath="{.data.$key}" >/dev/null 2>&1; then
                print_success "Key '$key' is present"
            else
                print_error "Key '$key' is missing"
            fi
        done
    else
        print_error "Secret 'jwt-keys' does not exist"
    fi
}

# Function to rotate keys
rotate_keys() {
    local key_id="${1:-primary-$(date +%Y-%m)}"
    local issuer="${2:-yatms-user-service}"
    local namespace="${3:-default}"
    
    print_warning "This will generate new JWT keys and update the Kubernetes secret."
    print_warning "Make sure to update all services that verify JWT tokens!"
    
    read -p "Are you sure you want to proceed? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Key rotation cancelled"
        exit 0
    fi
    
    generate_jwt_keys "$key_id" "$issuer"
    apply_secrets "$namespace"
    
    print_success "Key rotation completed"
    print_warning "Remember to restart your services to pick up the new keys!"
}

# Main script logic
case "${1:-help}" in
    "generate")
        generate_jwt_keys "$2" "$3"
        ;;
    "apply")
        apply_secrets "$2"
        ;;
    "verify")
        verify_secrets "$2"
        ;;
    "rotate")
        rotate_keys "$2" "$3" "$4"
        ;;
    "help"|*)
        echo "JWT Key Management Script"
        echo
        echo "Usage: $0 <command> [options]"
        echo
        echo "Commands:"
        echo "  generate [key_id] [issuer]  - Generate new JWT key pair"
        echo "  apply [namespace]           - Apply secrets to Kubernetes"
        echo "  verify [namespace]         - Verify secrets in Kubernetes"
        echo "  rotate [key_id] [issuer] [namespace] - Generate and apply new keys"
        echo "  help                       - Show this help message"
        echo
        echo "Examples:"
        echo "  $0 generate primary-2025-01 yatms-user-service"
        echo "  $0 apply default"
        echo "  $0 verify default"
        echo "  $0 rotate primary-2025-01 yatms-user-service default"
        ;;
esac
