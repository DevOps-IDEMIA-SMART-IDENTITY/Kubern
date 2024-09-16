## Ejercicios

### Ejercicio 1: Crear un Pod con límites de CPU y memoria
- Problema: Crea un Pod llamado mi-pod que utilice la imagen nginx y establece límites de CPU a 500m y de memoria a 256Mi.

<details>
    <summary>📌 Solución</summary>
    
Crea un archivo YAML llamado mi-pod.yaml con el siguiente contenido:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: mi-pod
spec:
  containers:
  - name: nginx
    image: nginx
    resources:
      limits:
        cpu: "500m"
        memory: "256Mi"
```

Aplica el archivo usando kubectl:

```bash
kubectl apply -f mi-pod.yaml
```

Verifica que el Pod esté corriendo con los límites establecidos:

```bash
kubectl describe pod mi-pod
```
</details>

### Ejercicio 2: Establecer requests y limits para un Pod

- Problema: Crea un Pod llamado mi-pod-requests con la imagen nginx, estableciendo requests de CPU a 250m y memoria a 128Mi, y límites de CPU a 500m y memoria a 256Mi.

<details>
    <summary>📌 Solución</summary>
Solución:

Crea el archivo mi-pod-requests.yaml:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: mi-pod-requests
spec:
  containers:
  - name: nginx
    image: nginx
    resources:
      requests:
        cpu: "250m"
        memory: "128Mi"
      limits:
        cpu: "500m"
        memory: "256Mi"
````

Aplica el archivo:

```bash
kubectl apply -f mi-pod-requests.yaml
````

Verifica los recursos:

```bash
kubectl describe pod mi-pod-requests
```

</details>

### Ejercicio 3: Limitar recursos en un Namespace usando ResourceQuota
- Problema: Aplica una cuota de recursos en el Namespace desarrollo que limite el uso total de CPU a 2 y de memoria a 1Gi.

<details>
    <summary>📌 Solución</summary>

Crea un archivo resource-quota.yaml:

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: cuota-recursos
  namespace: desarrollo
spec:
  hard:
    requests.cpu: "2"
    requests.memory: "1Gi"
    limits.cpu: "2"
    limits.memory: "1Gi"
```

Aplica la cuota al Namespace:

```bash
kubectl apply -f resource-quota.yaml
```

Verifica la ResourceQuota:

```bash
kubectl get resourcequota -n desarrollo
```

</details>

### Ejercicio 4: Verifica el uso de recursos en un nodo
Problema: Verifica el uso total de CPU y memoria en el nodo minikube.

<details>
    <summary>📌 Solución</summary>

Instala y utiliza kubectl top para ver el uso de recursos (si no está instalado, habilita el Metrics Server en Minikube):

```bash
minikube addons enable metrics-server
```

Verifica el uso de recursos en el nodo:

```bash
kubectl top pods
kubectl top nodes
```

</details>

### Ejercicio 5: Implementar un Limiter de Recursos mediante LimitRange
- Problema: Configura un LimitRange en el Namespace produccion que establezca un límite máximo de CPU a 1 y de memoria a 512Mi para cualquier Pod que se cree en dicho Namespace.

<details>
    <summary>📌 Solución</summary>

Crea un archivo `limit-range.yaml`:

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: limite-recursos
  namespace: produccion
spec:
  limits:
  - max:
      cpu: "1"
      memory: "512Mi"
    type: Container
```

Aplica el LimitRange al Namespace:

```bash
kubectl apply -f limit-range.yaml
```

Verifica el LimitRange:

```bash
kubectl get limitrange -n produccion
```

Intenta crear un Pod sin especificar límites y observa que se apliquen los límites por defecto.

```bash
kubectl run nginx --image=nginx -n produccion
```

</details>


### Ejercicio 6: Identificar y solucionar un Pod que está siendo OOMKilled

Antes de comenzar, aplica el siguiente manifiesto para crear un Pod que será reiniciado varias veces debido a un OOMKill:

```bash
kubectl apply -f deployment-oom.yaml
``` 

- Problema: Un Pod llamado mi-pod ha sido reiniciado varias veces con el estado OOMKilled. Investiga la causa y ajusta los límites de memoria para prevenir futuros OOMKills.

<details>

<summary>📌 Solución</summary>

Describe el Pod para ver los eventos:

```bash
kubectl describe pod mi-pod-xxx
```

Busca eventos que indiquen que el Pod fue OOMKilled debido a que excedió el límite de memoria.

Revisa la configuración actual de recursos:

```bash
kubectl get pod mi-pod -o yaml
```

Edita el Pod o el Deployment asociado para aumentar el límite de memoria. Por ejemplo, si es un Deployment:

```bash
kubectl edit deployment mi-deployment
```

Agrega o ajusta la sección de recursos:

```yaml
containers:
- name: mi-contenedor
  image: mi-imagen
  resources:
    requests:
      memory: "100Mi"
    limits:
      memory: "100Mi"
```

Aplica los cambios y verifica que el Pod se reinicie correctamente sin ser OOMKilled.

```bash
kubectl rollout restart deployment mi-deployment
kubectl get pods
```

Monitorea el Pod para asegurarte de que ya no se reinicia por OOMKilled:

```bash
kubectl describe pod mi-pod-xxxx
```

### Ejercicio 7: Desplegar MariaDB con Persistencia utilizando un PersistentVolumeClaim (PVC)
- Problema: Despliega una instancia de MariaDB en Minikube utilizando un PersistentVolumeClaim para el almacenamiento de datos. Luego, verifica que el PVC esté correctamente asociado y funcionando.

<details>

<summary>📌 Solución</summary>

Crea un archivo `mariadb-statefulset.yaml` para definir el despliegue de MariaDB con el PVC:

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mariadb
  labels:
    app: mariadb
spec:
  # serviceName: "mariadb-service"
  replicas: 1
  selector:
    matchLabels:
      app: mariadb
  template:
    metadata:
      labels:
        app: mariadb
    spec:
      containers:
      - name: mariadb
        image: mariadb:10.5
        env:
        - name: MARIADB_ROOT_PASSWORD
          value: "tu_contraseña_segura" # Esto es un secreto y debería ser almacenado en un Secret. No lo hagas así ni en la práctica ni en la vida real.
        ports:
        - containerPort: 3306
          name: mariadb
        volumeMounts:
        - name: mariadb-storage
          mountPath: /var/lib/mariadb
        resources:
          requests:
            memory: "256Mi"
            cpu: "150m"
          limits:
            memory: "1Gi"
            cpu: "500m"
  volumeClaimTemplates:
  - metadata:
      name: mariadb-storage
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: "standard"
      resources:
        requests:
          storage: 1Gi
```

Verifica que el StatefulSet esté corriendo:

```bash
kubectl get statefulsets
```

Verifica que el Pod de MariaDB esté en ejecución:
    
```bash
kubectl get pods -l app=mariadb
```

Verifica que los Persistent Volumes se hayan creado automáticamente:

```bash
kubectl get pv
```

Verifica que el Pod de MySQL esté utilizando el PVC correctamente:

```bash
kubectl describe pod mariadb-0
```

Accede a la base de datos MariaDB con la contraseña que estableciste (tu_contraseña_segura):

```bash
kubectl exec -it mariadb-0 -- mysql -u root -p
```

Y ejecuta:

```sql
CREATE DATABASE prueba_db;
USE prueba_db;
CREATE TABLE usuarios (id INT PRIMARY KEY, nombre VARCHAR(50));
INSERT INTO usuarios VALUES (1, 'Juan'), (2, 'María');
EXIT;
```

Prueba la persistencia de los datos reiniciando el Pod y verificando que los datos persistan:

```bash
kubectl delete pod mariadb-0
kubectl get pods -l app=mariadb
kubectl exec -it mariadb-0 -- mysql -u root -p
```

```sql
USE prueba_db;
SELECT * FROM usuarios;
EXIT;
```

</details>

