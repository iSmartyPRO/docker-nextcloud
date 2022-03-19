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