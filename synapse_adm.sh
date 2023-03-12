#!/bin/bash

# synapse_adm.sh
#
# Verson: 0.2a
# -------------
# Attention / This is a alpha script I cannt give any warranty for some damage!
#
# Create / Modify Users & Cleanup your Database for matrix_synapse - (C) 2023 suuhm:

# name TEXT, password_hash TEXT, creation_ts BIGINT, admin SMALLINT DEFAULT 0 NOT NULL,
# upgrade_ts BIGINT, is_guest
# SMALLINT DEFAULT 0 NOT NULL, appservice_id TEXT,
# consent_version TEXT, consent_server_notice_sent TEXT, user_type TEXT
# DEFAULT NULL, deactivated SMALLINT DEFAULT 0 NOT NULL, shadow_banned BOOLEAN, UNIQUE(name)

# SQLITE3 STUFF:

# Show Tables: .tables
# Quit: .quit
# Show Tableinfo: .schema users
#
# sqlite3 /var/lib/matrix-synapse/homeserver.db 'select ip,user_agent from user_ips where user_id LIKE "%tester%"'

# Debugging:
#set -x
set -e

################################################
########## C O N F I G U R A T I O N ###########
################################################
########### EDIT THESE LINES FIRST! ############
################################################

#
# Maininfos
#
SRV_DOM="matrix.your-server.com"
MTRXCONF="/etc/matrix-synapse/homeserver.yaml"
#USER=$1
#Joined local members
JLM=0
ROOMLIMIT=400
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
#DTIME=$(date +"%s" -d '5 minutes ago')
DTIME=$(date +"%s" -d '5 years ago')
#
MAILCR=NO
SUBJ="Synapse_adm Cron - $(hostname -f)";
POSTMASTER="mail@mailserv.com"
SUCC="NONE"
LOGFILE=/var/log/matrix-synapse/synapse_adm.log

################################################
################# END EDIT #####################
################################################

clear; echo -e ""
echo -e " __________________________________________________________             "
echo -e " ___  _   _  _ __    __ _  _ __   ___  ___        __ _  __| | _ __ ___  "
echo -e "/ __|| | | || '_ \  / _' || '_ \ / __|/ _ \      / _' |/ _' || '_ \ _ \ "
echo -e "\__ \| |_| || | | || (_| || |_) |\__ \  __/     | (_| | (_| || | | | | |"
echo -e "|___/ \__, ||_| |_| \__,_|| .__/ |___/\___| _____\__,_|\__,_||_| |_| |_|"
echo -e "      |___/               | |______________|_0_2a|                      "
echo -e ""
echo -e "       Create / Modify Users & Cleanup your Database - (C) 2023 suuhm:\n"

# Check for dirs exist
[[ -d $(dirname ${LOGFILE}) ]] || mkdir -p $(dirname ${LOGFILE})
# pre-cleanup
#echool "Remove temporary files..."

echool() {
    echo -e "\n$(date +%c) :: $1" | tee -a ${LOGFILE}
}

#Postgresqllite3 runner
psql_run() {
    echool "Using $DBSYSTEM as Databasesystem"
    
    if [ $DBSYSTEM == "Postgresql" ]; then
        export PGPASSWORD=$DB_PASSWD
        psql -U $DB_USER -d $PSQDB -c "$1"
    elif [ $DBSYSTEM == "Sqlite3" ]; then
        sqlite3 $SQDB "$1"
    else
        echool "Error wrong, Databasesystem selected!, exit"
        exit 1
    fi
}

_help() {
    echo -e "Usage: $0 [OPTION]\n\n" \
             "\t--list-users                  List all Users on Server\n" \
             "\t--create-user                 Create a new User on Server\n" \
             "\t--deactivate-user             Deactivate a User on Server\n" \
             "\t--passwd-reset                Reset User Password\n" \
             "\t--list-rooms                  List all Rooms on Server\n" \
             "\t--cleanup-rooms               Make a Garbage Colletion of Rooms on Databse\n" \
             "\t--delete-room <'ROOM:ID'>     Delete a specified Room on Server\n" \
             "\t--debloat-database <-s|-p>    Make a Debloating of your Databse (-s=Sqlite3 , -p=Postgresql)\n"
}

_mailcron() {
    if [ "${MAILCR}" = "YES" ]; then
        echool "Sending successful."
        cat $LOGFILE | mail -s "${SUJET} : ${RESULTAT}" ${POSTMASTER}
        [ "${SUCC}" = "DONE" ] && exit 0 || exit 1
    fi
}

_get_adm_token() {
    #check for ADM token already in Ram..
    if [ -f /tmp/madm_token ]; then
        ADM_TOKEN=$(cat /tmp/madm_token)
        echool "Found token: ($ADM_TOKEN) continue..."; return
    fi
    read -p "Get admin: " ADM
    read -sp "Password: " PASS
    #Use SSL Local request only with -k Flag in curl
    #ADM_TOKEN=$(curl -XPOST -d '{"type":"m.login.password", "user":"$ADM", "password":"$PASS"}' "https://$SRV_DOM/_matrix/client/r0/login")
    ACFULL=$(curl -s -XPOST -d '{"type":"m.login.password", "user":"'"$ADM"'", "password":"'"$PASS"'"}' "http://127.0.0.1:8008/_matrix/client/r0/login")
    export ADM_TOKEN=$(echo $ACFULL | cut -d "\"" -f8)
    #Write token to userfile and set rw,only:
    echo $ADM_TOKEN > /tmp/madm_token && chmod 600 /tmp/madm_token
    if [ "$1" == "--get-admtoken" ]; then
        echo -e "\n------\nToken: $ADM_TOKEN\n------\n"
    fi
    if echo "$ADM_TOKEN" | grep -q "Invalid" ; then
        echo -e "\n\a[!!] Error ($ADM_TOKEN). Now ending..."
        rm -f /tmp/madm_token; unset $ADM_TOKEN ; exit 1;
    else
        echool "Login successful, continue.."; echo; sleep 2
    fi
}

_create_user() {
    echool "[+] Create new Matrix user on Server\n"
    register_new_matrix_user -c $MTRXCONF http://localhost:8008
}

_reset_password() {
    read -p "Which user? " USER
    echool "Set new User and new hash..."
    HPW=$(hash_password -c $MTRXCONF)
    echo "Setup ($SRV_DOM) new sqlite pw..."

    psql_run "UPDATE users SET password_hash='$HPW' WHERE name LIKE '@$USER%';"
    
    sleep 2
    echool "\aDone!\n"
    sleep 2
    echo; echo "-----------------------------------------------"
    echo "Show users:"
    echo

    psql_run 'SELECT * FROM users;'
}

_deactivate_user() {
    _get_adm_token
    read -p "Which user? " USER
    echo
    echool "Using token: $ADM_TOKEN on Server: $SRV_DOM"
    #OLD VERISON HEADER: curl -s -XPOST -H "Authorization: Bearer "'"$ADM_TOKEN"'""
    curl -s -XPOST -H "Authorization: Bearer $ADM_TOKEN" -H "Content-Type: application/json" \
                   -d '{"erase":true}' \
                   "http://127.0.0.1:8008//_matrix/client/r0/admin/deactivate/@$USER:$SRV_DOM"
}

_list_rooms() {
    _get_adm_token
    curl -s -XGET -H "Authorization: Bearer $ADM_TOKEN" "http://127.0.0.1:8008/_synapse/admin/v1/rooms?limit=$ROOMLIMIT" \
    | jq '.rooms[]'

    BT=10
    echool "[*] Get a list of the biggest Tables/Rooms (> $BT):\n-----------------"
    curl -s -XGET -H "Authorization: Bearer $ADM_TOKEN" \
                     'http://127.0.0.1:8008/_synapse/admin/v1/rooms?limit=300' \
                     | jq '.rooms[] | select(.state_events > '$BT') | .room_id'

    echo -e "\n[*] Get a biggest SQLite Rooms (> $BT):\n-----------------"
    psql_run 'SELECT room_id, count(*) AS count FROM state_groups_state GROUP BY room_id HAVING count(*) > 1 ORDER BY count DESC;' \
    | sed -r 's/\s//g' | egrep -v '^$'
}

_garbage_collect_rooms() {
    _get_adm_token
    curl -s -XGET -H "Authorization: Bearer $ADM_TOKEN" "http://127.0.0.1:8008/_synapse/admin/v1/rooms?limit=$ROOMLIMIT" > /tmp/roomlist.json
    echo -n "[*] Total Number of Rooms: "; jq '.total_rooms' </tmp/roomlist.json ; echo ; sleep 3

    #extract from that list the rooms with no local users:
    jq '.rooms[] | select(.joined_local_members == '$JLM') | .room_id' < /tmp/roomlist.json > /tmp/rooms_to_purge.list
    sed s/\"//g -i /tmp/rooms_to_purge.list

    echo "[*] Get List of ($(wc -l </tmp/rooms_to_purge.list)) purgeable rooms with $JLM local members"; echo
    jq '.rooms[] | select(.joined_local_members == '$JLM') ' < /tmp/roomlist.json
    read -p "Continue purge rooms? (Press Enter or Ctrl^C to exit)" ntr

    while read room_id; do
        echool "[*] Purge room ($room_id) in loop:\n"
#       curl -s -XPOST -H "Authorization: Bearer $ADM_TOKEN" \
#                       -H "Content-Type: application/json" \
#                       -d '{"room_id":"'"$room_id"'"}' "http://127.0.0.1:8008/_synapse/admin/v1/purge_room"
        #V2
        curl -X DELETE -H "Authorization: Bearer $ADM_TOKEN" \
                       -d '{"room_name": "Removed Room","block":false,"purge":true}' \
                       'http://127.0.0.1:8008/_synapse/admin/v2/rooms/'$room_id''
        sleep 4; echo

        echo "[~] Get status of purge:"
        curl -s -XGET -H "Authorization: Bearer $ADM_TOKEN" \
                      'http://127.0.0.1:8008/_synapse/admin/v2/rooms/'$room_id'/delete_status' \
                      | jq '.results[] | .status'
        sleep 2; echo
    done < /tmp/rooms_to_purge.list

    echo -e "\n[*] Deleting some history logs.."
    while read room_id; do
        echool "[*] Purge room ($room_id) in loop:\n"
        curl -s -XPOST -H "Authorization: Bearer $ADM_TOKEN" \
                       -H "Content-Type: application/json" \
                       -d '{"delete_local_events":true,"purge_up_to_ts":'$DTIME'}' \
                          'http://127.0.0.1:8008/_synapse/admin/v1/purge_history/'$room_id''
        sleep 3; echo
    done < /tmp/rooms_to_purge.list

    echool "[**] Finished deleting..."; echo

    #Best way to seperate the process with --debloating-databse parameter!
    #_debloadting_database
}

_delete_room_manual() {
    _get_adm_token
    ROOMID=$1

    echool "[~] Get status of purge:"
    curl -s -XGET -H "Authorization: Bearer $ADM_TOKEN" \
                  'http://127.0.0.1:8008/_synapse/admin/v2/rooms/'$ROOMID'/delete_status' \
                  | jq '.results[] | .status'

    echool "[*] Additional Deleting room $ROOMID:\n"
    curl -s -XPOST -H "Authorization: Bearer $ADM_TOKEN" \
                       -H "Content-Type: application/json" \
                       -d "{ \"delete_local_events\": false, \"purge_up_to_ts\": ${DTIME} }" \
                       -H "HOST: ${SRV_DOM}" "http://127.0.0.1:8008/_synapse/admin/v1/purge_history/$ROOMID"
    echo; echool "[**] Finished deleting..."; echo
}

_debloadting_database() {
    if [ "$1" == "-s" ]; then
        echool "[!!] Debloating tables / index of Databse (SQLITE3)\n"

        echool "[*] Get a biggest SQLite Rooms (> $BT):\n-----------------"
        psql_run 'SELECT room_id, count(*) AS count FROM state_groups_state GROUP BY room_id HAVING count(*) > 1 ORDER BY count DESC;' \
        | sed -r 's/\s//g' | egrep -v '^$'
        echo; du -sh $SQDB

        echo -e "\nPlease wait...\n"
        systemctl stop matrix-synapse.service
        psql_run 'REINDEX' ; sleep 3
        psql_run 'VACUUM' && systemctl start matrix-synapse.service

        echool "[**] Finished debloating..."; echo; sleep 4

        echool "[~] Get Rooms after debloating- purge:"
        psql_run 'SELECT room_id, count(*) AS count FROM state_groups_state GROUP BY room_id HAVING count(*) > 1 ORDER BY count DESC;' \
        | sed -r 's/\s//g' | egrep -v '^$'
        echo; du -sh $SQDB
    elif [ "$1" == "-p" ]; then
        echool "[!!] Debloating tables / index of Databse (Postgresql)\n"

        echool "[*] Get a biggest PSQL Rooms (> $BT):\n-----------------"
        psql_run 'SELECT room_id, count(*) AS count FROM state_groups_state GROUP BY room_id HAVING count(*) > 1 ORDER BY count DESC;' \
        | sed -r 's/\s//g' | egrep -v '^$'

        echo -e "\nPlease wait...\n"
        systemctl stop matrix-synapse.service
        psql_run 'REINDEX' ; sleep 3
        psql_run 'VACUUM' && systemctl start matrix-synapse.service

        echool "[**] Finished debloating Postgresql DB..."; echo; sleep 4
    else
        echo "DB parameters (-s / -p) missing, exit.."&&exit 1
    fi

    #TODO:
    # synapse-compress-state -t -o state-compressor.sql -p "host=$DB_HOST user=$DB_USER password=$DB_PASS dbname=$SQDB" -r "$room_id"
}

if [ "$1" == "--passwd-reset" ]; then
    _reset_password
elif [ "$1" == "--get-admtoken" ]; then
    _get_adm_token
elif [ "$1" == "--create-user" ]; then
    _create_user
elif [ "$1" == "--list-users" ]; then
    psql_run 'SELECT * FROM users;'
elif [ "$1" == "--list-rooms" ]; then
    #psql_run 'SELECT * FROM rooms;'
    _list_rooms
elif [ "$1" == "--deactivate-user" ]; then
    _deactivate_user
elif [ "$1" == "--cleanup-rooms" ]; then
    _garbage_collect_rooms
elif [ "$1" == "--delete-room" ]; then
    [ ! "$2" ] && echo "Roomid missing, exit.."&&exit 1
    _delete_room_manual $2
elif [ "$1" == "--debloat-database" ]; then
    [ ! "$2" ] && echo "DB parameters (-s / -p) missing, exit.."&&exit 1
    _debloadting_database $2
else
    _help
    exit 1
fi

SUCC="DONE"; _mailcron
exit 0
