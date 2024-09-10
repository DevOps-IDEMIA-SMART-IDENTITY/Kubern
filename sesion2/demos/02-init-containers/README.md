# Init containers

Este ejemplo define un simple Pod que tiene dos init containers. El primero espera a myservice, y el segundo espera a mydb. Una vez que ambos init containers finalizan, el Pod ejecuta el contenedor de la aplicación de su sección spec.

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
    command: ['sh', '-c', 'echo The app is running! && sleep 3600']
  initContainers:
  - name: init-myservice
    image: busybox:1.28
    command: ['sh', '-c', "until nslookup myservice.$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace).svc.cluster.local; do echo waiting for myservice; sleep 2; done"]
  - name: init-mydb
    image: busybox:1.28
    command: ['sh', '-c', "until nslookup mydb.$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace).svc.cluster.local; do echo waiting for mydb; sleep 2; done"]
```

Para lanzar el ejemplo:

```shell
kubectl apply -f 01-pod.yaml
```

Tras lanzarlo, podemos ver su estado con:

```shell
kubectl get -f 01-pod.yaml
```

Para ver los logs de los init containers:

```shell
kubectl logs myapp-pod -c init-myservice
kubectl logs myapp-pod -c init-mydb
```

Podemos ver que los pods no se están creando correctamente. Esto es porque no existe un servicio llamado `myservice` ni `mydb`. Necesitamos crear lo siguiente:

```shell
---
apiVersion: v1
kind: Service
metadata:
  name: myservice
spec:
  ports:
  - protocol: TCP
    port: 80
    targetPort: 9376
---
apiVersion: v1
kind: Service
metadata:
  name: mydb
spec:
  ports:
  - protocol: TCP
    port: 80
    targetPort: 9377
```

Podemos crear los servicios con:

```shell
kubectl apply -f 02-service.yaml
```

## Referencias
- https://kubernetes.io/docs/concepts/workloads/pods/init-containers/#init-containers-in-use