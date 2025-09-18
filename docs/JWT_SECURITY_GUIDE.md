# JWT Key Security Guide

## Overview

This guide explains how to properly secure JWT keys in your Transportation Management System to avoid exposing sensitive cryptographic material.

## Security Issues with Current Implementation

### Problems Identified
1. **Hardcoded Private Keys**: JWT private keys are stored in plain text in Kubernetes deployment YAML files
2. **Version Control Exposure**: Sensitive keys are committed to your Git repository
3. **No Key Rotation**: Keys cannot be easily rotated without code changes
4. **Access Control**: Anyone with repository access can see the private key

### Security Risks
- **Token Forgery**: Attackers can generate valid JWT tokens
- **Identity Impersonation**: Compromised keys allow impersonating any user
- **System Compromise**: Full authentication bypass is possible

## Solutions Implemented

### 1. Kubernetes Secrets (Immediate Fix)

**What was done:**
- Created `jwt-secrets.yml` with base64-encoded JWT keys
- Updated `user-depl.yml` to reference secrets instead of hardcoded values
- Created management script for key generation and rotation

**Files created/modified:**
- `apps/infra/k8s/jwt-secrets.yml` - Kubernetes secret definition
- `apps/infra/k8s/user-depl.yml` - Updated to use secret references
- `scripts/manage-jwt-keys.sh` - Key management script

**Usage:**
```bash
# Generate new keys
./scripts/manage-jwt-keys.sh generate primary-2025-01 yatms-user-service

# Apply to Kubernetes
./scripts/manage-jwt-keys.sh apply default

# Verify secrets
./scripts/manage-jwt-keys.sh verify default

# Rotate keys
./scripts/manage-jwt-keys.sh rotate primary-2025-01 yatms-user-service default
```

### 2. Deployment Changes

**Before (Insecure):**
```yaml
env:
  - name: JWT_PRIVATE_KEY_PEM
    value: "-----BEGIN PRIVATE KEY-----\n..."
```

**After (Secure):**
```yaml
env:
  - name: JWT_PRIVATE_KEY_PEM
    valueFrom:
      secretKeyRef:
        name: jwt-keys
        key: jwt-private-key
```

## Advanced Security Solutions

### 3. External Secret Management (Recommended for Production)

#### Option A: HashiCorp Vault
```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: vault-secret-store
spec:
  provider:
    vault:
      server: "https://vault.example.com"
      path: "secret"
      version: "v2"
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "tms-app"
---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: jwt-keys-external
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-secret-store
    kind: SecretStore
  target:
    name: jwt-keys
    creationPolicy: Owner
  data:
  - secretKey: jwt-private-key
    remoteRef:
      key: jwt-keys
      property: private-key
  - secretKey: jwt-public-key
    remoteRef:
      key: jwt-keys
      property: public-key
```

#### Option B: AWS Secrets Manager
```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secret-store
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-west-2
      auth:
        secretRef:
          accessKeyID:
            name: aws-credentials
            key: access-key-id
          secretAccessKey:
            name: aws-credentials
            key: secret-access-key
```

#### Option C: Google Secret Manager
```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: gcp-secret-store
spec:
  provider:
    gcpsm:
      projectId: "your-project-id"
      auth:
        workloadIdentity:
          clusterLocation: "us-central1"
          clusterName: "your-cluster"
          serviceAccountRef:
            name: "external-secrets-sa"
```

### 4. Key Rotation Strategy

#### Automated Rotation
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: jwt-key-rotation
spec:
  schedule: "0 0 1 * *"  # First day of every month
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: key-rotator
            image: your-registry/key-rotator:latest
            env:
            - name: VAULT_ADDR
              value: "https://vault.example.com"
            - name: VAULT_TOKEN
              valueFrom:
                secretKeyRef:
                  name: vault-token
                  key: token
          restartPolicy: OnFailure
```

#### Manual Rotation Process
1. Generate new key pair
2. Update secret store with new keys
3. Deploy new keys to staging environment
4. Test authentication with new keys
5. Deploy to production
6. Monitor for any authentication failures
7. Remove old keys after verification

### 5. Monitoring and Alerting

#### Key Expiration Monitoring
```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: jwt-key-monitor
spec:
  selector:
    matchLabels:
      app: user-service
  endpoints:
  - port: metrics
    path: /metrics
    interval: 30s
```

#### Alert Rules
```yaml
groups:
- name: jwt-security
  rules:
  - alert: JWTKeyExpiringSoon
    expr: jwt_key_expires_in_days < 30
    for: 1h
    labels:
      severity: warning
    annotations:
      summary: "JWT key expires in {{ $value }} days"
      
  - alert: JWTKeyCompromised
    expr: jwt_failed_verifications > 10
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "High number of JWT verification failures detected"
```

## Best Practices

### 1. Key Management
- **Use strong key sizes**: Minimum 2048-bit RSA keys
- **Regular rotation**: Rotate keys every 90 days or after security incidents
- **Separate environments**: Use different keys for dev/staging/production
- **Backup strategy**: Securely backup keys for disaster recovery

### 2. Access Control
- **Principle of least privilege**: Only grant access to keys when necessary
- **Audit logging**: Log all key access and modifications
- **Multi-person approval**: Require multiple approvals for key changes

### 3. Monitoring
- **Key usage metrics**: Monitor key usage patterns
- **Failed verification alerts**: Alert on unusual verification failures
- **Expiration warnings**: Alert before keys expire

### 4. Development Practices
- **Never commit keys**: Use .gitignore for key files
- **Environment variables**: Use environment variables for key paths
- **Secure defaults**: Fail securely when keys are missing

## Implementation Checklist

### Immediate Actions (High Priority)
- [ ] Remove hardcoded keys from all deployment files
- [ ] Apply Kubernetes secrets to all environments
- [ ] Test authentication with new secret-based configuration
- [ ] Update CI/CD pipelines to handle secrets properly

### Short-term Actions (Medium Priority)
- [ ] Implement external secret management (Vault/AWS/GCP)
- [ ] Set up key rotation automation
- [ ] Configure monitoring and alerting
- [ ] Document key management procedures

### Long-term Actions (Low Priority)
- [ ] Implement hardware security modules (HSM) for key storage
- [ ] Set up cross-region key replication
- [ ] Implement advanced threat detection
- [ ] Regular security audits and penetration testing

## Troubleshooting

### Common Issues

#### Secret Not Found
```bash
# Check if secret exists
kubectl get secret jwt-keys -n default

# Check secret contents
kubectl get secret jwt-keys -n default -o yaml
```

#### Key Format Issues
```bash
# Verify base64 encoding
echo "your-key-content" | base64 -w 0

# Decode and verify
echo "base64-encoded-key" | base64 -d
```

#### Service Not Starting
```bash
# Check pod logs
kubectl logs -f deployment/user-deployment -n default

# Check environment variables
kubectl exec -it deployment/user-deployment -n default -- env | grep JWT
```

## Security Considerations

### Production Deployment
1. **Use external secret management** (Vault, AWS Secrets Manager, etc.)
2. **Enable encryption at rest** for secret storage
3. **Implement network policies** to restrict secret access
4. **Use service mesh** for secure service-to-service communication
5. **Regular security audits** and penetration testing

### Compliance
- **SOC 2**: Implement proper access controls and monitoring
- **GDPR**: Ensure proper data protection for user authentication
- **PCI DSS**: If handling payment data, use HSM for key storage
- **HIPAA**: If handling health data, implement additional encryption layers

## Conclusion

The implemented Kubernetes Secrets solution provides immediate security improvements by removing hardcoded keys from your deployment files. For production environments, consider implementing external secret management solutions like HashiCorp Vault or cloud-native secret managers for enhanced security, automated rotation, and better compliance.

Remember: Security is an ongoing process, not a one-time implementation. Regular reviews, updates, and monitoring are essential for maintaining a secure authentication system.
