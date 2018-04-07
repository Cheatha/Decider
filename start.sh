#!/bin/bash
# Enable unofficial bash strict mode
# More info: http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

mode=${1:-alpha}
option=${2:-alpha}

# Config
db_name="names.db"
db_path=$(dirname "$0")
db="$db_path/$db_name"

function check_input() {
	case $mode in
		add)
			# Add new name
			add_name $option
		;;
		remove)
			# Remove name
			remove_name $option
		;;
		start|*)
			# Start decider
			echo "start decider"
		;;
		esac
}

function sql() {
	sqlite3 -batch $db "$@"
}

function create_db() {
# Open DB and if it doen't exist, create it
if [ ! -f $db ]; then
	echo "Database not found!"
	sql "create table names (id INTEGER PRIMARY KEY,name TEXT,vote INTEGER,compared INTEGER);"
##else
##	sqlite3 -batch $db "select * from names"
fi
}

function add_name() {
	echo "Add Name $1"
}

function remove_name() {
	echo "Remove Name $1"
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
check_input
#present_options foo bar
#read_decision
