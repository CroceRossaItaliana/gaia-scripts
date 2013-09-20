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
sudo apt-get install --yes git wget sed unzip nano php5-cli php5-common php-pear php-mail mysql-server php5-dev php5-mysql redis-server
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
cd ~
echo "Scaricamento di phpMyAdmin..."
wget http://downloads.sourceforge.net/project/phpmyadmin/phpMyAdmin/4.0.5/phpMyAdmin-4.0.5-all-languages.zip
unzip phpMyAdmin-4.0.5-all-languages.zip
mv phpMyAdmin-4.0.5-all-languages/ pma
echo "Creazione scorciatoia PMA..."
echo "alias pma='cd ~/pma; clear; echo \"phpMyAdmin (user: gaia) ===> http://localhost:8887/\"; echo " "; php -S localhost:8887'" >> ~/.bashrc

clear
echo "Scaricamento dell'ultima versione di Gaia..."
git clone https://github.com/CroceRossaCatania/gaia.git
echo "Creazione scorciatoia Gaia..."
echo "alias gaia='cd ~/gaia; clear; echo \"APRI ===> http://localhost:8888/\"; php -S localhost:8888'" >> ~/.bashrc

clear
echo "Installazione del database di Gaia..."
cd ~/gaia
echo "Inserisci la password di root di MySQL"
read pmysql 
echo "Creazione database 'gaia'..."
echo "CREATE DATABASE gaia;" | mysql -u root --password=$pmysql
echo "Creazione utente 'gaia'..."
echo "GRANT ALL ON gaia.* TO gaia@localhost IDENTIFIED BY '$pmysql';" | mysql -u root --password=$pmysql
echo "FLUSH PRIVILEGES;" | mysql -u root --password=$pmysql
echo "Importazione database..."
cat core/conf/gaia.sql | mysql -u gaia --password=$pmysql --database=gaia
echo "Creazione configurazione..."
cp core/conf/database.conf.php.sample core/conf/database.conf.php
cp core/conf/smtp.conf.php.sample core/conf/smtp.conf.php
cp core/conf/autopull.conf.php.sample core/conf/autopull.conf.php
echo "Configurazione del database..."
sed -i 's/DATABASE_NAME/gaia/g' core/conf/database.conf.php
sed -i 's/DATABASE_USER/gaia/g' core/conf/database.conf.php
sed -i "s/DATABASE_PASSWORD/$pmysql/g" core/conf/database.conf.php


clear
echo "OK! Installazione di Gaia quasi completa"
echo "==> http://localhost:8888/setup.php <== per terminare"
echo " "
echo "In futuro, per avviare Gaia, aprire un terminale e digitare:"
echo "  gaia"
echo " "
echo "In futuro, per avviare phpMyAdmin, aprire un terminale e digitare:"
echo "  pma"
echo " "
echo "Avvio di Gaia..."
php -S localhost:8888

