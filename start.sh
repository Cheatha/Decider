#!/bin/bash
# Enable unofficial bash strict mode
# More info: http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

# Config
db_name="names.db"
db_path=$(dirname "$0")
db="$db_path/$db_name"


function create_db() {
# Open DB and if it doen't exist, create it
if [ ! -f $db ]; then
	 echo "Database not found!"
	sqlite3 -batch $db "create table names (id INTEGER PRIMARY KEY,name TEXT,vote INTEGER,compared INTEGER);"
else
	sqlite3 -batch $db "select * from names"
fi
}

function get_names() {
# Gets n Options from the DB
echo "Gets n Options from the DB"
}

function write_decision() {
# Add deciscion to DB
echo "Add deciscion to DB"

}

function present_options() {

echo "[1] $1"
echo "[2] $2"

}

function read_decision() {
read -n 1 decision
}

create_db
#present_options foo bar
#read_decision
