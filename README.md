![imagen](https://user-images.githubusercontent.com/3116368/226235603-ff82d30b-c854-4f32-a1a1-28fc8ad73c42.png)

Script que muestra los dispositivos WiFi conectados. Simplemente se autentica al Router, se trae un JSON con los datos de los dispositivos y los pinta en una tabla.

Con este Script he aprendido que los arrays de 1 solo elemento se "aplanan/flatten" y hay que usar `,$variable` para que devuelva el array.

Odio PowerShell pero va bien 👍

(Me tomo la molestia de censurar la imagen pero es bastante obvio que la dirección del router es `192.168.1.1`)

Es importante que si vas a usarlo (¿De verdad es necesario?) ajustes el usuario y la contraseña de la petición de autenticación.

Por pereza pura cada vez que quieras refrescar genera una nueva petición a autenticarse. 
No sé si se bloquea al realizar tantas peticiones pero entiendo que va bien.

Cada dia se aprende algo. Con esto podría hacer un ServiceProvider especifico para manejar routers desde un punto centralizado usando Laravel o algo así.

Las posibilidades son infinitas.
