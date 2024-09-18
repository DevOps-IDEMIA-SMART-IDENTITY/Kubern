<a name="pod"></a>
# Statefulsets y Storage

Para comprender completamente esta demostración, lo ideal es tener claros los siguientes conceptos:
- Pods
- Resolución DNS en el cluster
- Servicios HeadLess
- PersistentVolumes y PersistentVolumeClaims
- StatefulSets

La demostración da por supuesto que el cluster es capaz de crear `PersistentVolumes` dinámicamente.

Índice de contenidos:

- [Creación de Statefulset y consideraciones](#creation)
- [Comprobaciones básicas](#checks)
- [Exponiendo StatefulSet al exterior mediante LoadBalancer](#expose)
- [Escalando StatefulSets](#scale)
- [Aplicando cambios, rolling updates](#update)
- [Borrado del Statefulset y datos](#delete)

<a name="operations"></a>
## Creación de StatefulSet

Para la demostración y descripción de los `StatefulSets` vamos a utilizar un `nginx` (por su simplicidad), pero no es el tipo de aplicación que generalmente se asocia a cargas de trabajo de este tipo.

Comenzaremos con un statefulset NGINX con 2 replicas, incluyendo además un __PersistentVolumeClaim__ que gestionará la creación de discos individuales para nuestros pods.

El StatefulSet requiere de un servicio `HeadLess` asociado, por lo que lo incluimos en nuestra definición dentro del `yaml`:


```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-headless # tiene que hacer match con el statefulset 'serviceName'
  labels:
    app: nginx
spec:
  ports:
  - port: 80
    name: web
  clusterIP: None # para que sea headless
  selector:
    app: stateful-demo # apunta a pods
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  selector:
    matchLabels:
      app: stateful-demo # tiene que coincidir con .spec.template.metadata.labels
  serviceName: "nginx-headless" # Tiene que hacer match con el headless service name
  replicas: 2 # por defecto es 1
  template:
    metadata:
      labels:
        app: stateful-demo # tiene que coincidir con .spec.selector.matchLabels
    spec:
      terminationGracePeriodSeconds: 10
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
          name: web
        volumeMounts:
        - name: www
          mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
  - metadata:
      name: www
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 1Gi
```

Creamos el StatefulSet:
```shell
kubectl apply -f 01-statefulset.yaml
```

__NOTA__: El yaml va a fallar. Descubre por qué y arréglalo!!

__CONSIDERACIONES IMPORTANTES SOBRE EL MANIFIESTO__:

* Selector: Igual que en los Deployments, ha de apuntar a los pods.

* Al igual que en los deployments, en el bloque `spec.template` comienza la definición del pod.

* Hace falta un servicio headless (indicado en `serviceName`).

* `volumeClaimTemplates`: Define PVCs (`PersistentVolumeClaims`) que son solicitudes al sistema de storage para crear PVs (`PersistentVolumes`). El volumen final se montará donde indiquemos en el bloque `volumeMounts` del POD.

* `storageClassName` ha de ser una clase definida en el sistema. Si no se especifica se usará la clase por defecto.

* El mantenimiento y escalado de los `StatefulSet` se puede realizar de la misma manera que los `Deployment`

* __OJO__! Si quisiéramos abrir el `StatefulSet` al exterior tendríamos que crear otro Servicio, y no modificar el `HeadLess`.

__Troubleshooting__

- Además de todo lo dicho hasta ahora hay que asegurarse de que los PVCs y PVs asociados se creen correctamente, ya que si no los pods no podrán crearse.
- Como siempre haz un describe de los pods si están en estado `Pending` o `Init`
- Mira los pvcs y los pvs con `kubectl get pvc` y `kubectl describe pvc xxxxx`.
- Comprueba que la `storageClassName` usada exista en el sistema (`kubectl get storageclasses`)

<a name="checks"></a>
## Comprobaciones básicas

- Comenzamos echando un vistazo a los recursos creados:

  ```shell
  kubectl get pods -l app=stateful-demo
  kubectl get service nginx-headless
  kubectl get statefulset web
  kubectl get pvc
  kubectl get pv
  ```

Examina los nombres de los pods, tienen una identidad / nombre estática.

  - Comprobación de `hostnames` de cada pod:

  ```shell
  $ for i in 0 1; do kubectl exec "web-$i" -- sh -c 'hostname'; done
  web-0
  web-1
  ```

  - Lanzamos pod `busybox:1.28` para hacer comprobaciones DNS:

  ```shell
  $ kubectl run -i --tty --image busybox:1.28 dns-test --restart=Never --rm
  ```

  Posibles resoluciones:

  ```shell
  # Uno de los pods directamente
  nslookup web-0.nginx-headless

  # El servicio headless
  nslookup nginx-headless
  nslookup nginx-headless.default.svc.cluster.local
  ```

__Troubleshooting__: Problemas de resolucion??? Comprueba el manifiesto del `StatefulSet` y asegúrate de que `serviceName` apunta al nombre del servicio headless.

  - Eliminamos uno o todos los pods (comprobaremos como se reinician automáticamente)

  ```shell
  kubectl delete pod web-0
  kubectl delete pod -l app=stateful-demo
  ```

  Volvemos a comprobar los hostnames y vemos que siguen siendo los mismos.


  - Demostración de persistencia independiente:

  Con el siguiente comando crearemos un fichero `index.html` en cada uno de los nginx (`/usr/share/nginx/html/` es el punto de montaje del volumen persistente).

  ```shell
  for i in 0 1; do kubectl exec "web-$i" -- sh -c 'echo "$(hostname)" > /usr/share/nginx/html/index.html'; done
  ```

  A continuación podemos hacer un curl en cada uno de los pods para comprobar la página que ofrecen:
  ```shell
  $ for i in 0 1; do kubectl exec -i -t "web-$i" -- curl http://localhost ; done
  web-0
  web-1
  ```

<a name="expose"></a>
## Exponiendo el StatefulSet al exterior


  - Exposición de la aplicación con LoadBalancer externo:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-web-lb
spec:
  type: LoadBalancer
  selector:
    app: stateful-demo
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
```

Creamos el LB:

```shell
  kubectl apply -f 02-loadbalancer.yaml
```

Esperamos a que el load balancer externo se cree y accedemos con el navegador.

Si estamos usando minikube, podemos hacer un tunnel con el siguiente comando:

```shell
minikube tunnel
```

<a name="scale"></a>
## Escalando StatefulSets

Lo podemos hacer de la misma manera que los deployments, pero más lógico sería modificar el YAML origen y re-aplicarlo con `kubectl apply -f` (para que nuestro inventario refleje la realidad).

(Opción 1)
```shell
kubectl scale sts web --replicas=5
```


Otra forma de aplicar este tipo de cambios es con `kubectl patch`:

(Opción 2)
```shell
kubectl patch sts web -p '{"spec":{"replicas":3}}'
```

Lo ideal como hemos dicho sería modificar el yaml original y aplicarlo de nuevo:

(Opción 3)
```shell
vi 01-statefulset.yaml # para cambiar las replicas.
kubectl apply -f 01-statefulset.yaml
```

<a name="rolling"></a>
## Aplicando cambios, rolling updates

Las estrategias de aplicación de cambios se definen en el campo `updateStrategy`. El valor más común es `RollingUpdate`.

Podemos cambiar la imagen del contenedor a una nueva versión y aplicar los cambios. Los métodos son los mismos que al modificar deployments:

- Editar el yaml original y aplicar cambios (__recomendado__)
- Editar directamente el objeto de Kubernetes (`kubectl edit sts web`)
- Aplicar el cambio con `kubectl patch`.

Para observar el rolling update en acción en un terminal ejecutamos el siguiente comando:

```shell
kubectl get pod -l app=stateful-demo -w
```

Y en otra ventana provocamos un cambio (por ejemplo cambiamos la imagen a `nginx-slim:0.7`).

<a name="delete"></a>
## Borrado del StatefulSet y sus datos

Recursos a considerar durante el borrado:
- StatefulSet
- Servicio(s) asociados
- PervistentVolumeClaim y PersistentVolumes.

Para borrar el `StatefulSet` solamente:

```shell
kubectl delete sts web
```

Esto borrará la definición del statefulset y los pods pero dejará el PVC (`PersistentVolumeClaim`) intacto.

Si además queremos borrar los datos / discos persistentes de todos los nodos tendremos que borrar los PVCs a mano.

```shell
kubectl delete pvc www-web-1
...
...
```

Si por alguna razón queremos borrar el StatefulSet pero mantener los pods en ejecución podemos utilizar la opción `--cascade=orphan`:

```shell
kubectl delete sts web --cascade=orphan
```

## Limpieza completa

Una limpieza completa la podríamos hacer de la siguiente manera:

Borramos todo lo que había en el `yaml` original (sts y servicio), y además el `LoadBalancer` que habíamos creado.

```shell
kubectl delete -f 01-statefulset.yaml
kubectl delete -f 02-loadbalancer.yaml
```

__PRECAUCION__!: El próximo paso elimina los discos / volúmenes y todos los datos que hubiera.

Borramos PVCs:

```shell
kubectl delete pvc -l app=stateful-demo
```
