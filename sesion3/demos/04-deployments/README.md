<a name="pod"></a>
# Creación y mantenimiento de `Deployments` en Kubernetes

Índice de contenidos:

- [Creación e información básica](#creation)
- [Actualizando deployments](#updates)
- [Escalando deployments](#scale)
- [Detener rolling updates](#pause)


<a name="creation"></a>
### Creación e información básica de Deployments

Comenzaremos definiendo el siguiente deployment:

```yaml
apiVersion: apps/v1 # Version de la API (va cambiando)
kind: Deployment  # TIPO: Deployment
metadata: # Metadatos del Deployment
  name: nginx-deployment
spec: # Specificacion del DEPLOYMENT
  selector:
    matchLabels:
      app: nginx
  replicas: 2 # indica al controlador que ejecute 2 pods
  template:
    metadata: # Metadatos del POD
      labels:
        app: nginx
    spec: # Especificación del POD
      containers: # Declaración de los contenedores del POD
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
```

__CONSIDERACIONES IMPORTANTES__:

* Selector: Ha de apuntar a los labels de los pods, y es obligatorio definirlos y que cuadren. Asegúrate de que no son muy genéricos por si acaso!

* El bloque `spec.template` comienza la definición de un POD, por lo que `spec.template.spec` corresponde a la especificación de un pod (que ya conocemos).

Creamos el deployment:
```shell
kubectl apply -f 01-deployment.yaml
```

Chequamos el estado del deployment con `get` y `describe`. Observa y comprende los campos:

```shell
$ kubectl get deployment nginx-deployment -o=wide
NAME               READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES        SELECTOR
nginx-deployment   0/2     2            0           6s    nginx        nginx:1.7.9   app=nginx

$ kubectl describe deployment nginx-deployment
...
...
```

Para ver el estado del Deployment a nivel de cambios de configuración (rolling changes), ejecutamos el comando `rollout` de kubectl.

```shell
$ kubectl rollout status deployment nginx-deployment
deployment "nginx-deployment" successfully rolled out
```


Podemos mostrar también:

- ReplicaSet asociado al deployment:
```shell
$ kubectl get rs
NAME                          DESIRED   CURRENT   READY   AGE
nginx-deployment-5d59d67564   2         2         2       3m38s
```

- Pods con sus labels:

```shell
kubectl get pods --show-labels
NAME                                READY   STATUS    RESTARTS      AGE     LABELS
nginx-deployment-5d59d67564-jvgbx   1/1     Running   0             4m5s    app=nginx,pod-template-hash=5d59d67564
nginx-deployment-5d59d67564-sfjvw   1/1     Running   0             4m5s    app=nginx,pod-template-hash=5d59d67564
```

<a name="updates"></a>
### Actualizando deployments

- Supongamos que queremos actualizar la imagen a `nginx:1.25`, para ello podemos:
  - Cambiar el yaml y lanzar de nuevo `kubectl apply -f 01-deployment.yaml`
  - Editar el deployment con `kubectl edit deployment nginx-deployment`
  - Utilizar `kubectl set`:

  ```shell
  kubectl set image deployment/nginx-deployment nginx=nginx:1.25
  ```

Tras aplicar la actualización comprobamos el estado de cómo se van aplicando los cambios:

```shell
$ kubectl rollout status deployment/nginx-deployment
Waiting for deployment "nginx-deployment" rollout to finish: 1 out of 2 new replicas have been updated...
Waiting for deployment "nginx-deployment" rollout to finish: 1 out of 2 new replicas have been updated...
Waiting for deployment "nginx-deployment" rollout to finish: 1 out of 2 new replicas have been updated...
Waiting for deployment "nginx-deployment" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "nginx-deployment" rollout to finish: 1 old replicas are pending termination...
deployment "nginx-deployment" successfully rolled out
```

Como vemos se han destruido los pods antiguos y han sido sustituidos por nuevos.

También se puede verificar el estado de los cambios de forma más sencilla con:
  - `kubectl get deployment`
  - `kubectl get pod`

- Revertir cambios:

Supongamos que cometemos un error

Comprobación historial despliegues del deployment:
`kubectl rollout history deployment/nginx-deployment`

```shell
kubectl rollout history deployment/nginx-deployment --revision=2

kubectl rollout undo deployment/nginx-deployment

kubectl rollout undo deployment/nginx-deployment --to-revision=3
```

<a name="scale"></a>
### Escalando deployments

El escalado (y des-escalado) consiste en modificar el número de réplicas.

- Escalar un deployment:

  - Básico:
    ```shell
    kubectl scale deployment/nginx-deployment --replicas=10
    ```

  - Si autoescalado está habilitado en el cluster:
    ```shell
    kubectl autoscale deployment/nginx-deployment --min=10 --max=15 --cpu-percent=80
    ```

<a name="pause"></a>
### Pausando / deteniendo rolling updates

- Pausado de rollouts: Consiste en decirle al sistema que `no aplique cambios de configuración` temporalmente. Esto permite cambiar varias cosas a la vez, por ejemplo:

1) Pausamos deployment: `kubectl rollout pause deployment/nginx-deployment`
2) Realizamos múltiples cambios. Veremos después de cada cambio nada se aplica realmente:

```shell
kubectl set image deployment/nginx-deployment nginx=nginx:1.25
kubectl set resources deployment/nginx-deployment -c=nginx --limits=cpu=200m,memory=512Mi
```

Veremos como `rollout history` no muestra el cambio, y `rollout status` muestra un mensaje como:
```shell
Waiting for deployment "nginx-deployment" rollout to finish: 0 out of 10 new replicas have been updated...
```

3) Continuamos (resume) el rollout del deployment: `kubectl rollout resume deployment/nginx-deployment`

Comprobamos que los cambios se realizan:
```shell
kubectl get deployment
kubectl get pod -w
kubectl rollout status deployment nginx-deployment
```

__Troubleshooting__

Si el proceso se atasca, mira siempre:
- Estado de los pods y del deployment
- Describe de los componentes que no estén en el estado adecuado.
- Logs de los pods en caso de ser los pods los que por alguna razón fallan.
