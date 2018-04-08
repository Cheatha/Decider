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
		batchadd)
			# Add new names from text file
			batch_add $option
		;;
		remove)
			# Remove name
			remove_name $option
		;;
		print)
			# Show DB entries
			print_db
		;;
		start|*)
			# Start decider
			echo "start decider"
		;;
		esac
}

function sql() {
	sqlite3 -batch -line $db "$@"
}

function create_db() {
# Open DB and if it doen't exist, create it
if [ ! -f $db ]; then
	echo "Database not found!"
	sql "create table names (id INTEGER PRIMARY KEY,name TEXT UNIQUE,vote INTEGER,compared INTEGER);"
fi
}

function add_name() {
	name=$(sanitize $1)
	echo "Add Name $name"
	sql "insert into names (name,vote,compared) values (\"$name\",0,0);"
}

function remove_name() {
	name=$(sanitize $1)
	echo "Remove Name $name"
	sql "delete from names where name=\"$name\""
}

function batch_add() {
	# Add names from file
	if [ ! -f $1 ]; then
		echo "File $1 not found!"
		exit 1
	else
		echo "File is $1"
		while read name; do
			query=$(sql "select name from names where name=\"$name\"")
			if [[ -z "$query" ]]; then
			add_name "$name"
			else
			echo "Skipping, $name already in DB"
			fi
		echo ""
		done < "$1"
	fi
}

function sanitize() {
	lowercase=$(echo "$1"|tr '[:upper:]' '[:lower:]')
	trimmed=$(echo "$lowercase"|tr -d '[:blank:]')
	alpha=$(echo "$trimmed"|tr -cd  '[:alpha:]')
	echo "$alpha"
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

function print_db() {
	sql "select name,vote,compared from names"
}


create_db
check_input
#present_options foo bar
#read_decision

exit 0
