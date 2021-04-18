## Description
This code base allows you to create a minikube setup using ansible
Then it lets you deploy Jenkins kubernetes Operator which runs on minikube.(I haven't used Azure Devops) 
Jenkins operator auto creates jobs based on the job  [seed repo](https://github.com/srvmsr/testapi/tree/master/cicd/jobs)
And configures a ci cd job to build and deploy  TestApi on minikube.
CICD job is auto triggered whenever a new tag or commit is detected on the Applictaion Repo [seed repo](https://github.com/srvmsr/testapi)

## Prerequisites

A ubuntu/centos VM or host
1. [helm](https://helm.sh/docs/intro/install/)
2. [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
3. [Webhookrelay Tokens](https://my.webhookrelay.com/) Used to connect Jenkins to track Github changes.
      Signup and create a pair of token from 
      https://my.webhookrelay.com/tokens

## Installing your Minikube instance using ansible
[Run minikube installtion ](ansible/install.sh)

***Change the inventory file if not on localhost***

Once Minikube is ready 
You can open dashbord with **minikube dashboard command**

## Install Jenkins Operator and jenkins Instance
[Prepare cicd setup with jenkins](configure.sh) 

I am using Jenkins operator for ease of use as a all in one Jenkins setup.
Detailed documentaion can be found [here](https://jenkinsci.github.io/kubernetes-operator/docs/)


Once jenkins operator is deployed we will also deploy
webhookrelay operator to create a webhook url for the jenkins. Configuration script will take you through all the necessary steps to configure it.
Once you have got the webhookrelay url, configure it on the got repo  which you want to trigger builds.

## TestApi app

TestApi application code can be found at  [TestApi](https://github.com/srvmsr/testapi.git) is configured to be used for deployment

Jenkins operator automatically discovers the job to be created .

Deployment is auto tiggered whenever there is a push to the repository.
Jenkins builds the application and create a runtime docker image using multistage Build.

Versioning of the app is done based on the TAGs on the app repository.
If no tags are found , version is set to current date and commit id.

Application is exposed on http://<MinikubeIP>:30501/weatherforecast and internally within Kubernetes cluster on http://app:5001/weatherforecast

Issues:
- VM may have soft lock/crash . While setting us minikube on Virtualbox environment with nested virtualization. Its a open bug [currently](https://www.virtualbox.org/ticket/19561)
- Issue with DNS resolution on jenkins agent pods, to resolve edit core dns config to use google dns instead of loopback address.My resolution can be found [here](https://github.com/kubernetes/minikube/issues/7512#issuecomment-664348459).
- Official documents of jenkins-operator mentions [wrong](https://github.com/jenkinsci/kubernetes-operator/blob/master/cicd/pipelines/build.jenkins#L5) workspace location on jenkins agents. It should be set to **/home/jenkins/agent/workspace/**


