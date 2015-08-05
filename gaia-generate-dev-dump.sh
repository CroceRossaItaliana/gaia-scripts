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

    if [[ "$2" ]];then
        echo "(Password di root fornita come argomento)"
        mypassword="$2"
        
    else
        echo "Inserisci la password per root di MySQL: "
        read -s mypassword
        
    fi

    echo " Attendere..."

    # Genera il nome di un database temporaneo
    db="temp$RANDOM"

    echo "- Creazione database temporaneo ($db)..."
    echo "CREATE DATABASE $db" | MYSQL_PWD=$mypassword mysql -u root 

    echo "- Caricamento DUMP originale in memoria..."
    MYSQL_PWD=$mypassword mysql -u root $db < $1

    echo "- Oscuro i nomi..."
    echo "UPDATE anagrafica SET nome = CONCAT('Nome ', id)  WHERE admin = 0 OR admin IS NULL"  | MYSQL_PWD=$mypassword mysql -u root $db

    echo "- Oscuro i cognomi..."
    echo "UPDATE anagrafica SET cognome = CONCAT('Cognome ', id)  WHERE admin = 0 OR admin IS NULL"  | MYSQL_PWD=$mypassword mysql -u root $db

    echo "- Oscuro le password..."
    echo "UPDATE anagrafica SET password = '253903f72bbb236fe1cc72dd034b4e78061d9d57' WHERE admin = 0 OR admin IS NULL"  | MYSQL_PWD=$mypassword mysql -u root $db

    echo "- Oscuro i codici fiscali..."
    echo "UPDATE anagrafica SET codiceFiscale = CONCAT(LEFT(codiceFiscale, 10), 'X1234X') WHERE admin = 0 OR admin IS NULL"  | MYSQL_PWD=$mypassword  mysql -u root $db
    echo "UPDATE anagrafica SET codiceFiscale = CONCAT('ABCDED', RIGHT(codiceFiscale, 10)) WHERE admin = 0 OR admin IS NULL"  | MYSQL_PWD=$mypassword mysql -u root $db

    echo "- Oscuro le email..."
    echo "UPDATE anagrafica SET email = CONCAT('XXXXX', RIGHT(email, length(email)-5)) WHERE admin = 0 OR admin IS NULL"  | MYSQL_PWD=$mypassword mysql -u root $db
    
    echo "- Oscuro i telefoni..."
    echo "UPDATE dettagliPersona SET valore = CONCAT('XXXX', RIGHT(valore, length(valore)-4)) WHERE nome like '%cellulare%' OR nome like '%cellulareServizio%' "  | MYSQL_PWD=$mypassword mysql -u root $db

    echo "- Oscuro dettagli anagrafici..."
    echo "UPDATE dettagliPersona SET valore = CONCAT(nome, id) WHERE id NOT IN (SELECT id FROM anagrafica WHERE admin > 0) AND valore <> '' AND valore NOT REGEXP '[0-9]+';"  | MYSQL_PWD=$mypassword  mysql -u root $db

    echo "- Oscuro il sesso..."
    echo "UPDATE anagrafica SET sesso = 0  WHERE admin = 0 OR admin IS NULL"  | MYSQL_PWD=$mypassword mysql -u root $db
    
    echo "- Cancello la posta..."
    echo "DELETE FROM email"  | MYSQL_PWD=$mypassword mysql -u root $db
    echo "DELETE FROM email_allegati"  | MYSQL_PWD=$mypassword mysql -u root $db
    echo "DELETE FROM email_destinatari"  | MYSQL_PWD=$mypassword mysql -u root $db
    
    echo "- Cancello dati donazioni sangue..."
    echo "DELETE FROM donazioni"  | MYSQL_PWD=$mypassword mysql -u root $db
    echo "DELETE FROM donazioni_anagrafica"  | MYSQL_PWD=$mypassword mysql -u root $db
    echo "DELETE FROM donazioni_merito"  | MYSQL_PWD=$mypassword mysql -u root $db
    echo "DELETE FROM donazioni_personale"  | MYSQL_PWD=$mypassword mysql -u root $db
    echo "DELETE FROM donazioni_sedi"  | MYSQL_PWD=$mypassword mysql -u root $db

    echo "- Cancello le sessioni..."
    echo "DELETE FROM sessioni"  | MYSQL_PWD=$mypassword mysql -u root $db

    echo "- Cancello le sessioni (dettagli)..."
    echo "DELETE FROM datiSessione"  | MYSQL_PWD=$mypassword mysql -u root $db
    
    echo "- Cancello i file..."
    echo "DELETE FROM file"  | MYSQL_PWD=$mypassword mysql -u root $db
    
    echo "- Cancello gli avatar..."
    echo "DELETE FROM avatar"  | MYSQL_PWD=$mypassword mysql -u root $db
    
    echo "- Cancello gli allegati..."
    echo "DELETE FROM email_allegati"  | MYSQL_PWD=$mypassword mysql -u root $db

    echo "- Esportazione del file..."
    MYSQL_PWD=$mypassword mysqldump -u root $db > output.sql

    echo "- Compressione del dump..."
    bzip2 --best -f output.sql

    echo "- Cancello il database temporaneo ($db)..."
    echo "DROP DATABASE $db" | MYSQL_PWD=$mypassword mysql -u root $db

    echo " " 
    echo "Generato output.sql.gz"
    echo "Fine."

else

    echo "Uso: ./gaia-generate-dev-dump.sh <dump-originale.sql> [<mysql-root-password>]"

fi
