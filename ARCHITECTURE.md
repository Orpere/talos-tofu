# Talos-Tofu Architecture Documentation

This directory contains comprehensive architecture documentation for the Talos-Tofu project, including C4 model diagrams that render automatically in VS Code markdown preview.

## 📋 Documentation Structure

```text
talos-tofu/
├── ARCHITECTURE.md                     # This file - architecture overview
├── architecture-c4-diagram.md          # Complete C4 diagrams with Mermaid
└── README.md                           # Project overview and usage instructions
```

## 🎯 Quick Start - View Diagrams in VS Code

### **Automatic Rendering (Recommended)**

1. **Open the architecture file**: `architecture-c4-diagram.md`
2. **Enable markdown preview**: Press `Ctrl+Shift+V` (Windows/Linux) or `Cmd+Shift+V` (macOS)
3. **Diagrams render automatically** with the Mermaid extension

### **Requirements**

- VS Code with Markdown Preview Mermaid Support extension
- No additional setup needed - diagrams are embedded in markdown

## 🏗️ Architecture Overview

The Talos-Tofu project implements a production-ready Kubernetes infrastructure with the following key characteristics:

### **Infrastructure Layer**

- **Proxmox VE**: Virtualization platform hosting all cluster nodes
- **Talos OS**: Immutable, secure Linux distribution optimized for Kubernetes
- **Terraform/OpenTofu**: Infrastructure as Code for complete automation

### **Kubernetes Cluster**

- **High Availability**: 3 control plane nodes for cluster resilience
- **Scalable Workers**: 3 worker nodes for application workloads
- **Resource Allocation**: 8 cores, 8GB RAM per node with appropriate storage

### **Networking & Security**

- **MetalLB**: Bare-metal load balancer for LoadBalancer services
- **Nginx Ingress**: HTTP/HTTPS ingress with SSL termination
- **Cert-Manager**: Automatic SSL/TLS certificate management
- **External DNS**: Automatic DNS record management via RFC2136

### **GitOps & Automation**

- **ArgoCD**: GitOps controller for continuous deployment
- **Helm**: Package manager for Kubernetes applications
- **Automated DNS**: Dynamic DNS updates with TSIG authentication
- **SSL Automation**: Let's Encrypt integration with Cloudflare DNS01

## 📊 Diagram Hierarchy

### Level 1: System Context

- **Audience**: Stakeholders, architects, business users
- **Focus**: System boundaries and external dependencies
- **File**: `architecture-c4-diagram.md` (Level 1 section)

### Level 2: Container

- **Audience**: Technical team leads, system architects
- **Focus**: Major applications and their interactions
- **File**: `architecture-c4-diagram.md` (Level 2 section)

### Level 3: Component

- **Audience**: Developers, DevOps engineers
- **Focus**: Code organization and module structure
- **File**: `architecture-c4-diagram.md` (Level 3 section)

### Level 4: Deployment Flow

- **Audience**: DevOps engineers, operations team
- **Focus**: Deployment sequence and dependencies
- **File**: `architecture-c4-diagram.md` (Level 4 section)

## 🔧 Technology Stack

### **Infrastructure**

- Terraform/OpenTofu
- Proxmox VE
- Talos OS
- RFC2136/TSIG DNS

### **Kubernetes**

- Kubernetes 1.x
- MetalLB
- Nginx Ingress Controller
- Cert-Manager
- External DNS

### **GitOps**

- ArgoCD
- Helm
- Git repositories

### **External Services**

- Cloudflare (DNS provider)
- Let's Encrypt (SSL certificates)

## 🚀 Key Benefits

1. **Full Automation**: Complete infrastructure deployment with a single command
2. **High Availability**: Multi-master Kubernetes setup with automatic failover
3. **Security First**: Immutable OS, automatic SSL/TLS, network policies
4. **GitOps Ready**: Application lifecycle management through Git workflows
5. **Production Grade**: Load balancing, ingress, certificate management
6. **Scalable**: Easy to add more worker nodes or expand capacity

## 📖 Usage Instructions

1. **Start with Context**: Review the system context diagram to understand overall architecture
2. **Explore Containers**: Use the container diagram to understand major components
3. **Dive into Code**: Check component diagrams for implementation details
4. **Follow Deployment**: Use the deployment flow for operational understanding

## 🔄 Maintenance

When updating the infrastructure:

1. Update relevant diagrams in `architecture-c4-diagram.md`
2. Update documentation to reflect changes
3. Commit both source files and any generated images

## 📚 Additional Resources

- [C4 Model Documentation](https://c4model.com/)
- [Mermaid Documentation](https://mermaid.js.org/)
- [Talos OS Documentation](https://www.talos.dev/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)

This documentation provides multiple perspectives on the same architecture, suitable for different audiences and use cases.
