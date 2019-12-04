# INSTALL

## CentOS 7

Подключаем EPEL.

    yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

Устанавливаем rakudo, rakudo-zef.

    yum install rakudo rakudo-zef
 
Устанавливаем утилиты, необходимые для загрузки архивов по FTP, шифрования, шейпинга и пногопоточного сжатия.

    yum install git ncftp openssl pigz pv

Устанавливаем bkp.

    cd /var/tmp
    git clone git://github.com/kopytov/bkp.git
    zef --force-install install bkp
    ln -s /usr/lib64/perl6/site/bin/bkp /usr/local/bin/bkp
    rm -rf bkp

Пишем конфиг (пример).

    mkdir -m 700 /usr/local/etc/bkp
    mkdir -m 700 /var/backups
    cat >/usr/local/etc/bkp/sysconf.yml <<EOF
    src:
      class: tar
      cwd: /
      files:
      - etc
      - usr/local/etc
    compress:
      class: pigz
    dst:
      class: local
      dir: /var/backups
      plan:
        y: 2
        m: 6
        w: 3
        d: 6
    EOF

Создаём задание на резервное копирование.

    cat >/etc/cron.d/bkp <<EOF
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
    15 1 * * *  root    bkp /usr/local/etc/bkp/*.yml
    EOF

Готово!
