# Nginx chart
This is a helm nginx chart to create sample E
## Prerequisites
Install helm and kubectl
Configure kubectl context to connect to Minikube or Kubernetes cluster
## Usage
Clone repository and make application_deploy.sh executable
```
 > git clone https://github.com/r00tvvm/nginx-chart.git && cd nginx_chart
 > chmod +x deploy.sh
 > deploy.sh -h
  Usage: deploy.sh -c CHART_NAME -n NAMESPACE [-r REPO_URL] [command]
  Options:
    -h, --help           output help information
    -c, --chart          chart name to be installed
    -r, --repo           repository to pull chart from
  Commands:
    [command]            list of helm commands and options to be executed subsequently
                         if 'del' command provided all other commands 
```

## Install Helm chart application to local helm repository
```
deploy.sh -c nginx-chart pull
```

## Deploy Helm chart application to Minikube or Kubernetes cluster
```
deploy.sh -c nginx-chart -n NAMESPACE install
```

## Show Helm application running in Minikube or Kubernetes cluster
```
deploy.sh -n NAMESPACE -c nginx-chart
```

## Test applcation up and running
* Local kubernetes cluster
```
   # get local norePort
   echo -n "curl localhost:$(kubectl get svc nginx-chart -o 'jsonpath={..spec.ports[0].nodePort}')"
```
* Minikube or Kubertenes cluster with ingress controller setup
```
   
```

## Delete Helm chart from Minikube or Kubernetes cluster
```
deploy.sh -c nginx-chart -n NAMESPACE del
```

## Degugging
Run busybox
```
kubectl run busybox -it --image=odise/busybox-curl --restart=Never --rm
> curl <chart_name>.<namespace>.svc.cluster.local
```

