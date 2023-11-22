#!/bin/bash

sudo snap install multipass
sudo chmod a+w /var/snap/multipass/common/multipass_socket
curl https://raw.githubusercontent.com/tigera/ccol1/main/control-init.yaml | multipass launch -n control -m 2048M 20.04 --cloud-init -
curl https://raw.githubusercontent.com/tigera/ccol1/main/node1-init.yaml | multipass launch -n node1 20.04 --cloud-init -
curl https://raw.githubusercontent.com/tigera/ccol1/main/node2-init.yaml | multipass launch -n node2 20.04 --cloud-init -
curl https://raw.githubusercontent.com/tigera/ccol1/main/host1-init.yaml | multipass launch -n host1 20.04 --cloud-init -

multipass exec host1 -- kubectl create -f https://docs.projectcalico.org/archive/v3.21/manifests/tigera-operator.yaml
multipass exec host1 -- kubectl get pods -n tigera-operator
multipass exec host1 -- kubectl wait --for=condition=ready pod -l name=tigera-operator -n tigera-operator

cat <<EOF | kubectl apply -f -
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  calicoNetwork:
    containerIPForwarding: Enabled
    ipPools:
    - cidr: 198.19.16.0/21
      natOutgoing: Enabled
      encapsulation: None
EOF

