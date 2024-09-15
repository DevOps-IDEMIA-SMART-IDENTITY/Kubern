<a name="resources"></a>
# Recursos de CPU y Memoria

Índice de contenidos:

- [Namespace y chequeos previos](#start)
- [Comprobando limites de CPU](#cpu)
- [Comprobando limites de memoria](#memory)


<a name="start"></a>
## Pre-requisitos y setup inicial

Para esta demostración es necesario tener `metrics-server` o algún sistema de monitorización desplegado en Kubernetes.

En minikube puedes instalar `metrics-server` con `minikube addons enable metrics-server`.
En GKE ya viene instalado.

Para comprobarlo:

```shell
$ kubectl get apiservices | grep -i metric
v1beta1.metrics.k8s.io                 kube-system/metrics-server   True        129m
```

Para esta demostración crearemos un `Namespace` llamado `resources-demo`:

```shell
kubectl create namespace resources-demo
```


<a name="cpu"></a>
## Comprobando límites de CPU

Utilizaremos las siguientes definiciones:

- Pod `cpu-demo` capaz de estresar el sistema.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: cpu-demo
  namespace: resources-demo
spec:
  containers:
  - name: cpu-demo-ctr
    image: vish/stress
    resources:
      limits:
        cpu: "1"
      requests:
        cpu: "0.5"
    args:
    - -cpus
    - "2"
```

Comprueba el uso de CPU del pod creado con:
```shell
kubectl top pod cpu-demo -n resources-demo
```


- Pod `cpu-demo-high` con solicitud alta de CPU.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: cpu-demo-high
  namespace: resources-demo
spec:
  containers:
  - name: cpu-demo-ctr-2
    image: vish/stress
    resources:
      limits:
        cpu: "100"
      requests:
        cpu: "100"
    args:
    - -cpus
    - "2"
```

Qué pasa con el pod anterior? Descúbrelo y haz troubleshooting.


<a name="memory"></a>
## Comprobando límites de memoria

- Utilizaremos el siguiente pod, con un límie de 200M de memoria y que al levantar reservará 150M.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: memory-demo
  namespace: resources-demo
spec:
  containers:
  - name: memory-demo-ctr
    image: polinux/stress
    resources:
      limits:
        memory: "200Mi"
      requests:
        memory: "100Mi"
    command: ["stress"]
    args: ["--vm", "1", "--vm-bytes", "150M", "--vm-hang", "1"]
```

- Este otro pod tiene el mismo límite pero intentará reservar 250M:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: memory-demo-high
  namespace: resources-demo
spec:
  containers:
  - name: memory-demo-2-ctr
    image: polinux/stress
    resources:
      requests:
        memory: "50Mi"
      limits:
        memory: "100Mi"
    command: ["stress"]
    args: ["--vm", "1", "--vm-bytes", "250M", "--vm-hang", "1"]
```

Si observamos este pod con `kubectl get pod`
```shell
NAME               READY   STATUS      RESTARTS   AGE
memory-demo        1/1     Running     0          2m56s
memory-demo-high   0/1     OOMKilled   2          36s
```

Para ver eventos en tiempo real:
```shell
$ kubectl get pod -w

memory-demo-high   1/1     Running            2          22s
memory-demo-high   0/1     OOMKilled          2          23s
```

Para más detalles podemos hacer:

```shell
$ kubectl get pod memory-demo-high -o=yaml
...
...
    state:
      terminated:
        containerID: containerd://4d8d77579c6a684d89b746f1acb4d6191305e86855fc8d888255930f4fbbebdb
        exitCode: 1
        finishedAt: "2022-02-07T12:34:45Z"
        reason: OOMKilled
        startedAt: "2022-02-07T12:34:44Z"
```

También el describe del node que ejecuta el pod nos puede dar información al respecto (para saber el nodo que ejecuta un pod `kubectl get pod -o=wide`).

```shell
k describe node gke-keepcoding-default-pool-7b2ab140-b7vr

Events:
  Type     Reason      Age                  From            Message
  ----     ------      ----                 ----            -------
  Warning  OOMKilling  7m59s                kernel-monitor  Memory cgroup out of memory: Killed process 100490 (stress) total-vm:256776kB, anon-rss:100584kB, file-rss:268kB, shmem-rss:0kB, UID:0 pgtables:236kB oom_score_adj:975
  Warning  OOMKilling  7m57s                kernel-monitor  Memory cgroup out of memory: Killed process 100545 (stress) total-vm:256776kB, anon-rss:100584kB, file-rss:268kB, shmem-rss:0kB, UID:0 pgtables:244kB oom_score_adj:975
```
