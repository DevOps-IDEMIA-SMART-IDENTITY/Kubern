<a name="autoscaling"></a>
# Autoescalado

Índice de contenidos:

- [Setup inicial](#start)
- [Horizontal Pod Autoscaling (HPA)](#hpa)
- [Cluster Autoscaling](#cluster)

<a name="start"></a>
## Setup inicial

La funcionalidad HPA depende del metrics server de Kubernetes (instalado por defecto con la mayoría de instaladores o entornos SaaS). En minikube se puede integrar metrics server con el siguiente comando:

```bash
minikube addons enable metrics-server
```

Creamos deployment NGINX, expuesto mediante servicio:
- Una sola réplica
- requests.cpu: 100m
- requests.limit: 200m

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-hpa
spec:
  selector:
    matchLabels:
      app: nginx-hpa
  replicas: 1
  template:
    metadata:
      labels:
        app: nginx-hpa
    spec:
      containers:
      - name: nginx
        image: nginx:1.9.1
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 100m
          limits:
            cpu: 200m
```

Creamos el deployment:

```bash
kubectl apply -f resources/nginx-hpa.yaml
```

Creamos el servicio mediante `kubectl expose` (best practice: `YAML con servicio definido`):
```bash
kubectl expose deployment nginx-hpa --port 80
```

Comprobamos que se crea el servicio `nginx-hpa`.


<a name="hpa"></a>
## Horizontal Pod Autoscaling (HPA)

```bash
kubectl autoscale deploy nginx-hpa --cpu-percent=20 --min=2 --max=20
```

Podemos observar el `spec` del recurso creado con:

```bash
kubectl get hpa nginx-hpa -o=yaml
```

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: nginx-hpa
spec:
  maxReplicas: 20
  metrics:
  - resource:
      name: cpu
      target:
        averageUtilization: 20
        type: Utilization
    type: Resource
  minReplicas: 2
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: nginx-hpa
```

(Este es un buen ejemplo para ver cómo va cambiando la spec de algunos recursos a medida que Kubernetes evoluciona)

Ahora lanzaremos un Deployment que genere carga, por ejemplo:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: load-generator
spec:
  selector:
    matchLabels:
      app: load-generator
  replicas: 1
  template:
    metadata:
      labels:
        app: load-generator
    spec:
      containers:
      - name: busybox
        image: busybox:1.28
        command: ["sh"]
        args: ["-c", "while true; do wget -q -O- http://nginx-hpa >dev/null 2>&1; done"]
```

Otra manera de lanzar algo similar manualmente sería con este comando:
```bash
kubectl run load-generator-manual --image=busybox --command -- sh -c 'while true; do wget -q -O- http://nginx-hpa >dev/null 2>&1; done'
```

El deployment nos permitirá añadir replicas y generar más carga de forma fácil :)

```bash
kubectl apply -f resources/load-generator-dep.yaml
```

Observamos en diferentes ventanas:
- `kubectl get hpa -w`
- `kubectl get pod -w`

Si la carga no sube añadimos réplicas al generador de carga:
```bash
kubectl scale deployment load-generator --replicas=4
```

<a name="cluster"></a>
## Cluster Autoscaling

El autoescalado del cluster requiere integración con algún servicio externo (cloud) que provisione nuevos nodos.
En GKE lo podemos activar mediante la opción `Node auto-provisioning`, definiendo límites, zonas donde desplegar node-pools, etc.

Cuando Kubernetes necesite más recursos de los que dispone pedirá a la cloud que añada nodos. Cuando los nodos no se necesiten se destruirán.

Para esta prueba podemos desplegar el ejemplo `nginx-affinity` utilizado en otra de las demostraciones (tenía requests de 200m) y escalarlo a 6 u 8 réplicas.

```bash
k scale deployment nginx-affinity --replicas=12
```

Si echamos un vistazo a los pods que no se puedan colocar veremos que el componente `cluster-autoscaler` lanza un mensaje de solicitud de escalado:

```bash
Events:
  Type     Reason            Age                From                Message
  ----     ------            ----               ----                -------
  Warning  FailedScheduling  37s (x2 over 38s)  default-scheduler   0/3 nodes are available: 3 Insufficient cpu.
  Normal   TriggeredScaleUp  35s                cluster-autoscaler  pod triggered scale-up: [{https://www.googleapis.com/compute/v1/projects/chrome-plateau-338520/zones/us-west1-a/instanceGroups/gke-keepcoding-default-pool-887bbdcb-grp 3->6 (max: 6)}]
```
