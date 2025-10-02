#!/bin/bash

# project-verification.sh
# Tüm proje gereksinimlerinin kontrolü

echo "======================================"
echo "KUBERNETES PROJESİ DOĞRULAMA"
echo "======================================"

# Renkli output için
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $1"
    else
        echo -e "${RED}✗${NC} $1"
    fi
}

echo -e "\n${YELLOW}1. CLUSTER YAPILANDIRMASI${NC}"
echo "-----------------------------------"
NODE_COUNT=$(kubectl get nodes --no-headers | wc -l)
if [ "$NODE_COUNT" -eq 5 ]; then
    echo -e "${GREEN}✓${NC} 5 node'lu cluster (1 master + 4 worker)"
else
    echo -e "${RED}✗${NC} Node sayısı: $NODE_COUNT (5 olmalı)"
fi
kubectl get nodes

echo -e "\n${YELLOW}2. NAMESPACE'LER${NC}"
echo "-----------------------------------"
kubectl get ns test &>/dev/null
check_status "test namespace"
kubectl get ns production &>/dev/null
check_status "production namespace"

echo -e "\n${YELLOW}3. RBAC YAPILANDIRMASI${NC}"
echo "-----------------------------------"
kubectl get role junior-developer-test-full-access -n test &>/dev/null
check_status "Junior test role"
kubectl get role junior-developer-production-read-only -n production &>/dev/null
check_status "Junior production role"
kubectl get role senior-developer-test-full-access -n test &>/dev/null
check_status "Senior test full access role"
kubectl get role senior-developer-production-full-access -n production &>/dev/null
check_status "Senior production role"
kubectl get clusterrole senior-developer-cluster-read-only &>/dev/null
check_status "Senior cluster role"

echo -e "\n${YELLOW}4. INGRESS CONTROLLER${NC}"
echo "-----------------------------------"

# Service kontrolü
kubectl get svc ingress-nginx-controller -n ingress-nginx &>/dev/null
check_status "NGINX Ingress Controller Service"

# Pod kontrolü
kubectl get pods -n ingress-nginx -l app.kubernetes.io/component=controller | grep -q Running
check_status "NGINX Ingress Controller Pod"

echo -e "\n${YELLOW}5. NODE TAINTS (Production)${NC}"
echo "-----------------------------------"
for node in minikube-m02 minikube-m03 minikube-m04; do
    kubectl describe node $node | grep -q "environment=production:NoSchedule"
    check_status "$node production taint"
done

echo -e "\n${YELLOW}6. WORDPRESS DEPLOYMENTS${NC}"
echo "-----------------------------------"
kubectl get deployment wordpress -n test &>/dev/null
check_status "WordPress test deployment"
kubectl get deployment wordpress -n production &>/dev/null
check_status "WordPress production deployment"
kubectl get deployment mysql -n test &>/dev/null
check_status "MySQL test deployment"
kubectl get deployment mysql -n production &>/dev/null
check_status "MySQL production deployment"

echo -e "\n${YELLOW}7. INGRESS CONFIGURATION${NC}"
echo "-----------------------------------"
kubectl get ingress -n test | grep -q testblog.example.com
check_status "testblog.example.com ingress"
kubectl get ingress -n production | grep -q companyblog.example.com
check_status "companyblog.example.com ingress"

echo -e "\n${YELLOW}8. K8S APP DEPLOYMENT${NC}"
echo "-----------------------------------"
REPLICAS=$(kubectl get deployment k8s-app -n production -o jsonpath='{.spec.replicas}' 2>/dev/null)
IMAGE=$(kubectl get deployment k8s-app -n production -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
echo "Replicas: $REPLICAS (10 olmalı)"
echo "Image: $IMAGE (ozgurozturknet/k8s:v2 olmalı)"

echo -e "\n${YELLOW}9. LOADBALANCER SERVICE${NC}"
echo "-----------------------------------"
kubectl get svc k8s-app-lb -n production | grep -q LoadBalancer
check_status "LoadBalancer service"

echo -e "\n${YELLOW}10. DEPLOYMENT SCALING${NC}"
echo "-----------------------------------"
echo "Deployment history:"
kubectl rollout history deployment/k8s-app -n production

echo -e "\n${YELLOW}11. FLUENTD DAEMONSET${NC}"
echo "-----------------------------------"
kubectl get daemonset fluentd -n kube-system &>/dev/null
check_status "Fluentd DaemonSet"
FLUENTD_PODS=$(kubectl get pods -n kube-system -l app=fluentd --no-headers | wc -l)
echo "Fluentd pod sayısı: $FLUENTD_PODS"

echo -e "\n${YELLOW}12. MONGODB STATEFULSET${NC}"
echo "-----------------------------------"
kubectl get statefulset mongodb &>/dev/null
check_status "MongoDB StatefulSet"
MONGO_PODS=$(kubectl get pods -l app=mongodb --no-headers | grep Running | wc -l)
if [ "$MONGO_PODS" -eq 2 ]; then
    echo -e "${GREEN}✓${NC} MongoDB 2 node cluster çalışıyor"
else
    echo -e "${RED}✗${NC} MongoDB pod sayısı: $MONGO_PODS (2 olmalı)"
fi

echo -e "\n${YELLOW}13. SERVICE ACCOUNT${NC}"
echo "-----------------------------------"
kubectl get sa cluster-reader &>/dev/null
check_status "cluster-reader ServiceAccount"
kubectl get pod api-test-pod &>/dev/null
check_status "API test pod"

echo -e "\n======================================"
echo -e "${GREEN}DOĞRULAMA TAMAMLANDI!${NC}"
echo "======================================"