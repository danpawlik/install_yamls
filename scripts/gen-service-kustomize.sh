#!/bin/bash
#
# Copyright 2022 Red Hat Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
set -ex

# expect that the common.sh is in the same dir as the calling script
SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
. ${SCRIPTPATH}/common.sh --source-only

if [ -z "$NAMESPACE" ]; then
    echo "Please set NAMESPACE"; exit 1
fi

if [ -z "$KIND" ]; then
    echo "Please set SERVICE"; exit 1
fi

if [ -z "$SECRET" ]; then
    echo "Please set SECRET"; exit 1
fi

if [ -z "$DEPLOY_DIR" ]; then
    echo "Please set DEPLOY_DIR"; exit 1
fi

if [ -z "$IMAGE" ]; then
    echo "Please set IMAGE"; exit 1
fi

NAME=${KIND,,}

if [ ! -d ${DEPLOY_DIR} ]; then
    mkdir -p ${DEPLOY_DIR}
fi

pushd ${DEPLOY_DIR}

cat <<EOF >kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
namespace: ${NAMESPACE}
patches:
- target:
    kind: ${KIND}
  patch: |-
    - op: replace
      path: /spec/secret
      value: ${SECRET}
    - op: replace
      path: /spec/storageClass
      value: ${STORAGE_CLASS}
EOF
if [ "$KIND" == "OpenStackControlPlane" ]; then
cat <<EOF >>kustomization.yaml
    - op: replace
      path: /spec/keystone/template/containerImage
      value: ${KEYSTONEAPI_IMG}
    - op: replace
      path: /spec/mariadb/template/containerImage
      value: ${MARIADB_DEPL_IMG}
    - op: replace
      path: /spec/placement/template/containerImage
      value: ${PLACEMENTAPI_IMG}
    - op: replace
      path: /spec/glance/template/containerImage
      value: ${GLANCEAPI_IMG}
    - op: replace
      path: /spec/glance/template/glanceAPIInternal/containerImage
      value: ${GLANCEAPI_IMG}
    - op: replace
      path: /spec/glance/template/glanceAPIExternal/containerImage
      value: ${GLANCEAPI_IMG}
    - op: replace
      path: /spec/cinder/template/cinderAPI/containerImage
      value: ${CINDERAPI_IMG}
    - op: replace
      path: /spec/cinder/template/cinderScheduler/containerImage
      value: ${CINDERSCHEDULER_IMG}
    - op: replace
      path: /spec/cinder/template/cinderBackup/containerImage
      value: ${CINDERBACKUP_IMG}
    - op: replace
      path: /spec/cinder/template/cinderVolumes/volume1/containerImage
      value: ${CINDERVOLUME_IMG}
    - op: replace
      path: /spec/ovn/template/ovnDBCluster/ovndbcluster-nb/containerImage
      value: ${OVNBDS_IMG}
    - op: replace
      path: /spec/ovn/template/ovnDBCluster/ovndbcluster-sb/containerImage
      value: ${OVSBDS_IMG}
    - op: replace
      path: /spec/ovn/template/ovnNorthd/containerImage
      value: ${OVNNORTHD_IMG}
    - op: replace
      path: /spec/ovs/template/ovsContainerImage
      value: ${OVSSERVICE_IMG}
    - op: replace
      path: /spec/ovs/template/ovnContainerImage
      value: ${OVNCONTROLLER_IMG}
    - op: replace
      path: /spec/neutron/template/containerImage
      value: ${NEUTRONSERVER_IMG}
EOF
if [ "$IMAGE" != "unused" ]; then
cat <<EOF >>kustomization.yaml
    - op: replace
      path: /spec/containerImage
      value: ${IMAGE}
EOF
fi

kustomization_add_resources

popd
