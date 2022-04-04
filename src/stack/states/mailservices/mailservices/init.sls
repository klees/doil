# salt 'doil.postfix' state.highstate saltenv=mailservices
{% set cpu = salt['grains.get']('num_cpus', '4') %}
{% set ram = salt['grains.get']('mem_total', '4096') %}
{% set doil_host_system = salt['grains.get']('doil_host_system', 'linux') %}

mailservice_packages:
  pkg.installed:
    - pkgs:
      - apache2
      - mariadb-server
      - python3-mysqldb
      - postfix
      - dovecot-core
      - dovecot-imapd
      - roundcube
      - libapache2-mod-php7.4
      - php7.4-curl
      - php7.4-gd
      - php7.4-json
      - php7.4-mysql
      - php7.4-readline
      - php7.4-xsl
      - php7.4-cli
      - php7.4-zip
      - php7.4-mbstring
      - php7.4-soap
      - php7.4-bcmath
      - php7.4-imap
      - php7.4-xmlrpc

/etc/mysql/mariadb.conf.d/50-server.cnf:
  file:
    - managed
    - source: salt://mailservices/mysql-my.cnf
    - template: jinja
    - context:
      cpu: {{ cpu }}
      ram: {{ ram }}

{% if salt['grains.get']('doil_host_system', 'linux') == 'linux' %}
/etc/mysql/:
  file.directory:
    - user: root
    - group: root
    - recurse:
      - user
      - group

/var/lib/mysql/:
  file.directory:
    - user: mysql
    - group: mysql
    - recurse:
      - user
      - group
{% endif %}

a2_enable_php:
  module.run:
    - name: apache.a2enmod
    - mod: php7.4

/etc/mailname:
  file.managed:
    - source: salt://mailservices/mailname

/etc/postfix/main.cf:
  file.managed:
    - source: salt://mailservices/postfix-main.cf

/etc/dovecot/conf.d/10-mail.conf:
  file.managed:
    - source: salt://mailservices/dovecot-10-mail.conf

/etc/apache2/conf-enabled/roundcube.conf:
  file.managed:
    - source: salt://mailservices/roundcube.conf

/etc/roundcube/debian-db.php:
  file.managed:
    - source: salt://mailservices/roundcube-debian-db.php

/etc/supervisor/conf.d/apache2.conf:
  file.managed:
    - source: salt://mailservices/sv-apache.conf

/etc/supervisor/conf.d/mysql.conf:
  file.managed:
    - source: salt://mailservices/sv-mysql.conf

/etc/supervisor/conf.d/postfix.conf:
  file.managed:
    - source: salt://mailservices/sv-postfix.conf

/etc/supervisor/conf.d/dovecot.conf:
  file.managed:
    - source: salt://mailservices/sv-dovecot.conf

apache_supervisor_signal:
  supervisord.running:
    - name: apache2
    - watch:
      - file: /etc/supervisor/conf.d/apache2.conf

mysql_supervisor_signal:
  supervisord.running:
    - name: mysqld
    - watch:
      - file: /etc/supervisor/conf.d/mysql.conf

postfix_supervisor_signal:
  supervisord.running:
    - name: postfix
    - watch:
      - file: /etc/supervisor/conf.d/postfix.conf

dovecot_supervisor_signal:
  supervisord.running:
    - name: dovecot
    - watch:
      - file: /etc/supervisor/conf.d/dovecot.conf

mysql_adduser:
  mysql_user.present:
    - name: roundcube
    - host: 'localhost'
    - password: roundcube

mysql_grant:
  mysql_grants.present:
    - grant: all privileges
    - user: roundcube
    - database: '*.*'
    - grant_option: true

mysql_database:
  mysql_database.present:
    - name: roundcube

init-www-data:
  cmd.run:
    - name: touch /var/mail/www-data && mkdir -p /var/www/mail && chown -R www-data:mail /var/mail/www-data && chown -R www-data:mail /var/www/mail

www-data:
  user.present:
    - name: www-data
    - password: $6$xUv8xrV06vQ5DexD$PL.aUE6zesb9d6qBB6FnJtli6jIJ2Ud00JlnLcW0G4p2nwgwX7lryvFb1RiFEMIc22OwQ7f9LnplchpaUBRB51

install-roundcube:
  cmd.run:
    - name: mysql roundcube < /usr/share/roundcube/SQL/mysql.initial.sql