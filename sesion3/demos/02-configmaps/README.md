# ConfigMaps

Índice de contenidos:

- [Creación de ConfigMaps desde distintas fuentes](#create)
- [Uso de ConfigMaps como variables de entorno en pods](#env)
- [Uso de ConfigMaps como volúmenes y puntos de montaje para pods](#volume)

<a name="create"></a>
## Creación ConfigMaps desde distintas fuentes

Para la demostración de los distintos métodos, utilizaremos los siguientes recursos:

- Directorio `configmap-data` con ficheros fuente para nuestros `ConfigMaps`. Ahí encontraremos:

  - Fichero `game.properties`, con el siguiente contenido:

  ```
  enemies=aliens
  lives=3
  enemies.cheat=true
  enemies.cheat.level=noGoodRotten
  secret.code.passphrase=UUDDLRLRBABAS
  secret.code.allowed=true
  secret.code.lives=30
  ```

  - Fichero `ui.properties`, con el siguiente contenido:
  ```
  color.good=purple
  color.bad=yellow
  allow.textmode=true
  how.nice.to.look=fairlyNice
  ```

  - Otros ficheros como `datos-texto` y `filebeat-conf.yaml` para que veamos como las fuentes de los configmaps pueden tener cualquier cosa.

### Desde yaml declarativo

Podemos crear un `ConfigMap` desde un `yaml` como el resto de objetos de Kubernetes.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-config
data:
  conf.properties: |
    color=blue
    country=Spain
  conf.json: |
    {"color": "blue", "country": "Spain"}
  otrakey: "value"
  filetext: |
    este es el contenido
    de la clave del configmap
    que representa
    un fichero de texto  
```

Para crearlo:

```shell
kubectl apply -f 01-configmap.yaml
```

### Directorios

Podemos crear un ConfigMap con el contenido completo de un directorio. Se nos creará una "key" por cada fichero (con el nombre del fichero), y el valor de cada una será el contenido del propio fichero:

```shell
$ kubectl create configmap game-config --from-file=./configmap-data/
configmap/game-config created
```

Si hacemos un describe veremos lo siguiente:

```shell
kubectl describe configmaps game-config
```

La salida será algo como:

```shell
Name:         game-config
Namespace:    default
Labels:       <none>
Annotations:  <none>

Data
====
ui.properties:
----
color.good=purple
color.bad=yellow
allow.textmode=true
how.nice.to.look=fairlyNice

game.properties:
----
enemies=aliens
lives=3
enemies.cheat=true
enemies.cheat.level=noGoodRotten
secret.code.passphrase=UUDDLRLRBABAS
secret.code.allowed=true
secret.code.lives=30

BinaryData
====

Events:  <none
```

No es el uso más habitual, generalmente se crean los configmaps desde ficheros específicos.

### Ficheros

Podemos crear los ConfigMaps desde ficheros individuales con la opción `--from-file`:

```shell
kubectl create configmap game-config-2 --from-file=02-file.properties
```

### Ficheros env

Si nuestro fichero contiene variables de entorno en un formato adecuado la opción `--from-file-env` permitirá guardar el ConfigMap guardando cada variable de entorno como una `key` distinta (en lugar de ser el nombre de fichero la `key`).


```shell
kubectl create configmap game-config-env-file --from-env-file=02-file.properties
```

Lo anterior producirá un `ConfigMap` como estos datos:
```yaml
data:
  allowed: '"true"'
  enemies: aliens
  lives: "3"
```

En lugar del procesamiento de fichero por defecto que crearía:

```yaml
data:
  game-env-file.properties: |
    enemies=aliens
    lives=3
    allowed="true"

    # This comment and the empty line above it are ignored
```

__Notas__:
  - `--from-file` se puede utilizar varias veces en el mismo comando para añadir múltiples keys al configmap.
  - `--from-env-file` no se puede usar múltiples veces en el mismo comando, solo se procesará el último fichero.


### Elegir `key` al crear configmap desde un fichero:

La siguiente sintaxis provoca que la `key` generada sea la elegida en lugar del nombre del fichero: `kubectl create configmap game-config-3 --from-file=<my-key-name>=<path-to-file>`.

Por ejemplo:

```shell
kubectl create configmap game-config-3 --from-file=game-special-key=03-file-key.properties

# Lo anterior genera
# data
#   game-special-key: |-
#     enemies=aliens
#     lives=3
#     enemies.cheat=true
#     enemies.cheat.level=noGoodRotten
#     secret.code.passphrase=UUDDLRLRBABAS
#     secret.code.allowed=true
#     secret.code.lives=30
```

### Crear ConfigMap desde valores literales

Generará tantas keys y valores como añadamos:

```shell
kubectl create configmap special-config --from-literal=special.how=very --from-literal=special.type=charm
```

El resultado será:

```yaml
data:
  special.how: very
  special.type: charm
```

<a name="env"></a>
## Uso de Confimaps como variables de entorno en pods

### Definición de variables de entorno desde ConfigMaps

Para la demostración creamos un `ConfigMap` sencillo con una `key`:

```shell
kubectl create configmap special-config-key --from-literal=special.how=very
```

Añadimos a un contenedor de un Pod la variable de entorno `SPECIAL_LEVEL_KEY` haciendo referencia al ConfigMap creado y clave `special.how` (el valor debería de ser `very`).

Para ello utilizaremos `valueFrom` en la especificación de la variable de entorno que queremos configurar.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-configmap-value-from
spec:
  containers:
    - name: test-container
      image: busybox
      command: [ "/bin/sh", "-c", "env" ]
      env:
        # Define the environment variable
        - name: SPECIAL_LEVEL_KEY
          valueFrom:
            configMapKeyRef:
              # The ConfigMap containing the value you want to assign to SPECIAL_LEVEL_KEY
              name: special-config-key
              # Specify the key associated with the value
              key: special.how
  restartPolicy: Never
```

Cramos el pod:

```shell
kubectl apply -f 04-pod-configmap-value-from.yaml
```

Comprobamos resultado:

```shell
kubectl logs pod-configmap-value-from | grep  SPECI
```

## Añadir todas las key de un ConfigMap como variables de entorno

Crearemos el siguiente ConfigMap:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: special-config-multi
data:
  SPECIAL_LEVEL: very
  SPECIAL_TYPE: charm
```

Ejecutamos el comando:

```shell
kubectl apply -f 05-configmap-multikeys.yaml
```

Usamos `envFrom` en la especificación del contenedor para cargar un ConfigMap completo como variables de entorno.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-configmap-env-from
spec:
  containers:
    - name: test-container
      image: busybox
      command: [ "/bin/sh", "-c", "env" ]
      envFrom:
      - configMapRef:
          name: special-config-multi
  restartPolicy: Never
```

Lanzamos el ejemplo:

```shell
kubectl apply -f 06-pod-configmap-env-from.yaml
```

Comprobamos el resultado:

```shell
kubectl logs pod-configmap-env-from | grep SPEC
```

### Uso de variables de entorno en los comando a ejecutar (CMD / ENTRYPOINT)

Esto no tiene relación estricta con los `ConfigMaps` ya que aunque una variable de entorno no esté relacionada con un `ConfigMap` siempre se podrá usar en el `command` (entrypoint) o `args` de la especificación del contenedor.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-configmap-command
spec:
  containers:
    - name: test-container
      image: busybox
      command: [ "/bin/echo", "$(SPECIAL_LEVEL_KEY) $(SPECIAL_TYPE_KEY)" ]
      env:
        - name: SPECIAL_LEVEL_KEY
          valueFrom:
            configMapKeyRef:
              name: special-config-multi
              key: SPECIAL_LEVEL
        - name: SPECIAL_TYPE_KEY
          valueFrom:
            configMapKeyRef:
              name: special-config-multi
              key: SPECIAL_TYPE
  restartPolicy: Never
```

Para probar y comprobar:

```shell
kubectl apply -f 07-pod-configmap-command.yaml

kubectl logs pod-configmap-command
```

<a name="volume"></a>
## Uso de Confimaps como volumenes y puntos de montaje en pods

Podemos definir un `volumen` y que cargue los datos desde un ConfigMap. Posteriormente este volumen se puede `montar` en el contenedor como un fichero o directorio, dependiendo de las opciones usadas tanto en la definición del volumen como del montaje.

### Montando directorios

Cuando creamos un `volumen desde un ConfigMap` y lo montamos en un destino, este destino será un directorio y cada `key` del ConfigMap será un fichero en el directorio final, incluso si el `ConfigMap` solamente tuviera una clave.

Ejemplo de montaje de directorio:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-configmap-mount-volume
spec:
  containers:
    - name: test-container
      image: busybox
      command: [ "/bin/sh", "-c", "ls /etc/config/" ]
      volumeMounts:
      - name: config-volume
        mountPath: /etc/config
  volumes:
    - name: config-volume
      configMap:
        # Provide the name of the ConfigMap containing the files you want
        # to add to the container
        name: special-config-multi
  restartPolicy: Never
```

Para probar este ejemplo:

```shell
kubectl apply -f 08-pod-configmap-mount-volume.yaml
kubectl logs pod-configmap-mount-volume
```

### Montando ficheros (I)

Para montar solamente un `fichero` desde un `ConfigMap` con múltiples claves definiremos la `key` del `ConfigMap` directamente en la declaración del volumen, y un `path` para indicar el nombre del fichero final.

Ejemplo de punto de montaje para archivo:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-configmap-mount-file
spec:
  containers:
    - name: test-container
      image: busybox
      command: [ "/bin/sh","-c","ls -l /etc/config/filetest; echo; echo \"# Contenido\"; cat /etc/config/filetest" ]
      volumeMounts:
      - name: config-volume
        mountPath: /etc/config
  volumes:
    - name: config-volume
      configMap:
        name: special-config-multi
        items:
        - key: SPECIAL_LEVEL # Key del configmap
          path: filetest # fichero de destino
  restartPolicy: Never
```

El ejemplo anterior define el volumen `config-volume` cargando la key `SPECIAL_LEVEL` solamente, y la guarda con un path `filetest` (el volumen tendrá un fichero llamado `filetest` y no `SPECIAL_LEVEL`). Posteriormente el volumen se monta en `/etc/config` por lo que el fichero `filetest` acaba en `/etc/config`.

Para probar este ejemplo:

```
kubectl apply -f 09-pod-configmap-mount-file.yaml

kubectl logs pod-configmap-mount-file
```

### Montando ficheros (II)

El caso más típico suele ser montar únicamente un fichero desde un `ConfigMap` donde solamente definimos ese fichero.

- Imaginemos que tenemos un `ConfigMap` que define `config.yaml` de la siguiente forma:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: configmap-mount-simple
  namespace: default
data:
  config.yaml: |
    # este es un fichero yaml de prueba
    clave: valor
    array:
      - "uno"
      - "dos"
    otro: prueba
```

- El objetivo es montar ese fichero en `/app/config.yaml` de un contenedor (por ejemplo).

Para ello hay dos opciones:
- Definir el volumen cargándolo desde el `ConfigMap` e indicando la `key` y `path` (como en el ejemplo anterior).
- Definir el volumen cargando todo el `ConfigMap` y en el `volumeMount` indicar un `subPath`. El `subpath` es una indicación de que queremos montar sólo parte del volumen (en este caso un fichero concreto) en el destino, en caso contrario un `volumen` completo siempre se montará como `directorio`.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-configmap-mount-simple
spec:
  containers:
    - name: test-container
      image: busybox
      command: [ "/bin/sh","-c","cat /app/config.yaml" ]
      volumeMounts:
      - name: config-volume
        mountPath: /app/config.yaml # destino del mount
        subPath: config.yaml # key del configmap
  volumes:
    - name: config-volume
      configMap:
        name: configmap-mount-simple
  restartPolicy: Never
```

Si quitáramos el `subPath` en el ejemplo anterior, el volumen se montaría en un directorio `/app/config.yaml`, y dentro de este directorio nos encontraríamos el fichero. Obviamente no es lo que queremos.

Para probar este ejemplo:
```
# Creamos ConfigMap y POD
kubectl apply -f 10-configmap-mount-simple.yaml
kubectl apply -f 11-pod-configmap-mount-simple.yaml

# Observamos los logs del pod (ejecuta cat /app/config.yaml)
kubectl logs pod-configmap-mount-simple
# este es un fichero yaml de prueba
clave: valor
array:
  - "uno"
  - "dos"
otro: prueba
```

__Troubleshooting__

Problemas típicos:
- Intentas montar uno o varios ficheros y se montan como __directorios__. Hay que revisar el `ConfigMap` y sobre todo la definición del `volumen` y `volumeMount`.
