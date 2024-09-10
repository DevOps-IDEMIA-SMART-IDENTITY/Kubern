# Liveness & Readiness probes

El siguiente ejemplo simula la siguiente situación:
- Pod arranca y tarda 20 segundos en estar preparado.
- A los 40 segundos del arranque el liveness check fallará y el pod será reiniciado.


```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    test: liveness
  name: liveness-exec
spec:
  containers:
  - name: liveness
    image: busybox
    command: ['sh', '-c']
    args:
      - |
        touch /tmp/healthy; sleep 20
        touch /tmp/ready; sleep 20
        rm -rf /tmp/healthy
        sleep 300
    livenessProbe:
      exec:
        command:
        - cat
        - /tmp/healthy
      initialDelaySeconds: 5
      periodSeconds: 5
      failureThreshold: 1
      successThreshold: 1
    readinessProbe:
      exec:
        command:
        - cat
        - /tmp/ready
      initialDelaySeconds: 5
      periodSeconds: 5
      failureThreshold: 1
      successThreshold: 1
```

Para lanzar el ejemplo:
```
kubectl apply -f 01-pod.yaml
```

Tras lanzarlo abrimos dos ventanas diferentes y en una monitorizamos el estado del pod con:
```
kubectl get pod liveness-exec -w
```

En la otra ventana podemos ver los eventos con:
```
kubectl describe pod liveness-exec
```
