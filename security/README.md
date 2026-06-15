# Shift-Left Security Assets

This directory contains the repo-side assets for Phase 04.

- `trivy.yaml`: shared Trivy configuration for filesystem and IaC scans
- `workload-images.txt`: image inventory consumed by the CI security pipeline

When real workload images are published to Artifact Registry, add them to `workload-images.txt` so the CI pipeline can scan, generate SBOMs, and sign them.
