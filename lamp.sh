#!/bin/bash
function main {
    LAMP_install
}
function install_apache2 {
    # echo "******************************  Installing apache 2 ********************************"
    echo -ne '|#########-------------------------------|(15%)\r' && sleep 0.5
    apt-get install apache2 -y > /dev/null 2>&1
    [[ $? == 0 ]] && echo -ne '|################------------------------|(40%)\r' || return 1
    apache_status=$(systemctl status apache2 | grep Active: | awk '{print $2}')
    if [[ $apache_status == "active" ]]; then
        apt-get install curl > /dev/null 2>&1 && sleep 0.5 && echo -ne '|####################--------------------|(45%)\r'
        apache_status_code=`curl -o /dev/null --silent --head --write-out '%{http_code}\n' http://localhost/`
        if [[ $apache_status_code != 200 ]]; then
            echo -ne '|################------------------------|(40%)\r' && sleep 0.5 && return 1
        else
            # echo "************************** Apache 2 installed properly ************************" && sleep 0.5 && exit 0
            return 0
        fi
    else
        return 1
    fi
}
function purge_apache2 {
    apt autoremove > /dev/null 2>&1 && echo -ne '|############----------------------------|(30%)\r'
    sleep 0.5 && sudo apt remove apache2 -y > /dev/null 2>&1 && echo -ne '|####------------------------------------|(10%)\r' && sleep 0.5 && sudo apt-get purge apache2 apache2-utils apache2-bin apache2.2-common apache2-data -y > /dev/null 2>&1
    echo -ne '|----------------------------------------|(0%)\r' && sleep 0.5
    echo "Apache deleted because not installed properly check it manually..."
    exit 0
}
function install_mariaDB {
    apt-get install mariadb-server -y > /dev/null 2>&1 
    [[ $? == 0 ]] && echo -ne '|##########################--------------|(65%)\r' && sleep 0.5 || return 1
    mariadb_status=$(systemctl status mariadb | grep Active: | awk '{print $2}')
    if [[ $mariadb_status == "active" ]]; then
        return 0
    else
        return 1
    fi 
}
function purge_mariadb {
    echo -ne '|########################----------------|(60%)\r' && sleep 0.5
    apt-get purge mariadb-server libmariadb3:amd64 mariadb-client-10.3 mariadb-client-core-10.3 mariadb-common mariadb-server-10.3 mariadb-server-core-10.3 -y > /dev/null 2>&1 
    [[ $? == 0 ]] && echo -ne '|####################--------------------|(50%)\r' && sleep 0.5  || return 1
}
function purge_php {
    echo -ne '|####################################----|(90%)\r' && sleep 0.5
    apt-get purge php* -y > dev/null 2>&1
}
function install_php {
    echo -ne '|##############################----------|(75%)\r' && sleep 0.5
    apt-get install php libapache2-mod-php php-mysql -y > /dev/null 2>&1 
    echo -ne '|################################--------|(85%)\r' && sleep 0.5
    systemctl reload apache2 > /dev/null 2>&1 
    echo -ne '|####################################----|(95%)\r' && sleep 0.5
    # systemctl status apache2 > /dev/null 2>&1 
    touch /var/www/html/info.php && echo '<?php phpinfo(); ?>' > /var/www/html/info.php
    echo -ne '|######################################--|(98%)\r' && sleep 0.5
    php_status_code=$(curl -o /dev/null --silent --head --write-out '%{http_code}\n' http://localhost/info.php)
    [[ $php_status_code == 200 ]] && rm /var/www/html/info.php && echo -ne '|#######################################-|(99%)\r' && sleep 0.5 && return 0 || return 1
}
function LAMP_install {
    echo -ne '|----------------------------------------|(0%)\r'
    apt-get update > /dev/null 2>&1
    echo -ne '|####------------------------------------|(10%)\r'
    sleep 0.5
    # apache_check=($(dpkg --get-selections | grep apache))
    # if [[ ${apache_check[0]} == "apache2" && ${apache_check[1]} == "install" ]]; then
    #     echo -ne '|########            |(50%)\r' && sleep 0.5
    #     install_mariaDB && echo -ne '|##############      |(70%)\r' && sleep 0.5
    # else
    install_apache2
    [[ $? == 0 ]] && sleep 0.5 && echo -ne '|####################--------------------|(50%)\r' && sleep 0.5 || purge_apache2
    install_mariaDB
    [[ $? == 0 ]] && echo -ne '|############################------------|(70%)\r' && sleep 0.5 || { purge_mariadb && purge_apache2; }
    install_php
    [[ $? == 0 ]] && echo -ne '|########################################|(100%)\r' && sleep 0.5 && echo "APACHE2 , MARIADB and PHP installed succesfully on this machine" || { purge_php && purge_mariadb && purge_apache2; }
}
main

