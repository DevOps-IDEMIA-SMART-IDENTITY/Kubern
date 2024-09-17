## Ejercicios - Scheduling

> [!WARNING]
> Si queremos ver bien el resultado de los ejercicios de scheduling, es recomendable tener un cluster con más de un nodo. En caso de estar utilizando Minikube, podemos aumentar el número de nodos con el siguiente comando:
> ```bash
> minikube start --nodes 3
> ```

### Ejercicio 1: Node Affinity para programar Pods en nodos específicos

- Problema: Configura un nodo en Minikube con una etiqueta personalizada y crea un Deployment cuyos Pods solo se programen en nodos con esa etiqueta utilizando Node Affinity. Utiliza archivos YAML para definir los recursos.

<details>
    <summary>📌 Solución</summary>

Añadimos una etiqueta al nodo de Minikube:

```bash
kubectl label nodes minikube disktype=ssd
```

Crea un archivo `deployment.yaml` con el siguiente contenido:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-node-affinity
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx-node-affinity
  template:
    metadata:
      labels:
        app: nginx-node-affinity
    spec:
      containers:
      - name: nginx
        image: nginx
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: disktype
                operator: In
                values:
                - ssd
```

Aplica el deployment:

```bash
kubectl apply -f deployment.yaml
```

Comprueba que los Pods se han programado en el nodo con la etiqueta `disktype=ssd`:

```bash
kubectl get pods -o wide
```

</details>

### Ejercicio 2: Node Anti-Affinity para evitar nodos con etiquetas específicas

- Problema: Crea un Deployment cuyos Pods eviten ser programados en nodos etiquetados con gpu=true utilizando Node Anti-Affinity.

<details>
    <summary>📌 Solución</summary>

Etiqueta un nodo de Minikube con `gpu=true`:

```bash
kubectl label nodes minikube-m02 gpu=true
```

Crea un archivo `deployment.yaml` con el siguiente contenido:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-node-anti-affinity
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx-node-anti-affinity
  template:
    metadata:
      labels:
        app: nginx-node-anti-affinity
    spec:
      containers:
      - name: nginx
        image: nginx
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: gpu
                operator: NotIn
                values:
                - "true"
```

Aplica el deployment:

```bash
kubectl apply -f deployment.yaml
```

Comprueba que los Pods no se han programado en el nodo con la etiqueta `gpu=true`:

```bash
kubectl get pods -o wide
```

</details>

### Ejercicio 3: Pod Affinity para programar Pods en el mismo nodo que otros Pods

- Problema: Despliega dos aplicaciones diferentes. Configura la segunda aplicación para que sus Pods se programen en el mismo nodo donde se estén ejecutando los Pods de la primera aplicación utilizando Pod Affinity.

<details>
    <summary>📌 Solución</summary>

Crea un archivo `deployment1.yaml` con el siguiente contenido:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app1
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app1
  template:
    metadata:
      labels:
        app: app1
    spec:
      containers:
      - name: app1
        image: nginx
```

Aplica el primer deployment:

```bash
kubectl apply -f deployment1.yaml
```

Crea un archivo `deployment2.yaml` con el siguiente contenido:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app2
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app2
  template:
    metadata:
      labels:
        app: app2
    spec:
      containers:
      - name: app2
        image: httpd
      affinity:
        podAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchLabels:
                app: app1
            topologyKey: "kubernetes.io/hostname"
```

Aplica el segundo deployment:

```bash
kubectl apply -f deployment2.yaml
```

Comprueba que los Pods de la segunda aplicación se han programado en el mismo nodo que los Pods de la primera aplicación:

```bash
kubectl get pods -o wide
```

</details>

### Ejercicio 4: Pod Anti-Affinity para distribuir Pods en diferentes nodos

- Problema: Crea un Deployment que distribuya sus Pods en diferentes nodos para alta disponibilidad, utilizando Pod Anti-Affinity para evitar que los Pods se programen en el mismo nodo.

<details>
    <summary>📌 Solución</summary>

Crea un archivo `deployment.yaml` con el siguiente contenido:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-anti-affinity
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx-anti-affinity
  template:
    metadata:
      labels:
        app: nginx-anti-affinity
    spec:
      containers:
      - name: nginx
        image: nginx
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchLabels:
                app: nginx-anti-affinity
            topologyKey: "kubernetes.io/hostname"
```

Aplica el deployment:

```bash
kubectl apply -f deployment.yaml
```

Comprueba que los Pods se han programado en diferentes nodos:

```bash
kubectl get pods -o wide
```

</details>

### Ejercicio 5: Tolerations para programar Pods en nodos con taints

- Problema: Aplica un taint al nodo de Minikube que impida que cualquier Pod se programe en él a menos que tenga la toleration correspondiente. Verifica que un Deployment sin toleration no se programa y que otro con toleration sí lo hace.

<details>
    <summary>📌 Solución</summary>

Añade un taint al nodo de Minikube:
    
```bash
kubectl taint nodes minikube-m02 key=value:NoSchedule
```

Crea un archivo `deployment1.yaml` con el siguiente contenido:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: no-toleration
spec:
  replicas: 1
  selector:
    matchLabels:
      app: no-toleration
  template:
    metadata:
      labels:
        app: no-toleration
    spec:
      containers:
      - name: nginx
        image: nginx
```

Aplica el primer deployment:

```bash
kubectl apply -f deployment1.yaml
```

Crea un archivo `deployment2.yaml` con el siguiente contenido:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: with-toleration
spec:
  replicas: 1
  selector:
    matchLabels:
      app: with-toleration
  template:
    metadata:
      labels:
        app: with-toleration
    spec:
      tolerations:
      - key: "key"
        operator: "Equal"
        value: "value"
        effect: "NoSchedule"
      containers:
      - name: nginx
        image: nginx
```

Aplica el segundo deployment:

```bash
kubectl apply -f deployment2.yaml
```

Comprueba que el primer deployment no se ha programado en el nodo con el taint:

```bash
kubectl get pods -o wide
```

</details>

### Ejercicio 6: Usar Preferencias en Node Affinity

- Problema: Crea un Deployment que prefiera programar sus Pods en nodos con la etiqueta disktype=ssd, pero que pueda ejecutarse en otros nodos si no hay recursos disponibles, utilizando `preferredDuringSchedulingIgnoredDuringExecution`.

<details>
    <summary>📌 Solución</summary>

Crea un archivo `deployment.yaml` con el siguiente contenido:
    
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: preferred-node-affinity
spec:
  replicas: 3
  selector:
    matchLabels:
      app: preferred-node-affinity
  template:
    metadata:
      labels:
        app: preferred-node-affinity
    spec:
      containers:
      - name: nginx
        image: nginx
      affinity:
        nodeAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 1
            preference:
              matchExpressions:
              - key: disktype
                operator: In
                values:
                - ssd
```

Aplica el deployment:

```bash
kubectl apply -f deployment.yaml
```

</details>

### Ejercicio 7: Pod Anti-Affinity para evitar programar Pods juntos

- Problema: Crea un Deployment que evite programar sus Pods en el mismo nodo que otros Pods de la misma aplicación, utilizando Pod Anti-Affinity.

<details>
    <summary>📌 Solución</summary>

Crea un archivo `deployment.yaml` con el siguiente contenido:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: preferred-pod-anti-affinity
spec:
  replicas: 3
  selector:
    matchLabels:
      app: preferred-pod-anti-affinity
  template:
    metadata:
      labels:
        app: preferred-pod-anti-affinity
    spec:
      containers:
      - name: nginx
        image: nginx
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - weight: 1
            podAffinityTerm:
              labelSelector:
                matchLabels:
                  app: preferred-pod-anti-affinity
              topologyKey: "kubernetes.io/hostname"
```

Aplica el deployment:

```bash
kubectl apply -f deployment.yaml
```

</details>

### Ejercicio 8: Tolerar un taint con efecto NoExecute

- Problema: Aplica un taint maintenance=true:NoExecute al nodo. Crea un Pod que tolere este taint por un tiempo específico (por ejemplo, 60 segundos) antes de ser desalojado.

<details>
    <summary>📌 Solución</summary>

Añade un taint al nodo de Minikube con efecto `NoExecute`:

```bash
kubectl taint nodes minikube-m02 maintenance=true:NoExecute
```

Crea un archivo `pod.yaml` con el siguiente contenido:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: temporary-toleration-pod
spec:
  tolerations:
  - key: "maintenance"
    operator: "Equal"
    value: "true"
    effect: "NoExecute"
    tolerationSeconds: 60
  containers:
  - name: nginx
    image: nginx
```

Aplica el Pod:

```bash
kubectl apply -f pod.yaml
```

Comprueba que el Pod se ha programado y que será desalojado después de 60 segundos:

```bash
kubectl get pods -w
```

</details>


## Ejercicios - Autoescalado

### Ejercicio 1: Configurar un Horizontal Pod Autoscaler (HPA) para una aplicación NGINX

- Problema: Despliega una aplicación NGINX en Kubernetes utilizando Minikube. Crea un Deployment con 1 réplica inicial y configura un Horizontal Pod Autoscaler (HPA) que escale automáticamente las réplicas entre 1 y 5 basándose en el uso promedio de CPU superando el 50%. Utiliza archivos YAML para definir los recursos necesarios.

<details>
    <summary>📌 Solución</summary>

Crea un archivo `nginx-deployment.yaml` con el siguiente contenido:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        resources:
          requests:
            cpu: 100m
```

Aplica el deployment:

```bash
kubectl apply -f nginx-deployment.yaml
```

Crea un archivo llamado `nginx-service.yaml` con el siguiente contenido:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
```

Aplica el servicio:

```bash
kubectl apply -f nginx-service.yaml
```

Crea un archivo `nginx-hpa.yaml` con el siguiente contenido:

```yaml
apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
metadata:
  name: nginx-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: nginx-deployment
  minReplicas: 1
  maxReplicas: 5
  targetCPUUtilizationPercentage: 50
```

Aplica el HPA:

```bash
kubectl apply -f nginx-hpa.yaml
```

Generamos carga en el cluster para que el HPA pueda escalar los pods:

```bash
kubectl run -i --tty load-generator --image=busybox /bin/sh
```

Dentro del contenedor, ejecuta el siguiente comando para generar carga en el cluster:

```bash
while true; do wget -q -O- http://nginx-service; done
```

Comprueba el estado del HPA:

```bash
kubectl get hpa -w
```

</details>

### Ejercicio 2: Autoescalado basado en memoria

- Problema: Despliega una aplicación que consume memoria de forma variable. Configura un HPA que escale las réplicas basándose en el uso promedio de memoria, escalando entre 2 y 6 réplicas si el uso de memoria supera los 100Mi por Pod. Utiliza archivos YAML para la configuración.

<details>
    <summary>📌 Solución</summary>

Crea un archivo `deployment.yaml` con el siguiente contenido:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: memory-hog-deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: memory-hog
  template:
    metadata:
      labels:
        app: memory-hog
    spec:
      containers:
      - name: memory-hog
        image: polinux/stress
        command: ["stress"]
        args: ["--vm", "1", "--vm-bytes", "150M", "--vm-hang", "1"]
        resources:
          requests:
            memory: "150Mi"
```

Aplica el deployment:

```bash
kubectl apply -f deployment.yaml
```

Crea un archivo llamado `hpa.yaml` con el siguiente contenido:

```yaml
apiVersion: autoscaling/v2beta2
kind: HorizontalPodAutoscaler
metadata:
  name: memory-hog-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: memory-hog-deployment
  minReplicas: 2
  maxReplicas: 6
  metrics:
  - type: Resource
    resource:
      name: memory
      target:
        type: AverageValue
        averageValue: 200Mi
```

Aplica el HPA:

```bash
kubectl apply -f hpa.yaml
```

Comprueba el estado del HPA:

```bash
kubectl get hpa -w
```

</details>

