# OBaaS Helm Tools

Utility scripts for managing OBaaS chart dependencies and container images for
air-gapped or private-registry deployments.

## Scripts

### download-dependencies.sh

Downloads Helm chart dependencies for `obaas` and `obaas-prereqs`.

### generate-images-list.sh

Extracts container images from a running OBaaS deployment.

### mirror-images.sh

Mirrors OBaaS images to a private registry. Run `./mirror-images.sh --help` for
options.
