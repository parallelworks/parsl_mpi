#!/usr/bin/env bash
# Copyright (c) 2025 masezou. All rights reserved.
#########################################################
 
bold_msg() {
    echo -e "\033[1m$1\033[0m"
}
bold_green_msg() {
    echo -e "\033[1m\033[32m$1\033[0m"
}
green_msg() {
    echo -e "\033[1;32m$1\033[0m"
}

red_msg() {
    echo -e "\033[1;31m$1\033[0m"
}

yellow_msg() {
    echo -e "\033[1;33m$1\033[0m"
}

all_checks_passed=true

#===================================
# Remove architecture check for now
#===================================
#arch=$(dpkg --print-architecture)
#bold_msg "Checking Architecture: Required (amd64 or arm64), Current ($arch)"
#if [[ "$arch" == "amd64" || "$arch" == "arm64" ]]; then
#    green_msg "OK"
#else
#    red_msg "NG"
#    all_checks_passed=false
#fi

#======================================
# Remove release version check for now
#======================================
#ubuntu_version=$(lsb_release -rs)
#bold_msg "Checking Ubuntu Version: Required (22.04 or 24.04), Current ($ubuntu_version)"
#if [[ "$ubuntu_version" == "22.04" || "$ubuntu_version" == "24.04" ]]; then
#    green_msg "OK"
#else
#    red_msg "NG"
#    all_checks_passed=false
#fi

desktop_check=$(lsb_release -d | grep -i "desktop")
bold_msg "Checking Server Edition: Required (Server), Current ($(lsb_release -d))"
if [[ -z "$desktop_check" ]]; then
    green_msg "OK"
else
    red_msg "NG"
    all_checks_passed=false
fi
cpu_cores=$(nproc)
bold_msg "Checking CPU Cores: Required (4 or more), Current ($cpu_cores)"
if [[ "$cpu_cores" -ge 4 ]]; then
    green_msg "OK"
else
    red_msg "NG"
    all_checks_passed=false
fi
mem_total_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
mem_total_gb=$((mem_total_kb / 1024 / 1024))
bold_msg "Checking Memory: Required (8GB or more), Current (${mem_total_gb}GB)"
if [[ "$mem_total_gb" -ge 8 ]]; then
    green_msg "OK"
else
    red_msg "NG"
    all_checks_passed=false
fi
disk_free_gb=$(df --output=avail / | tail -n 1 | awk '{print $1 / 1024 / 1024}')
disk_free_gb=${disk_free_gb%.*} # 小数点以下切り捨て
bold_msg "Checking Disk Space: Required (50GB or more), Current (${disk_free_gb}GB)"
if [[ "$disk_free_gb" -ge 50 ]]; then
    green_msg "OK"
else
    red_msg "NG"
    all_checks_passed=false
fi

if $all_checks_passed; then
    green_msg "Continue..."
else
    red_msg "Some checks failed. Please fix the issues and retry."
    exit 1
fi

bold_green_msg "pre-setup"
tee /etc/sysctl.d/10-k8s.conf << EOF
fs.inotify.max_user_instances = 1024
fs.inotify.max_user_watches = 1048576
EOF
sysctl -p /etc/sysctl.d/10-k8s.conf
sysctl -a | grep "fs.inotify"
swapoff -a
sed -i '/\/swap\.img\s\+none\s\+swap\s\+sw\s\+0\s\+0/s/^/#/' /etc/fstab

bold_green_msg "Install local registry"
EGDIR=/disk/registry

mkdir -p ${REGDIR}
ln -s ${REGDIR} /var/lib/docker-registry
ufw allow 5000
apt -y install docker-registry
sed -i -e "s/  htpasswd/#  htpasswd/g" /etc/docker/registry/config.yml
sed -i -e "s/    realm/#    realm/g" /etc/docker/registry/config.yml
sed -i -e "s/    path/#    path/g" /etc/docker/registry/config.yml
cat <<EOF >/etc/cron.hourly/docker-registry-garbage
#!/bin/sh
/usr/bin/docker-registry garbage-collect /etc/docker/registry/config.yml
EOF
chmod +x /etc/cron.hourly/docker-registry-garbage
systemctl restart docker-registry
systemctl enable docker-registry

bold_green_msg "Install k3s"
curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=v1.31 K3S_KUBECONFIG_MODE="644" sh -
sleep 20
kubectl -n kube-system wait pod -l k8s-app=kube-dns --for condition=Ready --timeout 60s
kubectl -n kube-system wait pod -l k8s-app=metrics-server --for condition=Ready --timeout 60s
kubectl -n kube-system wait pod -l app=local-path-provisioner --for condition=Ready --timeout 60s
kubectl -n kube-system wait pod -l svccontroller.k3s.cattle.io/svcnamespace=kube-system --for condition=Ready --timeout 60s
kubectl -n kube-system wait pod -l app.kubernetes.io/instance=traefik-kube-system --for condition=Ready --timeout 60s

kubectl label node `hostname` node-role.kubernetes.io/worker=worker

ETHDEV=$(netplan get | sed 's/^[[:space:]]*//' | grep -A 1 "ethernet" | grep -v ethernet | cut -d ":" -f 1)
LOCALIPADDR=$(ip -f inet -o addr show $ETHDEV | cut -d\  -f 7 | cut -d/ -f 1)
REGISTRYHOST=${LOCALIPADDR}
REGISTRYPORT=5000
REGISTRY=${REGISTRYHOST}:${REGISTRYPORT}
REGISTRYURL=http://${REGISTRY}

cat <<EOF >/etc/rancher/k3s/registries.yaml
mirrors:
  "${REGISTRY}":
    endpoint:
      - "${REGISTRYURL}"
EOF
systemctl restart k3s
kubectl -n kube-system wait pod -l k8s-app=kube-dns --for condition=Ready --timeout 60s
kubectl -n kube-system wait pod -l k8s-app=metrics-server --for condition=Ready --timeout 60s
kubectl -n kube-system wait pod -l app=local-path-provisioner --for condition=Ready --timeout 60s
kubectl -n kube-system wait pod -l svccontroller.k3s.cattle.io/svcnamespace=kube-system --for condition=Ready --timeout 60s
kubectl -n kube-system wait pod -l app.kubernetes.io/instance=traefik-kube-system --for condition=Ready --timeout 60s

# Report only actual ip address from VMware Tools
if [ -d /etc/vmware-tools ]; then
	cat <<EOF >/etc/vmware-tools/tools.conf.tmp
[guestinfo]
exclude-nics=cni*,flannel*,podman*,lxdbr*,veth*,docker*,virbr*,br-*,lxc*,cilium*,vxlan*,calico*,cali*
EOF
	cp /etc/vmware-tools/tools.conf /etc/vmware-tools/tools.conf.orig
	cat /etc/vmware-tools/tools.conf.tmp /etc/vmware-tools/tools.conf.orig >/etc/vmware-tools/tools.conf
	rm /etc/vmware-tools/tools.conf.tmp
	apt -y install open-vm-tools-containerinfo
	systemctl stop open-vm-tools.service
	systemctl start open-vm-tools.service
fi

mkdir -p ~/.kube
cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
PUBLICIP=$(kubectl get node -o wide | grep control | awk '{print $6}')
sed -i -e "s/127.0.0.1/${PUBLICIP}/g" ~/.kube/config
chmod 400 ~/.kube/config
apt -y install bash-completion
k3s completion bash > /etc/bash_completion.d/k3s
source /etc/bash_completion.d/k3s
kubectl completion bash > /etc/bash_completion.d/kubectl
source /etc/bash_completion.d/kubectl
crictl completion bash > /etc/bash_completion.d/crictl
source /etc/bash_completion.d/crictl
CONTAINERDVER=1.7.23
curl --retry 10 --retry-delay 3 --retry-connrefused -sS https://raw.githubusercontent.com/containerd/containerd/v${CONTAINERDVER}/contrib/autocomplete/ctr -o /etc/bash_completion.d/ctr
source /etc/bash_completion.d/ctr

bold_green_msg "Deploy local registry frontend"
ETHDEV=$(netplan get | sed 's/^[[:space:]]*//' | grep -A 1 "ethernet" | grep -v ethernet | cut -d ":" -f 1)
LOCALIPADDR=$(ip -f inet -o addr show $ETHDEV | cut -d\  -f 7 | cut -d/ -f 1)
REGISTRYHOST=${LOCALIPADDR}
REGISTRYPORT=5000
REGISTRY=${REGISTRYHOST}:${REGISTRYPORT}
REGISTRYURL=http://${REGISTRY}
ARCH=`dpkg --print-architecture`

ctr images pull --platform linux/${ARCH} docker.io/ekazakov/docker-registry-frontend:latest
ctr images tag docker.io/ekazakov/docker-registry-frontend:latest ${REGISTRY}/docker-registry-frontend:latest
ctr images push --platform linux/${ARCH} --plain-http ${REGISTRY}/docker-registry-frontend:latest
ctr images rm docker.io/ekazakov/docker-registry-frontend:latest
ctr images rm ${REGISTRY}/docker-registry-frontend:latest

kubectl create ns registoryfe
cat <<EOF | kubectl apply -n registoryfe -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: registryfe
spec:
  replicas: 1
  selector:
    matchLabels:
      app: registryfe
  template:
    metadata:
      labels:
        app: registryfe
    spec:
      containers:
      - name: registryfe
        image: ${REGISTRY}/docker-registry-frontend:latest
        env:
        - name: ENV_DOCKER_REGISTRY_HOST
          value: "${REGISTRYHOST}"
        - name: ENV_DOCKER_REGISTRY_PORT
          value: "${REGISTRYPORT}"
        ports:
        - containerPort: 80
          name: http
EOF
cat <<EOF | kubectl apply -n registoryfe -f -
apiVersion: v1
kind: Service
metadata:
  name: registryfe
spec:
  selector:
    app: registryfe
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
      nodePort: 30000
  type: NodePort
EOF
kubectl -n registoryfe get all

bold_green_msg "Install External snapshotter"
SNAPSHOTTERVER=8.2.0
# Apply VolumeSnapshot CRDs
kubectl create -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/v${SNAPSHOTTERVER}/client/config/crd/snapshot.storage.k8s.io_volumesnapshotclasses.yaml
kubectl create -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/v${SNAPSHOTTERVER}/client/config/crd/snapshot.storage.k8s.io_volumesnapshotcontents.yaml
kubectl create -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/v${SNAPSHOTTERVER}/client/config/crd/snapshot.storage.k8s.io_volumesnapshots.yaml

# Create Snapshot Controller
curl --retry 10 --retry-delay 3 --retry-connrefused -sSOL https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/v${SNAPSHOTTERVER}/deploy/kubernetes/snapshot-controller/rbac-snapshot-controller.yaml
sed -i -e "s/namespace: default/namespace: kube-system/g" rbac-snapshot-controller.yaml
kubectl create -f rbac-snapshot-controller.yaml
rm -rf rbac-snapshot-controller.yaml
curl --retry 10 --retry-delay 3 --retry-connrefused -sSOL https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/v${SNAPSHOTTERVER}/deploy/kubernetes/snapshot-controller/setup-snapshot-controller.yaml
sed -i -e "s/namespace: default/namespace: kube-system/g" setup-snapshot-controller.yaml
kubectl create -f setup-snapshot-controller.yaml
rm setup-snapshot-controller.yaml
kubectl -n kube-system wait pod -l app.kubernetes.io/name=snapshot-controller --for condition=Ready --timeout 60s

bold_green_msg "Install Longhorn"
apt -y install nfs-common jq
systemctl stop multipathd.socket && systemctl disable multipathd.socket
systemctl stop multipathd && systemctl disable multipathd
modprobe iscsi_tcp
modprobe dm_crypt
echo "iscsi_tcp" > /etc/modules-load.d/iscsi_tcp.conf
echo "dm_crypt" > /etc/modules-load.d/dm_crypt.conf
sed -i -e "s/debian/debian.$(hostname)/g" /etc/iscsi/initiatorname.iscsi
systemctl restart iscsid.service
LONGHORNVER=1.8.1
curl -sSfL -o longhornctl https://github.com/longhorn/cli/releases/download/v${LONGHORNVER}/longhornctl-linux-$(dpkg --print-architecture)
chmod +x ./longhornctl
./longhornctl --kube-config /etc/rancher/k3s/k3s.yaml check preflight
helm repo add longhorn https://charts.longhorn.io
helm repo update
PUBLICIP=`kubectl get nodes -o jsonpath='{.items[*].metadata.annotations.flannel\.alpha\.coreos\.com\/public-ip}'`
DNSDOMAINNAME=`cat /etc/hostname`.${PUBLICIP}.sslip.io
helm install longhorn longhorn/longhorn --namespace longhorn-system --set persistence.defaultClassReplicaCount=1 --set defaultSettings.defaultReplicaCount=1 --set defaultSettings.replicaZoneSoftAntiAffinity=true  --set longhornUI.replicas=1 --set ingress.enabled=true --set ingress.host=longhorn.${DNSDOMAINNAME} --create-namespace --version $LONGHORNVER --wait
sleep 60
kubectl -n longhorn-system wait pod -l app=csi-attacher --for condition=Ready --timeout 300s
kubectl -n longhorn-system wait pod -l app=csi-provisioner --for condition=Ready --timeout 300s
kubectl -n longhorn-system wait pod -l app=csi-resizer --for condition=Ready --timeout 300s
kubectl -n longhorn-system wait pod -l app=csi-snapshotter --for condition=Ready --timeout 300s
kubectl label node `cat /etc/hostname` topology.kubernetes.io/zone=`cat /etc/hostname`

cat <<EOF | kubectl apply -f -
kind: VolumeSnapshotClass
apiVersion: snapshot.storage.k8s.io/v1
metadata:
  annotations:
    snapshot.storage.kubernetes.io/is-default-class: "true"
  name: longhorn-snapshot-vsc
driver: driver.longhorn.io
deletionPolicy: Delete
parameters:
  type: snap
EOF
kubectl get volumesnapshotclasses

cp /var/lib/rancher/k3s/server/manifests/local-storage.yaml /var/lib/rancher/k3s/server/manifests/custom-local-storage.yaml
sed -i -e "s/storageclass.kubernetes.io\/is-default-class: \"true\"/storageclass.kubernetes.io\/is-default-class: \"false\"/g" /var/lib/rancher/k3s/server/manifests/custom-local-storage.yaml
#kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
sleep 20
kubectl get sc

bold_green_msg "setup traefilk dashboard"
cat << 'EOF' > /var/lib/rancher/k3s/server/manifests/traefik-config.yaml
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: traefik
  namespace: kube-system
spec:
  valuesContent: |-
    ingressRoute:
      dashboard:
        enabled: true
      healthcheck:
        enabled: true
        entryPoints: ["traefik", "web", "websecure"]
    logs:
      access:
        enabled: true
    service:
      spec:
        externalTrafficPolicy: Local
    ports:
      traefik:
        port: 9000
        expose:
          default: true
      mysql:
        expose: false
        #exposedPort: 3306
        hostPort: 3306
        port: 3306
        protocol: TCP
      pgsql:
        expose: false
        #exposedPort: 5432
        hostPort: 5432
        port: 5432
        protocol: TCP
    providers:
      kubernetesCRD:
        allowCrossNamespace: true
EOF

bold_green_msg "Install helm"
if type "helm" >/dev/null 2>&1; then
    echo -e "\e[32mhelm OK. \e[m"
else
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | tee /etc/apt/keyrings/helm.gpg > /dev/null
apt  install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list
apt  update
apt -y install helm
fi
helm version
helm completion bash >/etc/bash_completion.d/helm
source /etc/bash_completion.d/helm

bold_green_msg "Docker CLI"
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
cat << EOF > /etc/docker/daemon.json
{"insecure-registries": ["${REGISTRY}"]}
EOF
systemctl restart docker

echo
echo
echo "Setup was completed.
kubectl cluster-info
kubectl config get-contexts
kubectl get node -o wide
kubectl get pod -A
kubectl get svc -A
kubectl get sc

bold_msg "Local registry frontend"
echo "http://${LOCALIPADDR}:30000
echo
bold_msg "Longhorn Dashboard"
echo "http://$(kubectl -n longhorn-system get ingress longhorn-ingress -o jsonpath='{.spec.rules[0].host}')"
echo
bold_msg "Treafik Dashboard"
echo "http://${PUBLICIP}:9000/dashboard/"
