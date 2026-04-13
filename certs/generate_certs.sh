#!/bin/bash

CONTROLLERS=("10.0.0.10" "10.0.0.11" "10.0.0.12")
WORKERS=("10.0.0.20" "10.0.0.21" "10.0.0.22")
K8S_SERVICE_IP="10.32.0.1"

# 1. CA (без изменений)
cat > ca-config.json <<EOF
{
  "signing": {
    "default": { "expiry": "8760h" },
    "profiles": {
      "kubernetes": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "8760h"
      }
    }
  }
}
EOF

cat > ca-csr.json <<EOF
{
  "CN": "Kubernetes",
  "key": { "algo": "rsa", "size": 2048 },
  "names": [{ "C": "RU", "L": "Minsk", "O": "Kubernetes", "OU": "CA", "ST": "Belarus" }]
}
EOF

cfssl gencert -initca ca-csr.json | cfssljson -bare ca

# 2. Компоненты (admin, kube-controller-manager, kube-proxy, kube-scheduler, service-account)
COMPONENTS=("admin" "kube-controller-manager" "kube-proxy" "kube-scheduler" "service-account")

for component in "${COMPONENTS[@]}"; do
  # Значения по умолчанию
  CN="system:$component"
  ORG="system:$component"

  # Точечные переопределения
  if [[ "$component" == "admin" ]]; then
    CN="admin"
    ORG="system:masters"
  elif [[ "$component" == "kube-proxy" ]]; then
    ORG="system:node-proxies"
  elif [[ "$component" == "service-account" ]]; then
    CN="service-account"
    ORG="Kubernetes"
  fi

  cat > ${component}-csr.json <<EOF
{
  "CN": "$CN",
  "key": { "algo": "rsa", "size": 2048 },
  "names": [{ "C": "RU", "L": "Minsk", "O": "$ORG", "OU": "Kubernetes", "ST": "Belarus" }]
}
EOF
  cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes ${component}-csr.json | cfssljson -bare ${component}
done

# 3. Workers (Kubelet)
for i in "${!WORKERS[@]}"; do
  instance="worker-${i}"
  ip="${WORKERS[$i]}"
  cat > ${instance}-csr.json <<EOF
{
  "CN": "system:node:${instance}",
  "key": { "algo": "rsa", "size": 2048 },
  "names": [{ "C": "RU", "L": "Minsk", "O": "system:nodes", "OU": "Kubernetes", "ST": "Belarus" }]
}
EOF
  cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -hostname=${instance},${ip} -profile=kubernetes ${instance}-csr.json | cfssljson -bare ${instance}
done

# 4. Kubernetes API Server (исправлено - отдельный блок)
CERT_HOSTNAME="127.0.0.1,${K8S_SERVICE_IP},kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster.local"
for ip in "${CONTROLLERS[@]}"; do CERT_HOSTNAME="${CERT_HOSTNAME},${ip}"; done

cat > kubernetes-csr.json <<EOF
{
  "CN": "kubernetes",
  "key": { "algo": "rsa", "size": 2048 },
  "names": [{ "C": "RU", "L": "Minsk", "O": "Kubernetes", "OU": "Kubernetes", "ST": "Belarus" }]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=${CERT_HOSTNAME} \
  -profile=kubernetes \
  kubernetes-csr.json | cfssljson -bare kubernetes

# 5. ETCD сертификаты (исправлено - правильные hostname для каждого узла)
for i in 0 1 2; do
  instance="controller-${i}"
  ip="${CONTROLLERS[$i]}"

  # Серверный сертификат etcd (peer-to-peer и client connections)
  cat > ${instance}-etcd-csr.json <<EOF
{
  "CN": "${instance}",
  "hosts": ["${ip}", "127.0.0.1"],
  "key": { "algo": "rsa", "size": 2048 },
  "names": [{ "C": "RU", "L": "Minsk", "O": "Kubernetes", "OU": "etcd", "ST": "Belarus" }]
}
EOF

  cfssl gencert \
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=ca-config.json \
    -profile=kubernetes \
    ${instance}-etcd-csr.json | cfssljson -bare ${instance}-etcd
done

# 6. ETCD клиентский сертификат для kube-apiserver
cat > etcd-client-csr.json <<EOF
{
  "CN": "etcd-client",
  "key": { "algo": "rsa", "size": 2048 },
  "names": [{ "C": "RU", "L": "Minsk", "O": "Kubernetes", "OU": "etcd-client", "ST": "Belarus" }]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  etcd-client-csr.json | cfssljson -bare etcd-client

echo "Генерация завершена. Создано файлов: $(ls *.pem 2>/dev/null | wc -l)"
