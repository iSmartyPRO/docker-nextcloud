# Краткое описание
Файловое облачное хранилище.
Отлично подойдет для корпоративных пользователей.
Имеется возможность авторизовать через Active Directory.

# Устанавливаемые контейнеры
* nextcloud
# Как пользоваться

## Установка

скопируйте файл .env.sample на .env и заполните своими данными

```
docker-compose up -d
```

## Удаление
```
docker-compose down
```

## Создание базы данных MySQL для NextCloud
```
CREATE DATABASE nextcloud CHARACTER SET utf8 COLLATE utf8_bin;
CREATE USER 'nextcloud'@'%' IDENTIFIED BY 'SuperPassword!';
GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud'@'%';
FLUSH PRIVILEGES;
```

## Конфигурация для Nginx сервера
```
server {
    server_name cloud.example.com;

    location / {
        proxy_pass http://nextcloud/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload";
        client_max_body_size 0;

        access_log /var/log/nginx/cloud.example.com.access.log;
        error_log /var/log/nginx/cloud.example.com.error.log;
    }

    location /.well-known/carddav {
      return 301 $scheme://$host/remote.php/dav;
    }

    location /.well-known/caldav {
      return 301 $scheme://$host/remote.php/dav;
    }
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    listen [::]:443 ssl http2; # managed by Certbot
    listen 443 ssl http2; # managed by Certbot
    ssl_certificate /etc/nginx/conf.d/ssl/cloud.example.com.crt;
    ssl_certificate_key /etc/nginx/conf.d/ssl/cloud.example.com.key;
}

server {
    if ($host = cloud.example.com) {
        return 301 https://$host$request_uri;
    } # managed by Certbot

        listen 80;
        listen [::]:80;

        server_name cloud.example.com;
    return 404; # managed by Certbot
}
```

## Дополнение
После установки, необходимо создать пользователя с правами администратора и далее донастроить под нужды компании.

## Включение поддержки SMB
для того чтобы включить поддержку SMB необходимо установить клиент:

```
docker exec -ti nextcloud bash
apt update
apt install smbclient
```

### в более свежих версиях нужно дополнительно настраивать
Оригинал статьи: https://www.reddit.com/r/NextCloud/comments/k0pmpv/how_do_i_get_smbclient_installed_in_my_docker/

Команды для докер контейнера:
```
apt install smbclient libsmbclient-dev
pecl install smbclient
docker-php-ext-enable smbclient
```
после чего контрольно перезагрузить контейнер.

## Решение проблемы - не авторизуется сразу - приходиться вводить данные авторизации, потом обновлять страницу
в консоле выдается ошибка: because it violates the following Content Security Policy directive: "form-action 'self'"

Решение - дополнить конфиг:
```
vim config/config.php
```
добавить:
```
'overwriteprotocol' => 'https',
```

# Выполнение команд через консоль

## Отобразить список всех команд
```
docker exec -u 33 nextcloud php occ list
```

## Отобразить настройки LDAP
```
docker exec -u 33 nextcloud php occ ldap:show-config
```
