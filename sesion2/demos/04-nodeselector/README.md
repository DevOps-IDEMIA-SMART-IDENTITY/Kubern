# NodeSelector

El siguiente ejemplo muestra cómo asignar un pod a un nodo específico usando un `nodeSelector`.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nodeselector-pod
  labels:
    app.kubernetes.io/name: nodeselector-app
spec:
  nodeSelector:
    bootcamp: keepcoding
  containers:
  - name: nodeselector-container
    image: busybox:1.28
    command: ['sh', '-c', 'echo The app is running! && sleep 3600']
```

Para lanzar el ejemplo ejecutamos:

```shell
kubectl apply -f 01-pod.yaml
```

Para ver el estado del pod desde otro terminal

```shell
kubectl get pod nodeselector-pod -w
```

Ahora, veremos que el pod se queda en estado `Pending`. Esto es porque no hay ningún nodo con la etiqueta `bootcamp=keepcoding`.

Para solucionarlo, primero vemos los nodos y sus etiquetas:

```shell
kubectl get nodes --show-labels
```

Y luego etiquetamos el nodo:

```shell
kubectl label nodes <your-node-name> bootcamp=keepcoding
```
