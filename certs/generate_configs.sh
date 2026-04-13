#!/bin/bash

# Публичный адрес для доступа к API (используем IP первого контроллера)
KUBERNETES_ADDRESS="10.0.0.10"

# Генерируем конфиги для воркеров (Kubelet)
for instance in worker-0 worker-1 worker-2;
do
    kubectl config set-cluster kubernetes-the-hard-way --server=https://${KUBERNETES_ADDRESS}:6443 --certificate-authority=ca.pem --embed-certs=true --kubeconfig=${instance}.kubeconfig
    kubectl config set-credentials system:node:${instance} --client-certificate=${instance}.pem --client-key=${instance}-key.pem --embed-certs=true --kubeconfig=${instance}.kubeconfig
    kubectl config set-context default --cluster=kubernetes-the-hard-way --user=system:node:${instance} --kubeconfig=${instance}.kubeconfig
    kubectl config use-context default --kubeconfig=${instance}.kubeconfig
done

# Генерируем конфиги для остальных компонентов
COMPONENTS=("kube-proxy" "kube-controller-manager" "kube-scheduler" "admin")
for comp in "${COMPONENTS[@]}";
do
    kubectl config set-cluster kubernetes-the-hard-way --server=https://${KUBERNETES_ADDRESS}:6443 --certificate-authority=ca.pem --embed-certs=true --kubeconfig=${comp}.kubeconfig
    kubectl config set-credentials system:${comp} --client-certificate=${comp}.pem --client-key=${comp}-key.pem --embed-certs=true --kubeconfig=${comp}.kubeconfig
    kubectl config set-context default --cluster=kubernetes-the-hard-way --user=system:${comp} --kubeconfig=${comp}.kubeconfig
    kubectl config use-context default --kubeconfig=${comp}.kubeconfig
done

for instance in controller-0 controller-1 controller-2; do
    kubectl config set-cluster kubernetes-the-hard-way \
        --server=https://127.0.0.1:2379 \
        --certificate-authority=ca.pem \
        --embed-certs=true \
        --kubeconfig=${instance}-etcd.kubeconfig

    kubectl config set-credentials etcd-client \
        --client-certificate=etcd-client.pem \
        --client-key=etcd-client-key.pem \
        --embed-certs=true \
        --kubeconfig=${instance}-etcd.kubeconfig

    kubectl config set-context default \
        --cluster=kubernetes-the-hard-way \
        --user=etcd-client \
        --kubeconfig=${instance}-etcd.kubeconfig

    kubectl config use-context default --kubeconfig=${instance}-etcd.kubeconfig
done

echo "Конфиги для всех компонентов сгенерированы."
