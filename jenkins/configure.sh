#!/usr/bin/env bash

kubectl create ns jenkins
#Install jenkins operator
#Create CRDs
kubectl apply -f https://raw.githubusercontent.com/jenkinsci/kubernetes-operator/master/deploy/crds/jenkins_v1alpha2_jenkins_crd.yaml
#Deploy Jenkins operator
kubectl apply -f https://raw.githubusercontent.com/jenkinsci/kubernetes-operator/master/deploy/all-in-one-v1alpha2.yaml -n jenkins

kubectl wait -n jenkins pod -l name=jenkins-operator --for=condition=Ready --timeout=300s

#Create jenkins Instance
read -p "Enter Github username: " GIT_USER
read -p "Enter Github token/password: " GIT_PASSWORD

kubectl -n jenkins create secret generic jenkins-operator --from-literal=username=$GIT_USER --from-literal=password=$GIT_PASSWORD

kubectl create -f jenkins_instance.yaml -n jenkins

kubectl apply -f jenkins_nodeport.yaml -n jenkins

#Webhook webrelay
echo "Please login to https://my.webhookrelay.com/ and get your tokens"

read -p "Enter RELAY KEY: " RELAY_KEY
read -p "Enter RELAY SECRET: " RELAY_SECRET

helm repo add webhookrelay https://charts.webhookrelay.com
helm repo update

helm upgrade --install webhookrelay-operator --namespace=jenkins webhookrelay/webhookrelay-operator \
  --set credentials.key=$RELAY_KEY --set credentials.secret=$RELAY_SECRET

kubectl wait -n jenkins pod -l app.kubernetes.io/instance=webhookrelay-operator --for=condition=Ready --timeout=300s

kubectl apply -n jenkins -f webhookrelay_cr.yaml
kubectl wait -n jenkins pod -l jenkins-cr=cicd --for=condition=Ready --timeout=300s
kubectl wait -n jenkins pod -l name=webhookrelay-forwarder --for=condition=Ready --timeout=300s

kubectl create namespace production
#This is done for ease of access to resources  , in production we should use a more secure approach
kubectl -n production create rolebinding jenkins --clusterrole=admin --serviceaccount=jenkins:default


read -p "Enter Path to docker config.yaml file: " DOCKERPATH
kubectl -n jenkins create secret generic docker-secret --from-file=$DOCKERPATH

echo "Jenkins url : http://$(minikube ip):32767"
echo $'\n'"Jenkins User"
kubectl -n jenkins get secret jenkins-operator-credentials-cicd -o 'jsonpath={.data.user}' | base64 -d
echo $'\n'"Jenkins Password"
kubectl -n jenkins get secret jenkins-operator-credentials-cicd -o 'jsonpath={.data.password}' | base64 -d

echo $'\n'"You can now login to Jenkins and manually trigger the first build"
echo $'\n'"Or for Auto build triggers login to https://my.webhookrelay.com/buckets and get your webhook public url, configure that on your app git repo"

