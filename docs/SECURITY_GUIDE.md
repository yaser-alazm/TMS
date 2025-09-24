# 🔐 Security Guide - Files to Never Commit

## Overview
This guide outlines files that should **NEVER** be committed to version control due to security risks.

## 🚨 Critical Files (Already Protected by .gitignore)

### **Environment Files**
```
.env                    # Contains database passwords, API keys
.env.local             # Local environment overrides
.env.development       # Development secrets
.env.production        # Production secrets
env/*.env              # Service-specific environment files
```

### **JWT Keys & Certificates**
```
*.pem                  # Private/public keys
*.key                  # Private keys
*.crt                  # Certificates
*.cert                 # Certificates
*.p12                  # PKCS#12 certificates
*.pfx                  # Personal Information Exchange
*.jks                  # Java KeyStore
*.keystore             # Java KeyStore
keys/                  # Directory containing JWT keys
```

### **Database Files**
```
*.db                   # SQLite databases
*.sqlite               # SQLite databases
*.sqlite3              # SQLite databases
```

## 🛡️ Security Best Practices

### **1. Environment Variables**
- ✅ **DO**: Use `.env.example` files as templates
- ❌ **DON'T**: Commit actual `.env` files with real values
- ✅ **DO**: Document required environment variables in README

### **2. JWT Keys**
- ✅ **DO**: Generate keys locally for each environment
- ❌ **DON'T**: Share private keys between team members
- ✅ **DO**: Use different keys for development/production
- ❌ **DON'T**: Commit keys to version control

### **3. Database Credentials**
- ✅ **DO**: Use strong, unique passwords
- ❌ **DON'T**: Use default passwords in production
- ✅ **DO**: Rotate credentials regularly
- ❌ **DON'T**: Hardcode credentials in source code

## 🔍 Current Project Security Status

### **✅ Protected Files**
- `env/user-service.env` - Contains JWT keys (now ignored)
- `env/vehicle-service.env` - Contains database credentials (now ignored)
- `env/gateway.env` - Contains service configurations (now ignored)
- `env/gps-service.env` - Contains service configurations (now ignored)
- `env/traffic-service.env` - Contains service configurations (now ignored)
- `keys/jwt-private.pem` - JWT private key (now ignored)
- `keys/jwt-public.pem` - JWT public key (now ignored)

### **✅ Safe to Commit**
- `env.dev.example` - Template file (no real secrets)
- `docker-compose.dev.yml` - Uses environment variables
- Configuration files without secrets

## 🚀 Development Workflow

### **For New Team Members**
1. Copy `env.dev.example` to create local environment files
2. Generate new JWT keys using OpenSSL commands
3. Set up local database credentials
4. Never commit `.env` files

### **For Production Deployment**
1. Use environment variable injection
2. Generate production-specific JWT keys
3. Use secure credential management systems
4. Never store secrets in code

## 🔧 Commands to Generate JWT Keys

```bash
# Generate new private key
openssl genrsa -out keys/jwt-private.pem 2048

# Generate public key from private key
openssl rsa -in keys/jwt-private.pem -pubout -out keys/jwt-public.pem

# Generate Key ID
openssl rand -hex 8
```

## ⚠️ Emergency Response

### **If Secrets Are Accidentally Committed**
1. **Immediately** rotate all affected credentials
2. Remove files from git history: `git filter-branch`
3. Force push to remote: `git push --force`
4. Notify team members to update their local copies

### **Security Checklist**
- [ ] No `.env` files in git
- [ ] No `.pem` files in git
- [ ] No hardcoded passwords in code
- [ ] JWT keys are environment-specific
- [ ] Database credentials are secure
- [ ] API keys are not in source code

## 📞 Security Contacts
- **Project Lead**: Yaser Alazm
- **Security Issues**: Report immediately to project lead
- **Credential Compromise**: Rotate immediately

---

**Remember**: Security is everyone's responsibility! 🔒
