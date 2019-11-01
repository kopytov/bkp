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

Помимо этого есть возможность формировать список источников динамически, указав скрипт и шаблон для рендера. Например, этот скрипт содержит источники для бекапа всех баз данных MySQL, каждую в отдельный дамп:

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

### class: mysql

    src:
      class: mysql
      dbs:
      - db1
      - db2

Описывает в качестве источника данных базы данных MySQL, которые бекапятся через mysqldump. Обязательных опций нет.

Опциональные атрибуты:
* `dbs` — список баз данных, которые будут переданы в mysqldump. Если список баз данных не задать, то mysqldump будет бекапить все базы данных (т. е. будет запущен с опцией `--all-databases`). Это не всегда удобно, т. к. вытащить одну единственную базу данных из такого дампа сложно. Если вы хотите бекапить базы данных в отдельные дампы, то нужно задавать их отдельными источниками:

        src:
          db1:
            class: mysql
            dbs: db1
          db2:
            class: mysql
            dbs: db2

    Либо сделать как в примере с динамическим списком источников данных.

* `cmd` — даёт возможность переопределить команду и опции `mysqldump`: По умолчанию имеет вид: `[ mysqldump, -ER, --single-transaction ]`. Можно сделать, например: `[ docker, exec, -u, root, mysql, mysqldump, -ER, --single-transaction ]`. Важно, чтобы вывод команды попадал в STDOUT для дальнейшей обработки.

## Продолжение следует...
