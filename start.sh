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
		start)
			# Start decider
			echo "start decider"
			decider
		;;
		hiscore)
			# Show best voted names
			hiscore
			;;
		*)
			# Show Main Menu
			main_menu
		;;
		esac
}

function sql() {
	local query="$2"
	local mode="$1"
	local options=""

	case $mode in
		list)
		options="-line"
		;;
		query)
		options=""
		;;
		column)
		options="-column -header"
		;;
	esac

	execute="sqlite3 ${options} ${db} \"${query}\""
	eval $execute
}

function headline() {
	local text="$1"
	local text_length="$(echo $text|wc -m)"
	echo -e "\n$text"
	seq -s= $text_length|tr -d '[:digit:]'
	echo ""
}

function create_db() {
# Open DB and if it doen't exist, create it
if [ ! -f $db ]; then
	echo "Database not found!"
	sql query "create table names (id INTEGER PRIMARY KEY,name TEXT UNIQUE,vote INTEGER,compared INTEGER);"
fi
}

function add_name() {
	name=$(sanitize $1)
	echo "Add Name $name"
	sql query "insert into names (name,vote,compared) values (\"$name\",0,0);"
}

function remove_name() {
	name=$(sanitize $1)
	echo "Remove Name $name"
	sql query "delete from names where name=\"$name\""
}

function hiscore() {
	headline "Top 10 names"
	sql column "select vote, name from names order by vote desc limit 10"
}

function batch_add() {
	# Add names from file
	if [ ! -f $1 ]; then
		echo "File $1 not found!"
		exit 1
	else
		echo "File is $1"
		while read name; do
			query=$(sql query "select name from names where name=\"$name\"")
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
	capitalize="$(tr '[:lower:]' '[:upper:]' <<< ${alpha:0:1})${alpha:1}"
	echo "$capitalize"
}

function ask_options() {
	# Gets n Options from the DB
	headline "Select best option!"
	names=$(sql query "select name from names where vote > 0 or compared < 10 order by random() limit $1")
	local loop="1"
	unset name_array
	declare -a name_array
	for name in $names;
	do
		i=$((loop++))
		echo "[$i] $name"
		name_array[$i]="$name"
	done

	echo -e "\n[q] Quit"

	read_decision

	case $decision in
		q)
		exit 0;
		;;
		[1-$i])
		best=${name_array[$decision]}
		write_decision "$best" "${name_array[*]}"
		;;
		*)
		echo "Press Button 1-$i to choose the best option!"
		sleep 5
		;;
	esac

}

function write_decision() {
	# Add deciscion to DB
	best="$1"
	rest="$2"
	for i in $rest; do
		if [ "$i" == "$best" ]; then
			sql query "update names set vote = vote + 1 where name=\"$i\""
		else
			sql query "update names set vote = vote - 1 where name=\"$i\""
		fi

		sql query "update names set compared = compared + 1 where name=\"$i\""

	done
}

function main_menu() {
	headline "Decider Main Menu"
	echo "[1] Start decider"
	echo "[2] Show names"
	echo "[3] Add new name"
	echo "[4] Remove name"
	echo ""
	echo "[o] Change options"
	echo "[q] Quit"

	read_decision

	case $decision in
		1)
		decider
		;;
		2)
		print_db
		;;
		3)
		echo -e "\nEnter new name:"
		read name
		add_name $name
		;;
		4)
		echo -e "\nName to delete:"
		read name
		remove_name $name
		;;
		o)
		;;
		q)
		exit 0;
		;;
		*)
		clear
		;;
	esac

	main_menu
}

function read_decision() {
	read -s -n 1 decision
}

function print_db() {
	headline "Database content"
	sql list "select name,vote,compared from names"
	echo ""
	entries=$(sql query "select count(name) from names")
	echo "Number of names in database: $entries"
}

function decider() {
	clear
	name_count="${1:-3}"
	ask_options $name_count
	decider
}

create_db
check_input

exit 0
