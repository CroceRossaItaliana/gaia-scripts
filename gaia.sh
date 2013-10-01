#!/bin/bash
#
# Script di installazione rapida di Gaia (sviluppo) per Ubuntu/Mint
#
# Copyright (C) 2013  Alfio Emanuele Fresta <alfio.emanuele.f@gmail.com>
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
#  This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
shopt -s expand_aliases

# Se e' la prima esecuzione crea .aliasgaia
if [ ! -f ~/.aliasgaia ];then
        echo "GAIALOCATION=/home/$USER/gaia" > ~/.aliasgaia
fi
        
source ~/.aliasgaia

if [[ "$1" = "install" ]];then

        clear
        echo "******** Installazione di Gaia (Ubuntu 13.04+/Mint) ********"
        echo " "
        echo "- Inserisci email di GitHub (es.: mario.rossi@gmail.com)"
        read email
        echo "- Inserisci il tuo nome completo (es.: Mario Rossi)"
        read nome

        clear
        echo "Installazione dei requisiti di Gaia (puo' richiedere molto tempo)..."
        echo " "
        sudo add-apt-repository --yes ppa:ondrej/php5
        sudo apt-get update
        sudo apt-get install --yes git wget build-essential sed unzip nano php5-cli php5-common php-pear php-mail mysql-server php5-dev php5-mysql redis-server
        sudo service mysql start

        clear
        echo "Installazione di REDIS (cache oggetti di Gaia)..."
        echo " "
        sudo pecl install http://pecl.php.net/get/redis-2.2.3.tgz
        sudo -- bash -c "echo 'extension=redis.so' >> /etc/php5/cli/php.ini"
        sudo -- bash -c "echo 'extension=redis.so' >> /etc/php5/apache2/php.ini"
        sudo -- bash -c "echo 'extension=redis.so' >> /etc/php5/fpm/php.ini"

        clear
        echo "Configurazione di GIT..."
        git config --global user.email $email
        git config --global user.name $nome

        clear
        echo "Configurazione"
        echo ""
        echo "- Dove vuoi installare gaia? (percorso assoluto) [$GAIALOCATION]"
        read location

        if [[ $location = '' ]];then
                location=$GAIALOCATION
                
        else
                location=${location%/}
        fi

        if [ ! -d $location ];then
                mkdir -p $location
        fi
        
        echo "GAIALOCATION=$gaialocation" > ~/.aliasgaia

        clear
        cd $location
        echo "Scaricamento di phpMyAdmin..."
        wget http://downloads.sourceforge.net/project/phpmyadmin/phpMyAdmin/4.0.5/phpMyAdmin-4.0.5-all-languages.zip
        unzip phpMyAdmin-4.0.5-all-languages.zip
        mv phpMyAdmin-4.0.5-all-languages/ pma
        rm phpMyAdmin-4.0.5-all-languages.zip
        echo "Creazione scorciatoia PMA..."
        #echo "alias pma='cd $location/pma; clear; echo \"phpMyAdmin (user: gaia) ===> http://localhost:8887/\"; echo " "; php -S localhost:8887'" >> ~/.bashrc
        echo "alias pma='cd $location/pma; clear; echo \"phpMyAdmin (user: gaia) ===> http://localhost:8887/\"; echo " "; php -S localhost:8887'" >> ~/.aliasgaia

        clear
        echo "Scaricamento dell'ultima versione di Gaia..."
        git clone https://github.com/CroceRossaCatania/gaia.git
        echo "Creazione scorciatoia Gaia..."
        #echo "alias gaia='cd $location/gaia; clear; echo \"APRI ===> http://localhost:8888/\"; php -S localhost:8888'" >> ~/.bashrc
        echo "alias gaia='cd $location/gaia; clear; echo \"APRI ===> http://localhost:8888/\"; php -S localhost:8888'" >> ~/.aliasgaia
        source ~/.bashrc

        clear
        echo "Installazione del database di Gaia..."
        cd $location/gaia
        echo "Inserisci la password di root di MySQL"
        read -s pmysql 
        echo "Creazione database 'gaia'..."
        echo "CREATE DATABASE gaia;" | mysql -u root --password="$pmysql"
        echo "Creazione utente 'gaia'..."
        echo "GRANT ALL ON gaia.* TO gaia@localhost IDENTIFIED BY '$pmysql';" | mysql -u root --password="$pmysql"
        echo "FLUSH PRIVILEGES;" | mysql -u root --password="$pmysql"
        echo "Importazione database..."
        cat core/conf/gaia.sql | mysql -u gaia --password="$pmysql" --database=gaia
        
        echo " "
        echo "Vuoi installare dei comitati di esempio? s/[n]"
        read -n 1 -s datiesempio
        if [[ "$datiesempio" = "s" ]];then
                # creazione primo comitato di esempio altrimenti è un casino!
                cat "INSERT INTO `gaia`.`nazionali` (`id`, `nome`, `geo`) VALUES ('1', 'Comitato Nazionale', GeomFromText('POINT(1 2)',0));" | mysql -u gaia --password="$pmysql" --database=gaia
                cat "INSERT INTO `gaia`.`regionali` (`id`, `nome`, `geo`, `nazionale`) VALUES ('1', 'Regionale prova', GeomFromText('POINT(1 2)',0), '1');" | mysql -u gaia --password="$pmysql" --database=gaia
                cat "INSERT INTO `gaia`.`provinciali` (`id`, `nome`, `geo`, `regionale`) VALUES ('1', 'provinciale di prova', GeomFromText('POINT(1 2)',0), '1');" | mysql -u gaia --password="$pmysql" --database=gaia
                cat "INSERT INTO `gaia`.`locali` (`id`, `nome`, `geo`, `provinciale`) VALUES ('1', 'locale di prova', GeomFromText('POINT(1 2)',0), '1');" | mysql -u gaia --password="$pmysql" --database=gaia
                cat "INSERT INTO `gaia`.`comitati` (`id`, `nome`, `colore`, `locale`, `geo`, `principale`) VALUES ('1', 'comitato locale di prova', NULL, '1', GeomFromText('POINT(1 2)',0), '1');" | mysql -u gaia --password="$pmysql" --database=gaia
        fi
        echo "Creazione configurazione..."
        cp core/conf/database.conf.php.sample core/conf/database.conf.php
        cp core/conf/smtp.conf.php.sample core/conf/smtp.conf.php
        cp core/conf/autopull.conf.php.sample core/conf/autopull.conf.php
        echo "Configurazione del database..."
        sed -i 's/DATABASE_NAME/gaia/g' core/conf/database.conf.php
        sed -i 's/DATABASE_USER/gaia/g' core/conf/database.conf.php
        sed -i "s/DATABASE_PASSWORD/$pmysql/g" core/conf/database.conf.php


        # Avvia il server per il setup su una porta diversa
        php -S localhost:8889 > /dev/null 2>&1 # Muto!
        clear
        echo "OK! Installazione di Gaia quasi completa"
        echo "Verra' ora avviato il setup di Gaia all'indirizzo"
        echo "==> http://localhost:8889/setup.php <=="
        echo " "
        echo "In futuro, per avviare Gaia, aprire un terminale e digitare:"
        echo "  gaia.sh start"
        echo " "
        echo "In futuro, per avviare phpMyAdmin, aprire un terminale e digitare:"
        echo "  gaia.sh startdb"
        echo " "
        echo "Avvio di Gaia (setup)... Premi INVIO quando sei pronto"
        read -n 1 -s
        sensible-browser "http://localhost:8889/setup.php" &

elif [[ "$1" = "uninstall" ]];then
        clear
        echo "rimuovo: git php5 mysql-server redis-server"
        echo "vuoi tenerli? [s]/n"
        read -n 1 -s tenerli
        if [[ "$tenerli" = "n" ]];then
                echo "ok li faccio fuori"
                sudo apt-get remove --yes git php5-cli php5-common php-pear php-mail mysql-server php5-dev php5-mysql redis-server
        else
                echo "ok ok li lascio non ti arrabbiare"
        fi
        echo "rimuovo il client di redis"
        sudo pecl uninstall redis
        echo "rimuovo phpmyadmin da dove lo avevi installato"
        rm -rf $GAIALOCATION/pma
        echo "rimuovo questa installazione di gaia"
        rm -rf $GAIALOCATION/gaia
                
        echo "rimuovo gli shortcut creati in bash.rc"
        sed -i '/gaia; clear; echo \"APRI ===>/d' ~/.bashrc
        sed -i '/pma; clear; echo \"APRI ===>/d' ~/.bashrc
        
        echo "Rimuovo il file .aliasgaia"
        rm ~/.aliasgaia
        
        echo "rimozione completata"
        echo "Contento? [s]/s"
        read -n 1 -s
        clear
        
elif [[ "$1" = "start" ]];then
        gaia &
        clear
        echo "Gaia avviato su http://localhost:8888/"
        echo "Aprire un browser? [s]/n"
        read -n 1 -s aprirebrowser
        if [[ "$aprirebrowser" != "n" ]];then
                sensible-browser localhost:8888 &
        fi
        
elif [[ "$1" = "startdb" ]];then
        gaia &
        pma &
        clear
        echo "Gaia        avviato su http://localhost:8888/"
        echo "phpMyAdmin  avviato su http://localhost:8887/"
        echo "Aprirli in un browser un browser? [s]/n"
        read -n 1 -s aprirebrowser
        if [[ "$aprirebrowser" != "n" ]];then
                sensible-browser localhost:8888 &
                sensible-browser localhost:8887 &
        fi
        
elif [[ "$1" = "stop" ]];then
        echo "Chiusura Gaia e PMA..."
        killall php
        
else
        echo "gaia.sh install | uninstall | start | startdb | stop"
        echo ""
        echo "install   installa gaia"
        echo "uninstall disinstalla gaia (non completo)"
        echo "start     Avvia gaia"
        echo "startdb   Avvia gaia ed apre phpmyadmin"
        echo "stop      Uccide tutti i server php (potenzialmente anche altri oltre gaia)"
        echo ""
fi
