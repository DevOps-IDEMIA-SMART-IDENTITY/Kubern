<a name="resources"></a>
# Scheduling

Indice de contenidos:

- [NodeSelector](#node-selector)
- [Node affinity](#node)
- [Pod affinity y anti-affinity](#pod)
- [Taints y Tolerations](#taints)

Los ejemplos propuestos están planteados sobre un cluster GKE con 3 nodos.

- [NodeSelector](#node-selector) (scheduling básico)

<a name="node-selector"></a>
### NodeSelector

NodeSelector nos ofrece seleccionar los nodos que podrán ejecutar nuestros pods. Es el nivel más básico de `scheduling` en Kubernetes.

- El siguiente pod sólo podrá ser ejecutado en nodos con label `disktype=ssd`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-ssd
  labels:
    env: test
spec:
  containers:
  - name: nginx
    image: nginx
    imagePullPolicy: IfNotPresent
  nodeSelector:
    disktype: ssd
```

Para lanzarlo:
```
kubectl apply -f resources/nodeSelector.yaml
```

Al no tener nodos con ese tag el pod se quedará en estado `Pending` con el mensaje (describe):

```
$ kubectl describe pod nginx-ssd
Events:
  Type     Reason             Age                From                Message
  ----     ------             ----               ----                -------
  Warning  FailedScheduling   18s (x2 over 20s)  default-scheduler   0/3 nodes are available: 3 node(s) didn't match Pod's node affinity/selector.
  Normal   NotTriggerScaleUp  18s                cluster-autoscaler  pod didn't trigger scale-up:
```

Para solucionarlo podemos añadir el label a uno de los nodos:

```
kubectl label node gke-keepcoding-default-pool-5a194f9d-phgm disktype=ssd
```

Tras añadir el label el pod arrancará en el nodo correspondiente.

<a name="node"></a>
## nodeAffinity

Para las pruebas de `afinidad` añadiremos a uno de nuestros nodos el label `apps=frontend`:

```
kubectl label node node3 apps=frontend
```

El siguiente ejemplo define deployment NGINX (de una sola réplica) con las siguientes reglas de afinidad:
- Requerida: Que no se pueda ejecutar en el no con hostname (label `kubernetes.io/hostname`) `node3`
- Preferida: Nodo con tag `apps` con valor `frontend`.
- Además el contenedor requerirá `200m` vCPUs.

Cambia el yaml para que incluya el hostname de uno de los nodos que no tienen el label.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-affinity
spec:
  selector:
    matchLabels:
      app: nginx-affinity
  replicas: 1
  template:
    metadata:
      labels:
        app: nginx-affinity
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: kubernetes.io/hostname
                operator: NotIn
                values:
                - gke-keepcoding-default-pool-f89b3810-51h7
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 1
            preference:
              matchExpressions:
              - key: apps
                operator: In
                values:
                - frontend
      containers:
      - name: nginx
        image: nginx:1.9.1
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 200m
```

Crea el deployment y comprueba como se crea en el nodo con el label:

```
kubectl apply -f resources/nginx-affinity.yaml
```

Escala el deployment a 2 o 3 replicas, comprueba como todas se crean en el mismo nodo (hasta que quede sin recursos):
```
kubectl scale deployment nginx-affinity --replicas 2
```

Escalalo hasta que se no haya manera de añadir pods, comprueba que ninguno está asociado al nodo que excluíamos en el ejemplo.

<a name="pod"></a>
## podAffinity y antiAffinity

Vamos a suponer que tenemos un redis y una aplicación web y queremos:
- Que los pods de redis no puedan compartir host.
- Que los pods de la aplicación web estén en distintos hosts siempre y además que estén en nodos donde haya algún redis.

Esto lo podríamos implementar de la siguiente manera:

- Redis: Los pods no pueden estar (`antiAffinity`) en nodos (`topologyKey --> hostname`) donde ya exista un pod con label `redis=cache` (su propio label). Esto los separará obligatoriamente (`required`).

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-pod-affinity
spec:
  selector:
    matchLabels:
      app: redis-cache
  replicas: 3
  template:
    metadata:
      labels:
        app: redis-cache # LABEL DEL POD
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - redis-cache
            topologyKey: "kubernetes.io/hostname"
      containers:
      - name: redis-server
        image: redis:3.2-alpine
```

- Aplicación web: queremos separar de pods del mismo deployment (al igual que antes) y además exigir que se haga el scheduling en maquinas donde haya pods con `app=redis-cache` (los redis)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-server-pod-affinity
spec:
  selector:
    matchLabels:
      app: web-store
  replicas: 3
  template:
    metadata:
      labels:
        app: web-store
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - web-store
            topologyKey: "kubernetes.io/hostname"
        podAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - redis-cache
            topologyKey: "kubernetes.io/hostname"
      containers:
      - name: web-app
        image: nginx:1.16-alpine
```

Comienza lanzando el manifiesto del servicio web y analiza qué ocurre:

```
kubectl apply -f resources/web-server-pod-affinity.yaml
```

Al lanzar solamente el servicio se queda todo en `Pending`, esto es normal debido a las reglas y a que `redis` todavía no está en ningún nodo, por lo que no se pueden cumplir.

Si hacemos un describe de alguno de los pods veremos algo como:

```
Events:
  Type     Reason             Age                From                Message
  ----     ------             ----               ----                -------
  Normal   NotTriggerScaleUp  97s                cluster-autoscaler  pod didn't trigger scale-up:
  Warning  FailedScheduling   12s (x3 over 99s)  default-scheduler   0/3 nodes are available: 3 node(s) didn't match pod affinity rules, 3 node(s) didn't match pod affinity/anti-affinity rules.
```

Lanzamos ahora redis y veremos que todo levanta:
```
kubectl apply -f resources/redis-pod-affinity.yaml
```


<a name="taints"></a>
## Taints y Tolerations


Para crear un taint:
```
kubectl taint nodes host1 special=true:NoSchedule
```

Para eliminar taint añadimos un `-` a la definición del taint.
```
kubectl taint nodes host1 special:NoSchedule-
```

Ejemplo, imaginamos que tenemos una serie de nodos donde queremos desplegar las aplicaciones exclusivas de monitorización, podríamos añadir taint a esos nodos de esta forma:
```
kubectl taint nodes monitoring-node01 area=monitoring:NoSchedule
```

Las workloads de monitorización tendrían que tener un toleration como este para poder ser incluidas en ese grupo de nodos:
```yaml
        tolerations:
          - key: "area"
            operator: "Equal"
            value: "monitoring"
            effect: "NoSchedule"
```

Pero __recuerda__! Los tolerations en los pods no impiden que los pods vayan a cualquier nodo sin taints. Un toleration implica que el nodo tolera el taint, pero no quiere decir que tenga que ir a nodos con ese taint.


Cuando se quieren nodos dedicados se utiliza una __combinación de taints / tolerations con reglas de afinidad__, a no ser que todos los nodos de tu cluster tengan taints.


Para finalizar un ejemplo de toleration para aceptar cualquier tipo de taint. Útil por ejemplo en un `DaemonSet` que queremos que se salte los taints (que tolere todo).

```
        # tolerate any taint (we want it to run in all nodes). Irrelevant if k8s taints not used
        tolerations:
          - effect: NoExecute
            operator: Exists
          - effect: NoSchedule
            operator: Exists
          - key: CriticalAddonsOnly
            operator: Exists
```
