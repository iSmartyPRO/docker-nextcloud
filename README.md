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

## Дополнение
После установки, необходимо создать пользователя с правами администратора и далее донастроить под нужды компании.

## Включение поддержки SMB
для того чтобы включить поддержку SMB необходимо установить клиент:

```
docker exec -ti nextcloud bash
apt update
apt install smbclient
```

## Решение проблемы - не авторизуется сразу - приходиться вводить данные авторизации, потом обновлять страницу
в консоле выдается ошибка: because it violates the following Content Security Policy directive: "form-action 'self'"

Решение - дополнить конфиг:
```
vim files/config/config.php
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
