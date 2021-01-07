!/usr/bin/env bash

mysqld --initialize-insecure

echo "Creating new user ${MYSQL_USER}..."
mysql -uroot -e "CREATE USER '${MYSQL_USER}'@'${MYSQL_ROOT_HOST}' IDENTIFIED BY '${MYSQL_PASSWORD}';"
echo "Granting privileges..."
mysql -uroot -e "GRANT ALL PRIVILEGES ON *.* TO '${MYSQL_USER}'@'${MYSQL_ROOT_HOST}';"
mysql -uroot -e "FLUSH PRIVILEGES;"
echo "All done."

chown -R mysql.mysql /var/lib/mysql
chmod -R 700 /var/lib/mysql