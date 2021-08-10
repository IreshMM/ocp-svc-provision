# Inspired by and contains work from https://github.com/ryanhay/ocp4-metal-install

## Example execution:

```bash
ansible-playbook -i inventory.yml playbook.yml --extra-vars 'ocp_clients_url="https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/4.2.18/openshift-client-linux-4.2.18.tar.gz" cluster_name=ocp42 ocp_installer_url="https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/4.2.18/openshift-install-linux-4.2.18.tar.gz"'
```
