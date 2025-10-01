#!/bin/bash

# node-drain-operations.sh
# Worker node tahliye ve cordon işlemleri

echo "================================================"
echo "Node Drain ve Cordon İşlemleri"
echo "================================================"

# Mevcut node'ları listele
echo -e "\n1. Mevcut Node'lar ve Pod Dağılımı:"
echo "-----------------------------------"
kubectl get nodes -o wide
echo ""
kubectl get pods --all-namespaces -o wide | grep -E "NAMESPACE|minikube-m05"

# Tahliye edilecek node
TARGET_NODE="minikube-m05"

echo -e "\n2. $TARGET_NODE üzerindeki mevcut pod'lar:"
echo "-----------------------------------"
kubectl get pods --all-namespaces --field-selector spec.nodeName=$TARGET_NODE

# Node'u cordon et (yeni pod kabul etme)
echo -e "\n3. Node'u cordon ediyorum (yeni pod'ları kabul etmeyecek):"
echo "-----------------------------------"
kubectl cordon $TARGET_NODE

# Cordon durumunu kontrol et
echo -e "\n4. Node durumu (SchedulingDisabled olmalı):"
echo "-----------------------------------"
kubectl get nodes $TARGET_NODE

# Node'u drain et (mevcut pod'ları tahliye et)
echo -e "\n5. Node'u drain ediyorum (mevcut pod'ları tahliye):"
echo "-----------------------------------"
# DaemonSet'leri ignore et, pod'ları sil ve graceful period kullan
kubectl drain $TARGET_NODE \
    --ignore-daemonsets \
    --delete-emptydir-data \
    --force \
    --grace-period=30

# Drain sonrası durumu kontrol et
echo -e "\n6. Drain sonrası node üzerindeki pod'lar (sadece DaemonSet'ler kalmalı):"
echo "-----------------------------------"
kubectl get pods --all-namespaces --field-selector spec.nodeName=$TARGET_NODE

echo -e "\n7. Tahliye edilen pod'ların yeni konumları:"
echo "-----------------------------------"
kubectl get pods --all-namespaces -o wide | grep -v $TARGET_NODE | head -20

echo -e "\n8. Node'un son durumu:"
echo "-----------------------------------"
kubectl describe node $TARGET_NODE | grep -A 5 "Taints:"
kubectl get nodes

echo -e "\n================================================"
echo "İşlem Tamamlandı!"
echo "================================================"
echo ""
echo "Node'u tekrar aktif etmek için:"
echo "kubectl uncordon $TARGET_NODE"
echo ""
echo "Taint'i kaldırmak için (eğer eklendiyse):"
echo "kubectl taint nodes $TARGET_NODE node.kubernetes.io/unschedulable-"