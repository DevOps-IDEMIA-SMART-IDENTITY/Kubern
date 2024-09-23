## Ejercicio 1

- Problema: Crea manualmente la estructura básica de un chart de Helm llamado "myapp" con el archivo Chart.yaml.

<details>
    <summary>📌 Solución</summary>

Crea un directorio llamado myapp y dentro de él crea un archivo llamado Chart.yaml con el siguiente contenido:

```yaml
apiVersion: v2
name: myapp
description: Un chart de Helm simple para desplegar una aplicación en Kubernetes
version: 0.1.0
appVersion: "1.0.0"
```

- apiVersion: La versión de la API de Helm que se está utilizando.
- name: El nombre del chart.
- description: Una breve descripción del chart.
- version: La versión del chart.
- appVersion: La versión de la aplicación que se está desplegando.

</details>

## Ejercicio 2

- Problema: Crea una plantilla de Deployment en el directorio `templates` utilizando los valores definidos en el archivo `values.yaml`. La imagen deberá ser siempre `nginx` y solo será configurable el número de replicas.

> [!NOTE]
> El fichero `values.yaml` ya está creado y contiene la siguiente configuración:
> ```yaml
> replicas: 3
> ```

<details>
    <summary>📌 Solución</summary>

Crea un archivo llamado `deployment.yaml` en el directorio `templates` con el siguiente contenido:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-deployment
spec:
    replicas: {{ .Values.replicas }}
    selector:
        matchLabels:
            app: {{ .Chart.Name }}
    template:
      metadata:
        labels:
          app: {{ .Chart.Name }}
        spec:
          containers:
            - name: {{ .Chart.Name }}
              image: "nginx"
              ports:
                - containerPort: 80
```

Prueba a renderizar el template con Helm:

```bash
helm template myapp .
```

</details>

## Ejercicio 3

- Problema: Añade un Service al chart que exponga el Deployment creado en el ejercicio anterior en el puerto 80.

<details>
    <summary>📌 Solución</summary>

Añade el siguiente contenido al archivo `templates/service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ .Chart.Name }}
spec:
  ports:
    - port: 80
      targetPort: 80
  selector:
    app: {{ .Chart.Name }}
```

Prueba a renderizar el template con Helm:

```bash
helm template myapp .
```

</details>

## Ejercicio 4

- Problema: Crea un archivo `templates/_helpers.tpl` que defina un bloque llamado `myapp.fullname` que concatene el nombre del chart con el nombre de la release y utilízalo en los archivos `deployment.yaml` y `service.yaml`. Define también un selector de etiquetas para utilizarlo en el Deployment y en el Service.

<details>
    <summary>📌 Solución</summary>

Crea un archivo llamado `_helpers.tpl` en el directorio `templates` con el siguiente contenido:

```yaml
{{- define "myapp.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name }}
{{- end -}}

{{- define "myapp.selectorLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
```

Modifica los archivos `deployment.yaml` y `service.yaml` para utilizar el bloque definido:

```yaml
metadata:
  name: {{ include "myapp.fullname" . }}
```

```yaml
# Deployment
  template:
    metadata:
      labels:
        {{- include "myapp.selectorLabels" . | nindent 8 }}
```

```yaml
# Service
  selector:
    {{- include "myapp.selectorLabels" . | nindent 4 }}
```

Prueba a renderizar el template con Helm:

```bash
helm template myapp .
```

</details>

## Ejercicio 5

- Problema: Añade un ConfigMap que contenga variables con un prefijo `MYAPP_` y que se utilice en el Deployment para definir variables de entorno. Estas variables podrán ser configuradas en el archivo `values.yaml`.

<details>
    <summary>📌 Solución</summary>

Añade el siguiente contenido al archivo `templates/configmap.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "myapp.fullname" . }}
data:
  {{- range $key, $value := .Values.config }}
  MYAPP_{{ $key }}: {{ $value | quote }}
  {{- end }}
```

Modifica el archivo `deployment.yaml` para añadir las variables de entorno del ConfigMap:

```yaml
          envFrom:
            - configMapRef:
                name: {{ include "myapp.fullname" . }}
```

Añade el siguiente contenido al archivo `values.yaml`:

```yaml
config:
  KEY1: value1
  KEY2: value2
```

Prueba a renderizar el template con Helm:

```bash
helm template myapp .
```

</details>

## Ejercicio 6

- Problema: Añade un Ingress al chart que dirija el tráfico al Service creado en el ejercicio 3. El host del Ingress deberá ser configurable en el archivo `values.yaml`.

<details>
    <summary>📌 Solución</summary>

Añade el siguiente contenido al archivo `templates/ingress.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "myapp.fullname" . }}
spec:
  rules:
    - host: {{ .Values.ingress.host }}
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: {{ include "myapp.fullname" . }}
                port:
                  number: 80
```

</details>

## Ejercicio 7

- Problema: Instala el chart varias veces con diferentes valores de configuración y comprueba que se despliegan correctamente.

<details>
    <summary>📌 Solución</summary>

Crea un archivo `values-prod.yaml` con el siguiente contenido:
  
```yaml
replicas: 5
config:
  ENVIRONMENT: PROD
ingress:
  host: myapp-prod-127-0-0-1.nip.io
```

Instala el chart con el siguiente comando:

```bash
helm install myapp . -f values-prod.yaml
```

</details>