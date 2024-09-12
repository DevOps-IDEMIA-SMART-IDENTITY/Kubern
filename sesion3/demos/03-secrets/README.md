<a name="secrets"></a>
# Uso de Secrets en Kubernetes

Los Secrets tienen una naturaleza y forma de uso similar a la de los `ConfigMaps`, por lo que en este documento nos centraremos simplemente en las peculiaridades de los secrets debido a su naturaleza codificada.

Echa un vistazo a la [demostración de configmaps](./configmaps.md) antes de continuar.

Índice de contenidos:

- [Creación de Secrets](#create)
- [Decodificación de Secrets](#decode)
- [Uso de Secrets](#use)

<a name="create"></a>
## Creación de Secrets

Los secrets son especiales porque van codificados, por lo que crearlos no es tan sencillo como los `ConfigMaps`.

### Manualmente, a través de fichero yaml

Podemos crear `Secrets` directamente a través de ficheros `yaml`. Para ello tenemos que codificar previamente los valores de las claves en `base64` (a diferencia de cuando creamos `ConfigMaps`).


Si quisiéramos añadir los valores 'admin' y '1f2d1e2e67df' a un secret que indique el usuario y la password deberemos hacer lo siguiente:

```
echo -n 'admin' | base64
YWRtaW4=
echo -n '1f2d1e2e67df' | base64
MWYyZDFlMmU2N2Rm
```

Una vez tenemos los valores codificados procedemos a crear el `Secret` de la siguiente manera:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: secret-manual
type: Opaque
data:
  username: YWRtaW4=
  password: MWYyZDFlMmU2N2Rm
```

Y lo creamos vía `kubectl`:

```
kubectl apply -f 01-secret.yaml
```

Nota: en lugar de la sección `data` (que ha de ir codificada) podríamos usar `stringData`.

### Desde ficheros

Imaginemos ahora que guardamos el nombre y contraseña que una aplicación necesita utilizar en dos ficheros en nuestra máquina, tal que:

```
# Creamos archivos necesarios para el resto del ejemplo.
echo -n 'admin' > ./username.txt
echo -n '1f2d1e2e67df' > ./password.txt
```

Podemos crear un `Secret` con esas dos keys de esta forma:
```shell
kubectl create secret generic db-user-pass --from-file=./username.txt --from-file=./password.txt
```

Si echamos un vistazo al `Secret` creado...

```shell
kubectl describe secrets/db-user-pass

Name:            db-user-pass
Namespace:       default
Labels:          <none>
Annotations:     <none>

Type:            Opaque

Data
====
password.txt:    12 bytes
username.txt:    5 bytes
```

__OJO!__: Como veis las keys no son las mismas en los 2 casos. ¿Cómo podríamos hacer para que las keys en el segundo caso fueran `username` y `password` en lugar de `username.txt` y `password.txt`?

### Desde literales

Al igual que con `ConfigMaps` podemos añadir las keys directamente desde la línea de comandos. __OJO__! Puede ser necesario escapar algunos caracteres especiales para que no los procese la shell antes de lanzar el comando (`$`, `\`, `*`, `!`), por lo que es recomendable utilizar comillas simples al lanzar el parámetro.

Ejemplos:
```shell
kubectl create secret generic test-db-secret --from-literal=username=testuser --from-literal=password=iluvtests

# Ejemplo con comilla simple para NO tener que escapar caracteres.
kubectl create secret generic dev-db-secret --from-literal=username=devuser --from-literal=password='S!B\*d$zDsb='
```

<a name="decode"></a>
### Decodificando Secrets

Si obtenemos lo siguiente de un Secret:

```yaml
data:
  username: YWRtaW4=
  password: MWYyZDFlMmU2N2Rm
```

Podremos decodificar cada key con el comando `base64 --decode`:

```shell
$ echo 'MWYyZDFlMmU2N2Rm' | base64 --decode
1f2d1e2e67df
```

<a name="use"></a>
### Uso de Secrets

El uso de Secrets es igual que el de los ConfigMaps. Revisa la [demostración de ConfigMaps](../02-configmaps/README.md) si tienes alguna duda de cómo funciona y en qué condiciones se montan ficheros o directorios.

Dejamos aquí ejemplos de referencia y comentarios:

### Uso de Secrets como volúmenes

Al igual que con `ConfigMaps`, dentro del contenedor que monta un volumen del Secret, las `keys` del Secret aparecen como archivos y los valores del Secret son decodificados en base-64 y almacenados dentro de estos archivos.

- Ejemplo 1: El contenido de `mysecret` se monta en __directorio__ `/etc/foo` del contenedor (múltiples archivos o lo que tenga el secret)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: mypod
spec:
  containers:
  - name: mypod
    image: redis
    volumeMounts:
    - name: foo
      mountPath: "/etc/foo"
      readOnly: true
  volumes:
  - name: foo
    secret:
      secretName: mysecret
```

- Ejemplo 2: La key `username` del secret `mysecret` se montará en el __fichero__ `/etc/foo/my-group/my-username`.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: mypod
spec:
  containers:
  - name: mypod
    image: redis
    volumeMounts:
    - name: foo
      mountPath: "/etc/foo"
      readOnly: true
  volumes:
  - name: foo
    secret:
      secretName: mysecret
      items:
      - key: username
        path: my-group/my-username
```

### Uso de Secrets en variables de entorno

- Ejemplo: 2 variables de entorno se configuran desde 2 keys diferentes del __mismo secret__.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secret-env-pod
spec:
  containers:
  - name: mycontainer
    image: redis
    env:
      - name: SECRET_USERNAME
        valueFrom:
          secretKeyRef:
            name: mysecret
            key: username
      - name: SECRET_PASSWORD
        valueFrom:
          secretKeyRef:
            name: mysecret
            key: password
  restartPolicy: Never
```
