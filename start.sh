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

# Default settings
default_name_count="3"
default_vote_threshold="0" # Vote score an option needs to have to be picked 
default_compared_threshold="10" # Number of rounds an option needs to have to been picked before vote threshold is counted

# functions

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

	query=$(sql query 'select name from names where name='"'"'$name'"'"'')
	if [[ -z "$query" ]]; then
		sql query 'insert into names (name,vote,compared) values ('"'"'$name'"'"',0,0);'
	else
		echo "Skipping, $name already in DB"
	fi
}

function remove_name() {
	name=$(sanitize $1)
	echo "Remove Name $name"
	sql query 'delete from names where name='"'"'$name'"'"''
}

function hiscore() {
	headline "Top 10 names"
	sql column 'select vote, name from names order by vote desc limit 10'
}

function batch_add() {
	# Add names from file
	if [ ! -f $1 ]; then
		echo "File $1 not found!"
		exit 1
	else
		echo "File is $1"
		while read name; do
			add_name "$name"
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
    vote_threshold="${global_vote_threshold:-${default_vote_threshold}}"
    compared_threshold="${global_compared_threshold:-${default_compared_threshold}}"

	# Gets n Options from the DB
	headline "Select best option!"
	names=$(sql query "select name from names where vote > $vote_threshold or compared < $compared_threshold order by random() limit $1")
	options_left=$(echo $names|wc -w)

	if [[ "$options_left" == "1" ]]; then
		echo "Option $names has won!"
		hiscore
		exit 0
	fi

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
			sql query 'update names set vote = vote + 1 where name='"'"'$i'"'"''
		else
			sql query 'update names set vote = vote - 1 where name='"'"'$i'"'"''
		fi

		sql query 'update names set compared = compared + 1 where name='"'"'$i'"'"''

	done
}

function main_menu() {
	headline "Decider Main Menu"
	echo "[1] Start decider"
	echo "[2] Show names"
	echo "[3] Add new name"
	echo "[4] Remove name"
	echo "[5] Show Top 10"
	echo ""
	echo "[o] Change settings"
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
		5)
		hiscore
		;;
		o)
		change_settings
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
	name_count="${global_name_count:-${default_name_count}}"
	ask_options $name_count
	decider
}

function change_settings() {
    name_count="${global_name_count:-${default_name_count}}"
    vote_threshold="${global_vote_threshold:-${default_vote_threshold}}"
    compared_threshold="${global_compared_threshold:-${default_compared_threshold}}"


	headline "Change settings"
	echo "[1] Number of voting options: $name_count"
	echo "[2] Vote threshold: $vote_threshold"
	echo "[3] Compare threshold: $compared_threshold"
	echo ""
	echo -e "[m] Main Menu\n"

	echo -e "\nSelect setting to change:"
	read_decision

	case $decision in
		1)
		echo "Number of options to choose from?"
		read_decision
		if [[ "$decision" =~ ^[2-9]+$ ]]; then
			global_name_count="${decision}"
		else
			echo "Value must be between 2 and 9!"
		fi
		;;
		2)
		echo "How many votes needs an option to be picked after it reached the compared threshold?"
		read decision
		if [[ "$decision" =~ ^-?[0-9]+$ ]]; then
			global_vote_threshold="${decision}"
		else
			echo "Value must be a number!"
		fi
		;;
		3)
		echo "How many times must an option have been picked before the vote threshold counts?"
		read decision
		if [[ "$decision" =~ ^-?[0-9]+$ ]]; then
			global_compared_threshold="${decision}"
		else
			echo "Value must be a number!"
		fi
		;;
		m)
		main_menu
		;;
	esac
	change_settings
}

create_db
check_input

exit 0
