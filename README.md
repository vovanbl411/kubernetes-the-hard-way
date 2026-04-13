# Kubernetes The Hard Way: Automation Edition

Этот репозиторий содержит всё необходимое для развертывания полностью функционального кластера Kubernetes «с нуля» на локальном гипервизоре QEMU/KVM.

Цель проекта — пройти путь Kubernetes The Hard Way, автоматизировав рутинные операции (создание ВМ, генерация PKI), но сохранив прозрачность настройки компонентов.

## Архитектура

* **OS**: Ubuntu 24.04 (Cloud Image).
* **Hypervisor**: Libvirt / QEMU / KVM.
* **Network**: NAT-сеть 10.0.0.0/24.
* **Control Plane**: 3 узла (controller-0..2).
* **Workers**: 3 узла (worker-0..2).
* **Pod Network**: Статическая маршрутизация, Pod CIDR 10.200.x.0/24.
* **State**: Terraform стейт хранится в локальном S3 (Minio).

## Дорожная карта развертывания

### 0. Подготовка (Root)

Скопируйте шаблон секретов и настройте свои данные:

```bash
cp .env.example .env.local
# Отредактируйте .env.local (пароли, пути к ключам)
source .env.local
```

### 1. State Backend (/minio-state)

Поднимаем локальное хранилище для стейта Terraform:

```bash
cd minio-state
docker compose up -d
# Создайте бакет 'terraform-state' в консоли :9001
```

> Подробнее: [minio-state/README.md](minio-state/README.md)

### 2. Инфраструктура (/terraform)

Создаем виртуальные машины и сеть:

```bash
cd terraform
terraform init
terraform apply
```

Terraform автоматически сгенерирует `ansible/inventory.ini`.

> Подробнее: [terraform/README.md](terraform/README.md)

### 3. Безопасность и PKI (/certs)

Генерируем удостоверяющий центр (CA), сертификаты компонентов и конфиги:

```bash
cd certs
./generate_certs.sh
./generate_configs.sh
```

> Подробнее: [certs/README.md](certs/README.md)

### 4. Автоматизация (/ansible)

Конфигурируем ОС и поднимаем компоненты Kubernetes:

```bash
cd ansible
ansible-playbook master.yml
```

> Подробнее: [ansible/README.md](ansible/README.md)

## Сетевая схема

| Node | IP | Pod CIDR | Роль |
|---|---|---|---|
| controller-0 | 10.0.0.10 | - | API, ETCD, Scheduler |
| worker-0 | 10.0.0.20 | 10.200.0.0/24 | Containerd, Kubelet |
| worker-1 | 10.0.0.21 | 10.200.1.0/24 | Containerd, Kubelet |

> Важно: В данном проекте используется статическая маршрутизация между нодами. Маршруты до Pod CIDR прописываются на каждой ноде через Ansible (плейбук `workers.yml`), что избавляет от необходимости использовать тяжелые CNI на этапе обучения.

## Полезные команды (Troubleshooting)

Проверка статуса компонентов:

```bash
# На любом контроллере
kubectl get componentstatuses --kubeconfig /var/lib/kubernetes/admin.kubeconfig
```

Проверка логов через journalctl:

```bash
# Если что-то не заводится (например, kubelet)
journalctl -u kubelet -f
```

Доступ к ВМ:

```bash
# Все ВМ используют ваш публичный ключ из ~/.ssh/id_ed25519
ssh vladimir@10.0.0.20
```
