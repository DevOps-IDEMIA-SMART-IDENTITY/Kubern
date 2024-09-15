<a name="resources"></a>
# Volúmenes

Indice de contenidos:

- [Conceptos Básicos](#conceptos)
- [Creación de Volumen externo](#setup)
- [Declaración de pod](#pod)

<a name="conceptos"></a>
## Conceptos Básicos

Resumen de conceptos:
- `Volumes`: Se declaran en los pods. Pueden ser de muchos tipos, entre ellos:
  - `ConfigMap`
  - `Secret`
  - `EmptyDir` / `Hostpath` (storage local)
  - Storage de red --> `gcePersistentDisk` (Discos de GCP).
  - ...

- `PersistentVolumes` (PVs): Volumen persistente con ciclo de vida manejado por Kubernetes. Se pueden crear manualmente o dinámicamente gracias a las `StorageClasses` y `PersistentVolumeClaims` (PVCs)

- Consumo de storage por parte de los `pods`: a través de `Volumes` o a través de `volumeClaimTemplates`. Los pods no consumen directamente `PersistentVolumes`.

- Para que un pod pueda estar asociado a un `PersistentVolume` hará falta crear tanto el PV como el PVC, y asociar el pod al `PVC` (mediante `volumeClaimTemplates`). [Aquí](https://kubernetes.io/docs/tasks/configure-pod-container/configure-persistent-volume-storage/) puedes encontrar un buen ejemplo de pod, PV y PVC creados manualmente.

Para esta demostración usaremos en Google Cloud un cluster `GKE` y volúmenes del tipo `gcePersistentDisk` con provisionamiento manual, sin PV ni PVC. Veremos los PVs, PVCs y StorageClasses en la demostración de `StatefulSets`.

<a name="setup"></a>
## Creación inicial del volumen

Creamos un disco en nuestra cloud en la misma región donde esté el cluster de Kubernetes.

```shell
gcloud compute disks create --size=10GB --zone=europe-west1-b my-data-disk
```

Creamos pod que monte el volumen en el directorio `/test-pd`

- Referencia:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: volume-pd-test
spec:
  containers:
  - image: nginx
    name: test-container
    volumeMounts:
    - mountPath: /test-pd
      name: test-volume
  volumes:
  - name: test-volume
    # This GCE PD must already exist.
    gcePersistentDisk:
      pdName: my-data-disk
      fsType: ext4
```

- Creamos el POD:

```shell
kubectl apply -f resources/volume-pd-test.yaml
```

Tras la creación, el describe del pod debería devolver algo como:
```shell
Events:
  Type    Reason                  Age   From                     Message
  ----    ------                  ----  ----                     -------
  Normal  Scheduled               9s    default-scheduler        Successfully assigned default/volume-pd-test to gke-keepcoding-default-pool-7b2ab140-b7vr
  Normal  SuccessfulAttachVolume  5s    attachdetach-controller  AttachVolume.Attach succeeded for volume "test-volume"
  ...
  ...
```

Podemos conectarnos al pod y escribir algo en el volumen con:
```shell
kubectl exec -it volume-pd-test -- bash

# una vez dentro
echo hola > /test-pd/fichero-prueba.txt
exit
```

Eliminamos el pod:
```shell
kubectl delete pod volume-pd-test
```

Lo creamos otra vez:
```shell
kubectl apply -f resources/volume-pd-test.yaml
```

Comprobamos si los datos siguen existiendo:
```shell
kubectl exec -it volume-pd-test -- ls -l /test-pd

total 24
-rw-r--r-- 1 root root     5 Feb  7 15:03 fichero-prueba.txt
```

Limpiamos todo, borrado del pod y eliminamos disco en GCP.
```shell
kubectl delete -f resources/volume-pd-test.yaml
gcloud compute disks delete --zone=us-west1-a my-data-disk
```

__Conclusiones__

- Trabajar de esta forma requeriría un mantenimiento (creación y borrado) de los volúmenes manual, por parte del administrador.
- Normalmente trabajaremos con `StorageClasses`, `PersistentVolumeClaims` y `PersistentVolumes`.
