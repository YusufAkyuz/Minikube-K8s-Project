#!/bin/bash

# 3 worker node'u production için işaretleyelim
# Node 2, 3 ve 4'ü production için ayıralım

echo "Production node'ları için taint ekleniyor..."

# Node'lara taint ekleyelim
kubectl taint nodes minikube-m02 environment=production:NoSchedule
kubectl taint nodes minikube-m03 environment=production:NoSchedule
kubectl taint nodes minikube-m04 environment=production:NoSchedule

# Node'lara label ekleyelim (kolay tanımlama için)
kubectl label nodes minikube-m02 node-role=production
kubectl label nodes minikube-m03 node-role=production
kubectl label nodes minikube-m04 node-role=production

# Test node'una da label ekleyelim
kubectl label nodes minikube-m05 node-role=test

echo "Node yapılandırması tamamlandı!"

# Kontrol
echo "Node durumları:"
kubectl get nodes --show-labels
kubectl describe nodes | grep -A 3 "Taints"