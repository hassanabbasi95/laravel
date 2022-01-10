#!/bin/bash

read -p "Enter the application name: " appname
path="/var/www/"
while [[ "$appname" == `echo "$appname" | grep "^([a-zA-Z0-9-])$"` || "$appname" == `echo $appname | grep "//"` || "$appname" == [/]* || "$appname" != *[!@#\$.%^\&*()_+]* || "$appname" == [.]* || -z "$appname" ]]; do
        read -p "The provided value is not correct. Please re-enter the application name: " appname
done
list=($(ls -l "$path" | sed 1d | awk '{print $9}' | grep ^$appname$ ))
while [[ ! -z "$list" ]];
do
       read -p "Application Already Exist Please Enter Application Name Again:" appname
while [[ "$appname" == `echo "$appname" | grep "^([a-zA-Z0-9-])$"` || "$appname" == `echo $appname | grep "//"` || "$appname" == [/]* || "$appname" != *[!@#\$.%^\&*()_+]* || "$appname" == [.]* || -z "$appname" ]]; do
        read -p "The provided value is not correct. Please re-enter the application name: " appname
done
       list=($(ls -l "$path" | sed 1d | awk '{print $9}'| grep ^$appname$ ))
done

read -p "Please Enter Database Name:" dbname
while [[ "$dbname" == `echo "$dbname" | grep "^([a-zA-Z0-9-])$"` || "$dbname" == `echo $dbname | grep "//"` || "$dbname" == [/]* || "$dbname" != *[!@#\$.%^\&*()_+]* || "$dbname" == [.]* || -z "$dbname" ]]; do
        read -p "The provided value is not correct. Please re-enter the database name: " dbname
done
       DBEXISTS=$(mysql --batch --skip-column-names -e "SHOW DATABASES LIKE '"$dbname"';" | grep "$dbname" > /dev/null; echo "$?")
if [ $DBEXISTS -eq 0 ];then
    read -p "A database with the name $dbname already exists. Please re-enter any other name: " dbname
else
        while [[ "$dbname" == `echo "$dbname" | grep "^([a-zA-Z0-9-])$"` || "$dbname" == `echo $dbname | grep "//"` || "$dbname" == [/]* || "$dbname" != *[!@#\$.%^\&*()_+]* || "$dbname" == [.]* || -z "$dbname" ]]; do
        read -p "The provided value is not correct. Please re-enter the database name: " dbname
done

fi

echo "Database User: " && read -e dbuser && echo "Database Password: " && read -s dbpass && mysql -uroot -e "create database $dbname" && mysql -uroot -e "GRANT ALL ON $dbname.* TO '$dbuser'@'localhost' IDENTIFIED BY '$dbpass'" && mysql -uroot -e "FLUSH PRIVILEGES"

curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer && chmod +x /usr/local/bin/composer && cd /var/www && apt-get install git -y && git clone https://github.com/laravel/laravel.git && mv laravel $appname && cd /var/www/$appname && composer install && chown -R www-data.www-data /var/www/$appname && chmod -R 755 /var/www/$appname && chmod -R 777 /var/www/$appname/storage && cp .env.example .env && php artisan key:generate && sed -i "s|http://localhost|http://$appname|g" .env && sed -i "s/DB_DATABASE=laravel/DB_DATABASE=$dbname/g" .env && sed -i "s/DB_USERNAME=laravel/DB_USERNAME=$dbuser/g" .env && sed -i "s/secret_password/$dbpass/g" .env && touch /etc/apache2/sites-available/$appname.com.conf && echo -e "<VirtualHost *:80>
        ServerName $appname.com

        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/$appname/public

        <Directory />
                Options FollowSymLinks
                AllowOverride None
        </Directory>
        <Directory /var/www/$appname>
                AllowOverride All
        </Directory>

        ErrorLog ${APACHE_LOG_DIR}/$appname-error.log
        CustomLog ${APACHE_LOG_DIR}/$appname-access.log combined
</VirtualHost>" >> /etc/apache2/sites-available/$appname.com.conf
a2enmod rewrite && a2ensite $appname.com.conf && systemctl restart apache2

