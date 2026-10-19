# GIT: Control de versiones y repositorios remotos

## Introducción

Este laboratorio introduce el uso de Git para registrar la evolución del código de un proyecto y compartir sus cambios mediante un `remote repository` (repositorio remoto). El trabajo se concentra en comprender el flujo básico y la terminología propia de Git.

La actividad comienza con la creación de un repositorio en un servicio remoto y la descarga de una copia en la máquina virtual. Sobre esa copia se realizará un primer ejercicio completamente guiado para modificar archivos, guardar una nueva versión y publicarla. Luego se repetirá el procedimiento con menos comandos explícitos, de modo que sea necesario reconocer qué operación corresponde realizar en cada momento.

### Prerrequisitos

- Tener iniciada la máquina virtual Lubuntu y haber clonado este repositorio
- Manejar el uso de la terminal y la edición de archivos mediante Vim
- Saber compilar y ejecutar un programa sencillo escrito en C
- Tener una cuenta en `github.com`
- Tener disponibles `git`, `ssh`, `ssh-keygen`, `gcc` y `bash`
- Considerar que el repositorio creado durante la actividad será público y no debe contener información sensible

### Objetivo general

- Utilizar Git para guardar distintas versiones de un proyecto en un `local repository` (repositorio local) y compartirlas mediante un `remote repository` alojado en un servicio remoto

### Objetivos específicos

- Configurar el nombre y el correo electrónico que identificarán las versiones creadas
- Conectarse de manera segura a un servicio remoto mediante SSH
- Descargar una copia local de un repositorio disponible en la web
- Reconocer los archivos modificados y seleccionar cuáles formarán parte de una nueva versión
- Inspeccionar los cambios mediante `git status`, `git diff` y `git diff --staged`
- Guardar versiones con contenido coherente y revisar su historia mediante `git log` y `git show`
- Compilar un programa sin incorporar el ejecutable generado a la historia del repositorio
- Restaurar un archivo modificado en el `working directory` (directorio de trabajo)
- Excluir archivos generados mediante `.gitignore`
- Enviar y recibir cambios mediante `git push` y `git pull`

### Estructura inicial

```text
workspace/
├── material/
│   ├── README.md
│   └── areaperimetro.c
├── scripts/
│   └── check.sh
└── repositorio/        <- se creará durante la actividad
```

- `material` contiene los archivos que se incorporarán al repositorio de práctica
- `scripts/check.sh` permite revisar qué actividades están completas y cuáles permanecen pendientes
- `repositorio` no existe inicialmente. Se creará al clonar el `remote repository` dentro de `workspace`

### Conceptos básicos

Git es una herramienta que permite guardar la historia de un proyecto. Un directorio administrado por Git se denomina repositorio. Sus archivos se continúan editando con Vim u otras herramientas, mientras Git permite reconocer qué cambió y conservar versiones anteriores.

Git no guarda automáticamente cada modificación. Antes de crear una nueva versión se deben seleccionar los cambios que se quieren incluir. Durante la actividad se utilizarán los siguientes términos, cuyos nombres en inglés son los utilizados habitualmente al trabajar con Git:

- El `working directory` (directorio de trabajo) corresponde a la carpeta que contiene los archivos que se están consultando o modificando
- El `staging area` (área de preparación), normalmente llamado `staging`, contiene la selección de cambios que formará parte de la próxima versión. Los cambios que se encuentran en esta selección se denominan `staged` (preparados)
- Un `commit` corresponde a una versión guardada del proyecto. Cada commit incluye los cambios seleccionados, un mensaje y la identidad de quien lo creó
- El `local repository` (repositorio local), normalmente llamado `local`, conserva en el equipo una copia de los archivos y la historia de commits
- El `remote repository` (repositorio remoto), normalmente llamado `remote`, conserva una copia de esa historia en un servicio remoto

El flujo básico consiste en modificar archivos en el `working directory`, seleccionarlos con `git add` para incorporarlos al `staging`, guardarlos en un commit mediante `git commit` y publicar ese commit en el `remote` con `git push`. En sentido contrario, `git pull` permite incorporar al `local` los commits disponibles en el `remote`.

## Actividad

En esta actividad se utilizará GitHub. Una conexión SSH normalmente utiliza el puerto 22, pero la red de trabajo no permite conexiones salientes por ese puerto. GitHub también ofrece acceso SSH mediante el puerto 443, por lo que se configurará esa alternativa antes de clonar el repositorio.

### 1. Preparar Git y el acceso al `remote`

#### 1.1. Entrar a `workspace` y configurar Git

Ir a `workspace` y revisar su contenido:

```bash
cd workspace
ls
```

Los comandos de las siguientes secciones consideran que el directorio actual es `workspace`, salvo cuando se indique que se debe entrar a `repositorio`.

Comprobar que Git se encuentra disponible:

```bash
git --version
```

Cada commit guarda el nombre y el correo electrónico de la persona que lo creó. Revisar si ambos datos ya se encuentran configurados:

```bash
git config --global user.name
git config --global user.email
```

Si alguno de los valores no está definido, o tiene un valor que no corresponde, configurarlo reemplazando los marcadores correspondientes:

```bash
git config --global user.name "<NOMBRE APELLIDO>"
git config --global user.email "<CORREO>"
```

Estos datos identifican al autor de cada commit, pero no corresponden al nombre de usuario ni a la contraseña utilizados para entrar al servicio remoto.

#### 1.2. Crear una llave SSH

Una conexión SSH es un canal de comunicación seguro entre dos equipos. En este laboratorio, uno de esos equipos es la máquina virtual y el otro es un servidor, es decir, un equipo que ofrece el servicio remoto. Git utilizará este canal para descargar y enviar información del repositorio.

Antes de permitir estas operaciones, el servicio remoto debe comprobar la identidad de quien se conecta. SSH puede realizar esta comprobación mediante llaves, sin solicitar la contraseña de la cuenta en cada operación.

Una llave SSH es un archivo que contiene información utilizada para autenticar al usuario. Al crear una llave SSH se generan dos archivos relacionados, llamados llave privada y llave pública. Ambos forman un par y cumplen funciones diferentes:

- La llave privada permite demostrar la identidad durante la conexión. Permanece en la máquina y no se debe compartir
- La llave pública se puede compartir y se registra en el servicio remoto. El servicio la utiliza para comprobar que la conexión se realiza con la llave privada correspondiente

Cuando Git se conecta, el servicio remoto comprueba que la máquina posee la llave privada asociada a la llave pública registrada. La llave privada no se envía al servicio durante este proceso.

Revisar el contenido del directorio `.ssh`, que es donde normalmente se guardan estas llaves:

```bash
ls -la ~/.ssh
```

Los archivos que terminan en `.pub` corresponden a llaves públicas. El archivo relacionado que tiene el mismo nombre sin `.pub` corresponde a la llave privada.

Las máquinas virtuales utilizadas en esta actividad deben comenzar sin llaves SSH. Si se encuentran llaves creadas anteriormente, se deben eliminar todos sus archivos antes de continuar, aunque aparezca solamente una parte de un par. Esto evita utilizar por error una llave perteneciente a otra sesión o a otro estudiante.

Por ejemplo, si aparecen los archivos `id_rsa` e `id_rsa.pub`, se deben eliminar mediante:

```bash
rm ~/.ssh/id_rsa ~/.ssh/id_rsa.pub
```

Si aparecen `id_ed25519` e `id_ed25519.pub`, se deben eliminar mediante:

```bash
rm ~/.ssh/id_ed25519 ~/.ssh/id_ed25519.pub
```

Si las llaves tienen otro nombre, eliminar sus archivos utilizando los nombres exactos observados con `ls`. No eliminar `known_hosts`, ya que ese archivo registra servidores conocidos y no corresponde a una llave personal.

Una vez comprobado que no quedan llaves anteriores, crear una llave nueva para la actividad:

```bash
ssh-keygen -t ed25519
```

El texto `ed25519` indica el tipo de llave que se creará. Aceptar la ruta propuesta y, para esta actividad en la máquina virtual, dejar vacía la contraseña de la llave (`passphrase`). Esta contraseña permite proteger adicionalmente la llave privada. El comando genera normalmente `~/.ssh/id_ed25519` y `~/.ssh/id_ed25519.pub`.

Mostrar solamente la llave pública:

```bash
cat ~/.ssh/id_ed25519.pub
```

#### 1.3. Registrar la llave y configurar el acceso

Registrar la llave pública en GitHub. Para esto hay que dirigirse al sitio web del servicio y agregar la llave desde `Settings` -> `SSH and GPG keys`.

El servidor SSH habitual de GitHub utiliza el puerto 22. Para utilizar el servidor alternativo disponible en el puerto 443 sin cambiar las URL de los repositorios, crear o editar el archivo de configuración de SSH:

```bash
vim ~/.ssh/config
```

Agregar las siguientes líneas y guardar el archivo:

```text
Host github.com
    HostName ssh.github.com
    User git
    Port 443
```

- `Host github.com` identifica las conexiones que utilizan el nombre habitual de GitHub
- `HostName ssh.github.com` establece el servidor alternativo que recibirá la conexión
- `User git` establece el usuario utilizado por el servicio SSH
- `Port 443` establece el puerto por el que se realizará la conexión

Una vez que la llave pública está registrada y el archivo se encuentra configurado, probar la conexión:

```bash
ssh -T git@github.com
```

Aunque el comando utiliza el nombre `github.com`, SSH leerá el archivo de configuración y se conectará a `ssh.github.com` mediante el puerto 443. El texto `git@github.com` identifica al servicio SSH y no se debe reemplazar por un correo personal. La primera conexión puede solicitar que se confirme la identidad del servidor mediante su huella, que corresponde a un identificador de ese servidor. En ese caso, revisar que aparezca `ssh.github.com` y responder `yes`.

### 2. Crear y clonar el `remote repository`

#### 2.1. Crear el repositorio en el servicio remoto

Los servicios remotos permiten alojar `remote repositories`, es decir, guardar en un servidor externo una copia de un repositorio. Desde la interfaz web de GitHub, crear un repositorio con las siguientes características:

- Nombre `inf20125-git-<ROL>` reemplazando `<ROL>` por el identificador del estudiante
- Visibilidad pública
- Inicializado con un archivo `README.md`
- Sin plantilla de `.gitignore` y sin licencia

El `README.md` creado al inicializar el `remote` queda registrado en un primer commit. De esta manera, el repositorio ya contiene una versión que se puede descargar.

Copiar la URL SSH presentada por GitHub. Esta dirección identifica el repositorio y permite conectarse con él mediante la llave registrada anteriormente. La URL tiene una forma similar a la siguiente:

```text
git@github.com:<USUARIO>/inf20125-git-<ROL>.git
```

Una URL que comienza con `https://` utiliza un tipo de conexión diferente del seleccionado para esta actividad y no corresponde a las operaciones siguientes.

#### 2.2. Clonar e inspeccionar el repositorio

Clonar un repositorio significa descargar sus archivos y su historia para comenzar a trabajar con ellos en el equipo. Para continuar, clonar el repositorio dentro de `workspace`. Reemplazar `<URL_SSH>` y mantener `repositorio` como destino:

```bash
git clone <URL_SSH> repositorio
```

Este comando se ha utilizado en laboratorios anteriores, pero en esta ocasión se agrega una palabra después de la URL. Esta palabra corresponde al nombre de la carpeta que se creará para guardar el repositorio. Si no se incluye, la carpeta recibe el mismo nombre del repositorio.

Entrar al repositorio clonado:

```bash
cd repositorio
```

Inspeccionar el repositorio clonado:

```bash
git status
git log --oneline
git remote -v
```

- `git status` informa el estado del `working directory` y del `staging`
- `git log --oneline` muestra una versión resumida de la historia del `local`
- `git remote -v` muestra la dirección guardada con el nombre `origin`, tanto para recibir como para enviar cambios

En este momento el `working directory` debería estar `clean` (limpio). Esto significa que sus archivos coinciden con el último commit y no existen cambios pendientes. La historia debería contener el commit que creó el `README.md` en el `remote`.

### 3. Primer ciclo de trabajo guiado

#### 3.1. Incorporar el programa inicial

Copiar al repositorio los archivos entregados en `material`:

```bash
cp ../material/README.md .
cp ../material/areaperimetro.c .
```

Revisar el estado y las diferencias:

```bash
git status
git diff
```

`README.md` ya pertenecía al repositorio porque fue incluido en el primer commit. Por eso corresponde a un archivo `tracked` (rastreado) y Git lo reconoce como modificado. En cambio, `areaperimetro.c` aparece como un archivo `untracked` (no rastreado): existe en el `working directory`, pero todavía no ha formado parte de ningún commit.

`git diff` muestra qué líneas cambiaron en los archivos `tracked`. No presenta el contenido de los archivos `untracked`.

#### 3.2. Preparar los cambios

Antes de guardar una nueva versión se deben seleccionar los cambios que formarán parte de ella. Agregar ambos archivos al `staging`:

```bash
git add README.md areaperimetro.c
```

Revisar nuevamente el estado y luego el contenido disponible en el `staging`:

```bash
git status
git diff --staged
```

#### 3.3. Crear el primer commit local

Un commit guarda en la historia una nueva versión formada por los cambios disponibles en el `staging`. La opción `-m` permite incluir un mensaje breve que describe esa versión. Crear el commit:

```bash
git commit -m "Agrega programa inicial"
```

Comprobar el estado y revisar la historia:

```bash
git status
git log --oneline
git show HEAD
```

Git utiliza el nombre `HEAD` para identificar el commit actual. `git show HEAD` presenta la información y los cambios guardados en ese commit.

El `working directory` debería encontrarse `clean`, pero el nuevo commit todavía existe solamente en el `local`. Aún no ha sido enviado al servicio remoto.

#### 3.4. Enviar el commit al `remote`

`git push` envía al `remote` los commits creados en el `local`. No envía modificaciones que todavía no hayan sido guardadas en un commit. Publicar el commit con:

```bash
git push
```

Actualizar la página del repositorio en el navegador y comprobar que aparecen `README.md`, `areaperimetro.c` y el nuevo commit.

### 4. Compilar, ignorar y corregir el programa

#### 4.1. Compilar y ejecutar el programa

El programa `areaperimetro.c` lee el radio de un círculo desde la entrada estándar y muestra su área y su perímetro.

Construir el comando necesario para compilar `areaperimetro.c` con `-Wall`, `-Wextra`, `-Werror` y `-std=c11`. El ejecutable debe llamarse `areaperimetro` y quedar en la raíz del repositorio clonado.

Ejecutar el programa, ingresar el radio `5` y observar la salida:

```text
Área: 78.54
Perímetro: 15.71
```

En esta sección solamente se utilizará el ejecutable para observar cómo Git trata un archivo generado.

#### 4.2. Ignorar el ejecutable

Revisar el estado del repositorio. `areaperimetro` debería aparecer como un archivo `untracked` porque fue generado después del último commit.

El ejecutable se puede volver a generar compilando `areaperimetro.c`, por lo que no es necesario guardarlo en la historia. En cambio, el código fuente sí debe conservarse, ya que contiene las instrucciones escritas por quien desarrolla el programa.

`.gitignore` es un archivo de texto que contiene nombres o patrones correspondientes a los archivos que Git debe omitir. Estos archivos se denominan `ignored` (ignorados). `.gitignore` no los elimina del directorio; solamente evita que Git los muestre como archivos `untracked` y que se agreguen accidentalmente al repositorio.

Crear `.gitignore` con Vim y agregar:

```text
/areaperimetro
```

La línea indica que Git debe ignorar el archivo llamado `areaperimetro` ubicado en la raíz del repositorio. Revisar nuevamente el estado. El ejecutable ya no debería aparecer entre los archivos `untracked`. Para mostrar explícitamente los archivos `ignored` se puede utilizar:

```bash
git status --ignored
```

Agregar solamente `.gitignore` al `staging`, revisar el contenido seleccionado y crear un commit con el mensaje `Ignora el ejecutable`. Enviar el commit al `remote`. El ejecutable debe permanecer en el `working directory`, pero no debe formar parte del commit.

#### 4.3. Corregir y comprobar el programa

Para un círculo de radio `5`, el área mostrada por el programa es correcta, pero su perímetro debería ser `31.42`.

Revisar `areaperimetro.c` con Vim, identificar la expresión que produce el valor incorrecto y corregirla.

Volver a compilar con las mismas flags utilizadas anteriormente. Ejecutar el programa e ingresar nuevamente el radio `5`. La salida debe ser:

```text
Área: 78.54
Perímetro: 31.42
```

La nueva compilación reemplaza el ejecutable ignorado, pero no cambia su estado en Git. Los cambios realizados en `areaperimetro.c` sí permanecen pendientes.

#### 4.4. Guardar la corrección

Revisar el estado y la diferencia antes de agregar el cambio al `staging`. El único archivo modificado que debe aparecer es `areaperimetro.c`; el ejecutable continúa como `ignored`, por lo que no se reporta aunque haya cambiado.

En esta sección no se entregan los comandos completos. Utilizar las operaciones practicadas anteriormente para agregar solamente el cambio de `areaperimetro.c` al `staging`, revisar el contenido seleccionado y crear un commit con el mensaje `Corrige el cálculo del perímetro`.

Revisar la historia resumida y utilizar `git show` para comprobar que el commit contiene solamente la corrección del código. Luego enviar el commit al `remote`.

### 5. Restaurar una modificación local

Editar `areaperimetro.c`, reemplazar el valor `3.14159` de `pi` por `3.141592653589793` y guardar el archivo. Revisar la diferencia luego de compilar y ejecutar (sin agregar el cambio al `staging`).

Como los resultados se muestran con dos decimales, esta mayor precisión no produce una diferencia visible en la salida para el radio utilizado. Sin embargo, Git detecta que el contenido del archivo fue modificado.

Esta modificación se puede considerar una prueba numérica y no debe formar parte de una nueva versión. Por lo tanto, se debe recuperar el contenido registrado en el commit anterior.

Restaurar el archivo mediante:

```bash
git checkout -- areaperimetro.c
```

En este comando, `--` separa la operación del nombre del archivo. Como la modificación de `areaperimetro.c` no fue agregada al `staging`, el comando recupera el contenido guardado en el último commit.

Volver a revisar la diferencia y el contenido de `areaperimetro.c`. La modificación debería haber desaparecido. Esta operación descarta los cambios que no fueron guardados en un commit y _Git no conserva una copia que permita recuperarlos_ por lo que hay que tener cuidado al usar esta funcionalidad.

### 6. Incorporar un cambio desde el `remote`

Desde la interfaz web del servicio remoto, realizar las siguientes acciones:

- Abrir `README.md`
- Editar el archivo
- Agregar al final la línea `Última revisión remota: completada.`
- Crear el commit desde la interfaz web

El `remote` contiene ahora un commit que todavía no forma parte del `local`.

Anteriormente se utilizó `git push` para enviar commits desde el `local` hacia el `remote`. `git pull` realiza el recorrido contrario: descarga los commits disponibles en el `remote` y los incorpora a la historia del `local`.

Volver a la terminal y comprobar que el `working directory` se encuentre `clean`. Incorporar el cambio disponible en el `remote`:

```bash
git pull
```

Revisar `README.md`, la historia resumida y el estado del repositorio. El cambio creado en la web debe aparecer en el `local` y ambas historias deben contener los mismos commits.

### 7. Verificar la actividad

Volver a `workspace`, revisar los permisos de `scripts/check.sh` y agregar permiso de ejecución para el propietario.

Ejecutar `scripts/check.sh` desde `workspace`. El script permite revisar qué actividades están completas y cuáles permanecen pendientes.

La revisión utiliza solamente el `local`: no solicita un nombre de usuario ni una contraseña, y tampoco se conecta nuevamente con el servicio remoto.

## Actividad complementaria: inicializar un `local repository`

`git clone` crea un `local` a partir de un `remote` y configura `origin` automáticamente. Git también permite comenzar desde una carpeta que todavía no está asociada a un servicio remoto.

Desde `workspace`, crear una carpeta separada, entrar en ella e inicializarla:

```bash
mkdir repositorio-local
cd repositorio-local
git init
```

Crear un archivo de texto y observar su estado. Luego agregar el archivo al `staging`, crear el primer commit y revisar la historia. Finalmente, ejecutar `git remote -v` y comprobar que no aparece ningún `remote`: `git init` crea un `local`, pero no lo conecta automáticamente con un servicio remoto.

Esta actividad es complementaria y no forma parte de las comprobaciones de `check.sh`.

## Limpieza de la llave SSH

Al terminar la actividad, eliminar primero la llave pública desde la configuración del servicio remoto. Luego eliminar de la máquina virtual el par creado durante la sesión:

```bash
rm ~/.ssh/id_ed25519 ~/.ssh/id_ed25519.pub
```

Eliminar los archivos locales no elimina la llave pública registrada en el servicio remoto. Por eso se deben completar ambos pasos.
