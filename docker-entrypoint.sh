#!/bin/bash

set -e

# generating secrets
BENNO_SHARED_SECRET=$(cat /dev/urandom | tr -dc 'A-Z0-9' | fold -w 32 | head -n 1)
BENNO_ADMIN_PASSWORD=$(cat /dev/urandom | tr -dc 'A-Z0-9' | fold -w 12 | head -n 1)

echo "Benno's SHARED_SECRET: $BENNO_SHARED_SECRET"
echo "Benno's admin password: $BENNO_ADMIN_PASSWORD"

# set secret
sed -ri -e "s/^SHARED_SECRET =.*/SHARED_SECRET = ${BENNO_SHARED_SECRET}/g" /etc/benno-web/benno.conf
sed -ri -e "s/^    <sharedSecret>.*<\/sharedSecret>.*/    <sharedSecret>${BENNO_SHARED_SECRET}<\/sharedSecret>/g" /etc/benno/benno.xml

# set default admin pasword
benno-useradmin -c admin -p $BENNO_ADMIN_PASSWORD

# set owner and rights of volumes
chown -R benno:benno /var/log/benno && chmod 770 /var/log/benno
chown -R root:adm /var/log/apache2 && chmod 750 /var/log/apache2
chown -R benno:benno /srv/benno/archive /srv/benno/inbox
chmod 755 /srv/benno/archive
chmod 770 /srv/benno/inbox

# starting benno services
/etc/init.d/benno-rest restart &>/dev/null
/etc/init.d/benno-archive start &>/dev/null
/etc/init.d/benno-smtp start &>/dev/null

rm -Rf /var/run/apache2

/etc/init.d/apache2 start &>/dev/null

# show logs on default console
exec /usr/bin/tail -f /var/log/benno/*.log /var/log/apache2/*.log
