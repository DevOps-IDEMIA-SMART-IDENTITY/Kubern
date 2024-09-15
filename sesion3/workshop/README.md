# Sesión 3 - Taller

## Objetivos del Taller
- Desplegar una aplicación usando un Deployment con 3 réplicas.
- Configurar liveness y readiness probes en el Deployment.
- Crear un Service de tipo ClusterIP para exponer la aplicación internamente en el cluster.
- Pasar información sensible a los pods mediante un Secret.
- Proveer configuraciones adicionales usando un ConfigMap.

## Creación del Deployment

Un Deployment en Kubernetes gestiona la creación y escalado de un conjunto de Pods idénticos. Es útil para garantizar que un número específico de réplicas de una aplicación estén corriendo en todo momento.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-keepcoding
spec:
  replicas: 3
  selector:
    matchLabels:
      app: app-keepcoding
  template:
    metadata:
      labels:
        app: app-keepcoding
    spec:
      containers:
      - name: contenedor-keepcoding
        image: nginx:latest
        ports:
        - containerPort: 80
```

```bash
kubectl apply -f deployment.yaml
```

## Configuración de Liveness y Readiness Probes
- Liveness Probe: Verifica si el contenedor está funcionando correctamente. Si falla, Kubernetes reiniciará el contenedor.
- Readiness Probe: Indica si el contenedor está listo para recibir tráfico. Si falla, el servicio dejará de enviar tráfico al contenedor.

Modifica el Deployment para incluir las probes:
```yaml
...
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 15
          periodSeconds: 20
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 10
...
```

Ahora, aplica los cambios:
```bash
kubectl apply -f deployment.yaml
```

# Creación del Service (ClusterIP)
Un Service expone tu aplicación dentro del cluster y proporciona un nombre DNS estable para acceder a ella. El tipo ClusterIP expone el servicio en una IP interna del cluster.

Crea un archivo llamado `service.yaml` con el siguiente contenido:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: servicio-keepcoding
spec:
  selector:
    app: app-keepcoding
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  type: ClusterIP
```


```bash
kubectl apply -f service.yaml
```

## Creación y uso de un Secret
Un Secret permite almacenar y gestionar información sensible, como contraseñas o tokens, de forma segura.

Crea un archivo llamado secret.yaml:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: secret-keepcoding
type: Opaque
data:
  password: cGFzc3dvcmQ=  # 'password' codificado en base64
```

Nota: Para codificar tu propia contraseña en base64, puedes usar:

```bash
echo -n 'tu-contraseña' | base64
```

Aplicamos el Secret:
```bash
kubectl apply -f secret.yaml
```
## Uso del Secret en el Deployment
Actualiza deployment.yaml para incluir el Secret:

```yaml
...
        envFrom:
          - secretRef:
              name: secret-keepcoding
...
```

Aplicamos los cambios:

```bash
kubectl apply -f deployment.yaml
```

# Creación y uso de un ConfigMap
Un ConfigMap almacena datos de configuración no confidenciales en pares clave-valor.

Crea un archivo llamado `configmap.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: configmap-keepcoding
data:
  APP_ENV: "produccion"
  APP_DEBUG: "false"
```

Aplicamos el ConfigMap:

```bash
kubectl apply -f configmap.yaml
```

## Uso del ConfigMap en el Deployment
Actualiza `deployment.yaml` para referenciar el ConfigMap:

```yaml
...
        envFrom:
        - configMapRef:
            name: configmap-keepcoding
...
```

Aplicamos los cambios:

```bash
kubectl apply -f deployment.yaml
```
## Verificación y Pruebas
Verificar los Pods
Comprueba que los Pods estén corriendo:

```bash
kubectl get pods
kubectl describe pod <nombre-del-pod>
```

Utiliza port forwarding para acceder al servicio:

```bash
kubectl port-forward service/servicio-keepcoding 8080:80
```

Accede a la aplicación en http://localhost:8080.

Verifica las variables de entorno entrando al contenedor del Pod:

```bash
kubectl exec -it <nombre-del-pod> -- /bin/bash
```

Y una vez dentro, ejecuta:

```bash
echo $APP_ENV
echo $APP_DEBUG
echo $SECRET_PASSWORD
```

## Conclusión
- Deployments: Gestionan la creación y escalado de Pods.
- Probes: Aseguran la salud y disponibilidad de las aplicaciones.
- Services: Exponen aplicaciones y permiten el descubrimiento de servicios.
- Secrets y ConfigMaps: Gestionan información sensible y configuración.
