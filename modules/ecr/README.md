# ECR Module

Creates a private ECR repository for Docker images.

Features:
- Immutable tags by default
- Scan on push
- Lifecycle policy to keep storage costs low

Inputs: repository_name (required), others optional.

Outputs: repository_url (key for CI/CD), name, etc.