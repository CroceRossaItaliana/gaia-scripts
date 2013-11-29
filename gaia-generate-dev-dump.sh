#!/bin/bash
#
# Generazione di un DUMP per lo sviluppo
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

if [[ "$1" ]];then

    echo "==== GAIA - Generatore di DUMP fittizzio ===="
    echo "Dump originale: $1"
    echo " "

    echo "Inserisci la password per root di MySQL: "
    read -s mypassword

    echo " Attendere..."

    # Genera il nome di un database temporaneo
    db="temp$RANDOM"

    echo "- Creazione database temporaneo ($db)..."
    echo "CREATE DATABASE $db" | mysql -u root --password="$mypassword"

    echo "- Caricamento DUMP originale in memoria..."
    mysql -u root --password="$mypassword" $db < $1

    echo "- Oscuro i nomi..."
    echo "UPDATE anagrafica SET nome = CONCAT('Nome ', id)  WHERE admin = 0 OR admin IS NULL"  | mysql -u root --password="$mypassword" $db

    echo "- Oscuro i cognomi..."
    echo "UPDATE anagrafica SET cognome = CONCAT('Cognome ', id)  WHERE admin = 0 OR admin IS NULL"  | mysql -u root --password="$mypassword" $db

    echo "- Oscuro le password..."
    echo "UPDATE anagrafica SET password = '253903f72bbb236fe1cc72dd034b4e78061d9d57' WHERE admin = 0 OR admin IS NULL"  | mysql -u root --password="$mypassword" $db

    echo "- Oscuro i codici fiscali..."
    echo "UPDATE anagrafica SET codiceFiscale = CONCAT(LEFT(codiceFiscale, 11), 'X123X') WHERE admin = 0 OR admin IS NULL"  | mysql -u root --password="$mypassword" $db
    echo "UPDATE anagrafica SET codiceFiscale = CONCAT('ABCDED', RIGHT(codiceFiscale, 10)) WHERE admin = 0 OR admin IS NULL"  | mysql -u root --password="$mypassword" $db

    echo "- Oscuro le email..."
    echo "UPDATE anagrafica SET email = CONCAT('XXX', RIGHT(email, length(email)-3)) WHERE admin = 0 OR admin IS NULL"  | mysql -u root --password="$mypassword" $db
    
    echo "- Oscuro i telefoni..."
    echo "UPDATE dettagliPersona SET valore = CONCAT('XXX', RIGHT(valore, length(valore)-3)) WHERE nome like '%cellulare%' OR nome like '%cellulareServizio%' "  | mysql -u root --password="$mypassword" $db

    echo "- Oscuro dettagli anagrafici..."
    echo "UPDATE dettagliPersona SET valore = CONCAT(nome, id) WHERE id NOT IN (SELECT id FROM anagrafica WHERE admin > 0) AND valore <> '' AND valore NOT REGEXP '[0-9]+';"  | mysql -u root --password="$mypassword" $db

    echo "- Oscuro il sesso..."
    echo "UPDATE anagrafica SET sesso = 0  WHERE admin = 0 OR admin IS NULL"  | mysql -u root --password="$mypassword" $db

    echo "- Cancello le sessioni..."
    echo "DELETE FROM sessioni"  | mysql -u root --password="$mypassword" $db

    echo "- Cancello le sessioni (dettagli)..."
    echo "DELETE FROM datiSessione"  | mysql -u root --password="$mypassword" $db
    
    echo "- Cancello i file..."
    echo "DELETE FROM file"  | mysql -u root --password="$mypassword" $db
    
    echo "- Cancello gli avatar..."
    echo "DELETE FROM avatar"  | mysql -u root --password="$mypassword" $db

    echo "- Esportazione del file..."
    mysqldump -u root --password="$mypassword" $db > output.sql

    echo "- Compressione del dump..."
    gzip -f output.sql

    echo "- Cancello il database temporaneo ($db)..."
    echo "DROP DATABASE $db" | mysql -u root --password="$mypassword"

    echo " " 
    echo "Generato output.sql.gz"
    echo "Fine."

else

    echo "Uso: ./gaia-generate-dev-dump.sh <dump-originale.sql>"

fi
