# synapse_adm.sh
Simple shellscript for create/managing users/rooms and database shrinking your matrix synapse server

#### Functions:
```

 __________________________________________________________
 ___  _   _  _ __    __ _  _ __   ___  ___        __ _  __| | _ __ ___
/ __|| | | || '_ \  / _' || '_ \ / __|/ _ \      / _' |/ _' || '_ \ _ \
\__ \| |_| || | | || (_| || |_) |\__ \  __/     | (_| | (_| || | | | | |
|___/ \__, ||_| |_| \__,_|| .__/ |___/\___| _____\__,_|\__,_||_| |_| |_|
      |___/               | |______________|_0_2a|

       Create / Modify Users & Cleanup your Database - (C) 2023 suuhm:

Usage: ./synapse_adm.sh [OPTION]

        --list-users                  List all Users on Server
        --create-user                 Create a new User on Server
        --deactivate-user             Deactivate a User on Server
        --passwd-reset                Reset User Password
        --list-rooms                  List all Rooms on Server
        --cleanup-rooms               Make a Garbage Colletion of Rooms on Databse
        --delete-room <'ROOM:ID'>     Delete a specified Room on Server
        --debloat-database <-s|-p>    Make a Debloating of your Databse (-s=Sqlite3 , -p=Postgresql)
```

## How to run the script:
Simply run this on your serial/ssh console: 
```bash
sudo su --
wget https://raw.githubusercontent.com/suuhm/synapse_adm.sh/main/synapse_adm.sh 
chmod +x synapse_adm.sh 
./synapse_adm.sh --help
```

Alternatively you can just clone the project or copy/paste the file to your ssh console

## Configure these necessary lines in synapse_adm.sh to run the script

```bash
# Open with vi / nane / etc
#
# Maininfos
#
SRV_DOM="matrix.your-server.com"
MTRXCONF="/etc/matrix-synapse/homeserver.yaml"

#
# Databseinfos:
#
DBSYSTEM="Sqlite3"
#DBSYSTEM="Postgresql"
SQDB="/var/lib/matrix-synapse/homeserver.db"
# POSTGRESQL:
DB_HOST="127.0.0.1"
DB_USER="user"
DB_PASSWD="secr3tpasswd"
PSQDB="synapse_dbname"

#
# Mail / Loginfos / etc
#
MAILCR=NO
POSTMASTER="mail@mailserv.com"

```

<br>
<hr>

# If you have some questions and feature wishes write an issue

#### Verson: 0.2a
#### -------------
#### Attention / This is a alpha script I cannt give any warranty for some damage!

<hr>
