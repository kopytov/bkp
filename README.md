# Bkp

Bkp — система резервного копирования для всего на свете с ротацией по заданному плану. Процесс резервного копирования запускается скриптом bkp с передачей ему списка конфигов:

    # добавьте в крон
    bkp /etc/opt/bkp/sysconf.yml /etc/opt/bkp/www.yml /etc/opt/bkp/mysql.yml

Конфигурационный файл состоит из двух основных секций: `src` и `dst` и трёх необязательных: `compress`, `crypt` и `shape`. Пример конфигурационного файла, осуществляющего резервное копирование содержимого директории /var/www/htdocs и MySQL базы данных wordpress на FTP-сервер ftp.bkp.server.com с хранением 6-х ежемесячных копий, 3-х еженедельных и 6-ти ежедневных:

    src:
      files:
        class: tar
        cwd: /var/www
        files:
          htdocs
      database:
        class: mysql
        dbs: wordpress
    compress:
      class: gzip
    dst:
      class: ftp
      hostname: ftp.bkp.server.com
      username: bkpuser
      password: bkpsecret
      path: /backups
      plan:
        m: 6
        w: 3
        d: 6

Файлы на сервер буду загружаться под именами: files-YYYY-MM-DD-P.tar.gz и database-YYYY-MM-DD-P.sql.gz (где P — код периода: m, w, d).

## src

Секция src описывает источники данных. Источник данных может быть один:

    src:
      class: tar
      cwd: /var/www
      files:
        htdocs

Или несколько:

    src:
      site:
        class: tar
        cwd: /var/www
        files:
          htdocs
      database:
        class: mysql
        dbs: wordpress

Помимо этого есть возможно формировать список источников динамически, указав скрипт и шаблон для рендера. Например, этот скрипт содержит источника для бекапа всех баз данных MySQL, каждую в отдельный дамп:

    src:
      script: mysql -se 'SHOW DATABASES'
        | egrep -v '^(Database|(information|performance)_schema)$'
      template: |
        mysql-{{ item }}:
          class: mysql
          dbs: {{ item }}

Каждый источник должен содержать атрибут `class` и дополнительные атрибуты, свойственные каждому конкретному классу.

### class: tar

    src:
      class: tar
      cwd: /var/www
      files:
      - site1.com
      - site2.com
      exclude:
      - site1.com/cache

Описывает в качестве источника данных локальные файлы, которые передаются в команду tar. Обязательные опции:
* `cwd` — директория, в которой запускается команда tar;
* `files` — список файлов и директорий, передаваемых в команду tar.

Опциональные атрибуты:
* `exclude` — список файлов и директорий, которые нужно исключить из архива.
* `cmd` — команда tar с опциями в виде списка, которые можно переопределить. По умолчанию: `[ tar, --warning=none, --numeric-owner, -cf, - ]`. Если будете переопределять, убедитесь, что в итоге поток вывода будет попадать в STDOUT.

## Продолжение следует...
