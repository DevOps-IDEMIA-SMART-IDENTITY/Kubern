# Pods

El siguiente ejemplo muestra cómo definir un Pod simple con un contenedor que ejecuta un comando.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod
  labels:
    app.kubernetes.io/name: MyApp
spec:
  containers:
  - name: myapp-container
    image: busybox:1.28
    command: ['sh', '-c', 'echo Hello Kubernetes! && sleep 3600']
```

Para lanzar el pod ejecutamos:

```shell
kubectl apply -f 01-pod.yaml
```

Para ver el estado del pod ejecutamos:

```shell
kubectl get pod myapp-pod
```

Para ver los logs del pod ejecutamos:

```shell
kubectl logs myapp-pod
```

Para ver más detalles del pod (eventos, etc.) ejecutamos:

```shell
kubectl describe pod myapp-pod
```
