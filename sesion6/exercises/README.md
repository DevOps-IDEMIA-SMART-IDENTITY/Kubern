## Ejercicios - Ingress

> [!WARNING]
> Para los siguientes ejercicios necesitaremos crear un tunnel con minikube y tener instalado el addon `ingress`. Para ello ejecutaremos los siguientes comandos:
> ```bash
> minikube addons enable ingress
> minikube tunnel
> ```

> [!NOTE]
> Usaremos nip.io para usar dominios que apunten a nuestra IP local (127.0.0.1).
> Por ejemplo, si queremos exponer la aplicación `mi-app`, podríamos utilizar el dominio `mi-app-127-0-0-1.nip.io`.

### Ejercicio 1: Despliega una aplicación con NGINX y expónla mediante un Ingress

- Problema: Crea un Deployment con una aplicación NGINX y un servicio ClusterIP. Crea un Ingress para exponer la aplicación.

<details>
    <summary>📌 Solución</summary>
    
Crea un archivo `mi-app.yaml` con el siguiente contenido:
    
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mi-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mi-app
  template:
    metadata:
      labels:
        app: mi-app
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: mi-app
spec:
  selector:
    app: mi-app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: mi-app
spec:
  rules:
  - host: mi-app-127-0-0-1.nip.io
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: mi-app
            port:
              number: 80
```

Aplica el archivo usando kubectl:

```bash
kubectl create namespace sesion6
kubens sesion6
kubectl apply -f mi-app.yaml
```

</details>

### Ejercicio 2: Configurar Ingress con Múltiples Servicios Basados en Path

- Problema: Crea un Ingress que exponga dos servicios diferentes en función de la ruta. Expón el servicio `mi-app` en la ruta `/app` y el servicio `mi-app2` en la ruta `/app2`.

> [!TIP]
> Puedes utilizar el archivo `mi-app.yaml` del ejercicio anterior y añadir un nuevo servicio y un nuevo deployment. Este nuevo deployment puede ser un `http-echo` que devuelva un texto diferente al de `mi-app`. Puedes utilizar el siguiente deployment para `mi-app2`:
> ```yaml
> apiVersion: apps/v1
> kind: Deployment
> metadata:
>   name: mi-app2
> spec:
>   replicas: 2
>   selector:
>     matchLabels:
>       app: mi-app2
>   template:
>     metadata:
>       labels:
>         app: mi-app2
>     spec:
>       containers:
>       - name: mi-app2
>         image: hashicorp/http-echo:latest
>         args:
>           - "-text=Soy mi-app2"
>         ports:
>         - containerPort: 5678
> ```

> [!TIP]
> Si obtienes un 404 al acceder a la ruta `/app`, añade el siguiente annotation al Ingress:
> ```yaml
> metadata:
>   annotations:
>     nginx.ingress.kubernetes.io/rewrite-target: /
> ```

<details>
    <summary>📌 Solución</summary>

Crea un archivo `mi-app.yaml` con el siguiente contenido:
        
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mi-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mi-app
  template:
    metadata:
      labels:
        app: mi-app
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: mi-app
spec:
  selector:
    app: mi-app
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mi-app2
spec:
  replicas: 2
  selector:
    matchLabels:
      app: mi-app2
  template:
    metadata:
      labels:
        app: mi-app2
    spec:
      containers:
      - name: mi-app2
        image: hashicorp/http-echo:latest
        args:
          - "-text=Soy mi-app2"
        ports:
        - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: mi-app2
spec:
  selector:
    app: mi-app2
  ports:
  - protocol: TCP
    port: 5678
    targetPort: 5678
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: mi-app
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: ejercicio2-127-0-0-1.nip.io
    http:
      paths:
      - path: /app
        pathType: Prefix
        backend:
          service:
            name: mi-app
            port:
              number: 80
      - path: /app2
        pathType: Prefix
        backend:
          service:
            name: mi-app2
            port:
              number: 5678
```

Aplica el archivo usando kubectl:

```bash
kubectl apply -f mi-app.yaml
```

</details>

### Ejercicio 3: Configurar Ingress con Múltiples Servicios Basados en Host

- Problema: Modifica el Ingress del ejercicio anterior para que los servicios se expongan en función del host. Utiliza los dominios `mi-app-127-0-0-1.nip.io` y `mi-app2-127-0-0-1.nip.io`.

<details>
    <summary>📌 Solución</summary>

Modifica el archivo `mi-app.yaml` para que el Ingress tenga la siguiente configuración:
  
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: mi-app
spec:
  rules:
  - host: mi-app-127-0-0-1.nip.io
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: mi-app
            port:
              number: 80
  - host: mi-app2-127-0-0-1.nip.io
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: mi-app2
            port:
              number: 5678
```

Aplica el archivo usando kubectl:

```bash
kubectl apply -f mi-app.yaml
```

</details>

### Ejercicio 4: Configurar TLS en Ingress

- Problema: Configura el Ingress del ejercicio anterior para que utilice TLS. Utiliza un certificado autofirmado.

<details>
    <summary>📌 Solución</summary>

Crea un certificado autofirmado:

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -subj "/CN=mi-app-127-0-0-1.nip.io/O=keepcoding"
```

Crea un secreto con el certificado:

```bash
kubectl create secret tls mi-app-tls --key tls.key --cert tls.crt
```

Modifica el archivo `mi-app.yaml` para que el Ingress incluya el certificado:

```yaml
...
spec:
  tls:
  - hosts:
    - mi-app-127-0-0-1.nip.io
    secretName: mi-app-tls
...
```

Aplica el archivo usando kubectl:

```bash
kubectl apply -f mi-app.yaml
```

Observa el certificado en el navegador al acceder a https://mi-app-127-0-0-1.nip.io y a https://mi-app2-127-0-0-1.nip.io. ¿Ves alguna diferencia?

</details>

## Ejercicios - Helm

### Ejercicio 1: Instalar un Chart de Helm

- Problema: Instala el chart de Helm oficial de Grafana en tu clúster de Minikube.

<details>
    <summary>📌 Solución</summary>

Añade el repositorio de Helm de NGINX:
  
```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

Instala el chart de Grafana
  
```bash
kubectl create namespace mi-grafana # Creamos un namespace para el chart
kubens mi-grafana # Cambiamos al namespace creado
helm install mi-grafana grafana/grafana
```

Comprueba que el chart se ha instalado correctamente:

```bash
kubectl get pods
```

Lista las releases de Helm:

```bash
helm list
```

</details>

### Ejercicio 2: Actualizar un Chart de Helm

- Problema: Actualiza el chart de Grafana a la versión 8.5.0.

<details>
    <summary>📌 Solución</summary>

Actualiza el chart de Grafana a la versión 8.5.0:

```bash
helm upgrade mi-grafana grafana/grafana --version 8.5.0
```

Comprueba que el chart se ha actualizado correctamente:

```bash
helm list
```

</details>



### Ejercicio 3: Desinstalar una release de Helm

- Problema: Desinstala la release de Grafana que has instalado en el ejercicio 1.

<details>
    <summary>📌 Solución</summary>

Desinstala la release de Grafana:

```bash
helm uninstall mi-grafana
```

Comprueba que la release se ha desinstalado correctamente:

```bash
helm list
kubectl get pods
```

</details>

### Ejercicio 4: Crear e instala un Chart de Helm básico

- Problema: Crea un chart de Helm básico que despliegue un Deployment con una aplicación NGINX. Instala el chart en tu clúster de Minikube.

<details>
    <summary>📌 Solución</summary>

1. Ejecuta `helm create mi-app` para crear un chart de Helm básico.

2. Comprueba los archivos generados en la carpeta `mi-app`.

3. Instala el chart en tu clúster de Minikube:

  ```bash
  helm install mi-app ./mi-app
  ```

4. Comprueba que el chart se ha instalado correctamente:

  ```bash
  helm list
  kubectl get pods
  ```
</details>

### Ejercicio 5: Actualizar un Chart de Helm básico

- Problema: Actualiza el chart de Helm básico que has creado en el ejercicio 4 para que despliegue dos réplicas del Deployment y habilita el ingress con el dominio `helm-127-0-0-1.nip.io`.

<details>
    <summary>📌 Solución</summary>

1. Modifica el archivo `values.yaml` para que tenga dos réplicas y contenga liveness y readiness probes:

```yaml
replicaCount: 2

ingress:
  enabled: true
  hosts:
    - host: helm-127-0-0-1.nip.io
      paths:
        - path: /
```

2. Actualiza el chart en tu clúster de Minikube:

```bash
helm upgrade mi-app ./mi-app
```

3. Comprueba que el chart se ha actualizado correctamente:

```bash
helm list
kubectl get pods
```

4. Comprueba que el Ingress se ha creado correctamente:

```bash
kubectl get ingress
```

5. Accede a la aplicación desde tu navegador con el dominio `helm-127-0-0-1.nip.io` (recuerda que necesitas ejecutar `minikube tunnel`).

</details>

### Ejercicio 6: Incluir un ConfigMap en el Chart

- Problema: Modifica el chart de Helm básico para que incluya un ConfigMap con un archivo `index.html` que contenga un mensaje de bienvenida. Monta el ConfigMap en el Deployment en el directorio `/usr/share/nginx/html`.

<details>
    <summary>📌 Solución</summary>

1. Crea un archivo `configmap.yaml` dentro de la carpeta `templates` con el siguiente contenido:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "mi-app.fullname" . }}
data:
  index.html: |
    <html>
      <head>
        <title>{{ .Values.webTitle }}</title>
      </head>
      <body>
        <h1>{{ .Values.webMessage }}</h1>
      </body>
    </html>
```

2. Modifica el archivo `deployment.yaml` para que monte el ConfigMap en el directorio `/usr/share/nginx/html`:

```yaml
          volumeMounts:
            - name: index-html-volume
              mountPath: /usr/share/nginx/html/
          {{- with .Values.volumeMounts }}
            {{- toYaml . | nindent 12 }}
          {{- end }}
      volumes:
        - name: index-html-volume
          configMap:
            name: {{ include "mi-app.fullname" . }}
      {{- with .Values.volumes }}
        {{- toYaml . | nindent 8 }}
      {{- end }}
```

Observa que ahora siempre se crea un volumen y se monta en el contenedor. Además, mantenemos la posibilidad de añadir más volumenes y mounts si es necesario.

3. Actualiza el fichero `values.yaml` para incluir el título y el mensaje de bienvenida:

```yaml
webTitle: "Bienvenido a mi app"
webMessage: "¡Hola, mundo!"
```

3. Actualiza el chart en tu clúster de Minikube:

```bash
helm upgrade mi-app ./mi-app
```

4. Comprueba que el chart se ha actualizado correctamente:

```bash
helm list
kubectl get pods
```

5. Comprueba que el ConfigMap se ha creado correctamente:

```bash
kubectl get configmap
```

6. Accede a la aplicación desde tu navegador con el dominio `helm-127-0-0-1.nip.io` (recuerda que necesitas ejecutar `minikube tunnel`).

</details>

### Ejercicio 7: Asegurar que el mensaje esté siempre en mayúsculas

- Problema: Modifica el chart de Helm para que el mensaje de bienvenida siempre esté en mayúsculas.

<details>
    <summary>📌 Solución</summary>

Añade la función `upper` al mensaje de bienvenida en el archivo `deployment.yaml`:

```yaml
{{ .Values.webMessage | upper }}
```

Actualiza la release de Helm:

```bash
helm upgrade mi-app ./mi-app
```

Comprueba que se ha actualizado accediendo a la aplicación desde tu navegador.

</details>

### Ejercicio 8: Añade una dependencia a un Chart de Helm

- Problema: Añade el chart de MariaDB de Bitnami como dependencia al chart de Helm.

<details>
    <summary>📌 Solución</summary>

1. Añade el repositorio de Bitnami:

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

2. Añade el chart de MariaDB como dependencia en el archivo `Chart.yaml`:

```yaml
dependencies:
  - name: mariadb
    version: 19.0.6
    repository: https://charts.bitnami.com/bitnami
```

3. Actualiza las dependencias:

```bash
helm dependency update ./mi-app
```

4. Actualiza la release de Helm:

```bash
helm upgrade mi-app ./mi-app
```

Comprueba que se ahora se despliega también una base de datos MariaDB.

</details>

