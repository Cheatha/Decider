#!/bin/bash
# Enable unofficial bash strict mode
# More info: http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

mode="${1:-alpha}"
option="${2:-alpha}"

# Config
db_name="options.db"
db_path=$(dirname "$0")
db="$db_path/$db_name"

# Default settings
default_option_count="3"
default_vote_threshold="0" # Vote score an option needs to have to be picked 
default_compared_threshold="10" # Number of rounds an option needs to have to been picked before vote threshold is counted

### Functions
# program flow functions

function check_input() {
	case $mode in
		add)
			# Add new option to DB
			add_option "$option"
		;;
		batchadd)
			# Add new options from text file
			batch_add "$option"
		;;
		remove)
			# Remove option from DB
			remove_option "$option"
		;;
		print)
			# Show DB entries
			print_db
		;;
		start)
			# Start decider
			decider
		;;
		hiscore)
			# Show best voted options
			hiscore
			;;
		*)
			# Show Main Menu
			main_menu
		;;
		esac
}

function main_menu() {
	headline "Decider Main Menu"
	echo "[1] Start decider"
	echo "[2] Show options"
	echo "[3] Add new option"
	echo "[4] Remove option"
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
		echo -e "\nEnter new option:"
		read -r option
		add_option "$option"
		;;
		4)
		echo -e "\nOption to delete:"
		read -r option
		remove_option "$option"
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

function ask_options() {
    vote_threshold="${global_vote_threshold:-${default_vote_threshold}}"
    compared_threshold="${global_compared_threshold:-${default_compared_threshold}}"

	# Gets n Options from the DB
	headline "Select best option!"
	options=$(sql query "select option from options where vote > $vote_threshold or compared < $compared_threshold order by random() limit $1")
	options_left=$(echo "$options"|wc -w)

	if [[ "$options_left" == "1" ]]; then
		echo "Option $options has won!"
		hiscore
		exit 0
	fi

	local loop="1"
	unset option_array
	declare -a option_array
	for option in $options;
	do
		i=$((loop++))
		echo "[$i] $option"
		option_array[$i]="$option"
	done

	echo -e "\n[m] Main menu"
	echo -e "[q] Quit"

	read_decision

	case $decision in
		q)
		exit 0;
		;;
		m)
		main_menu
		;;
		[1-$i])
		best=${option_array[$decision]}
		write_decision "$best" "${option_array[*]}"
		;;
		*)
		echo "Press Button 1-$i to choose the best option!"
		sleep 5
		;;
	esac

}


# Database operation functions

function create_db() {
# Open DB and if it doen't exist, create it
if [ ! -f "$db" ]; then
	echo "Database not found!"
	sql query "create table options (id INTEGER PRIMARY KEY,option TEXT UNIQUE,vote INTEGER,compared INTEGER);"
fi
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
	eval "$execute"
}

function write_decision() {
	# Add deciscion to DB
	best="$1"
	rest="$2"
	for i in $rest; do
		if [ "$i" == "$best" ]; then
			sql query 'update options set vote = vote + 1 where option='"'$i'"''
		else
			sql query 'update options set vote = vote - 1 where option='"'$i'"''
		fi

		sql query 'update options set compared = compared + 1 where option='"'$i'"''

	done
}

# Helper functions

function headline() {
	local text="$1"
	local text_length
	text_length="$(echo \"${text}\"|wc -m)"
	echo -e "\n$text"
	seq -s= "$text_length"|tr -d '[:digit:]'
	echo ""
}

function sanitize() {
	lowercase=$(echo "$1"|tr '[:upper:]' '[:lower:]')
	trimmed=$(echo "$lowercase"|tr -d '[:blank:]')
	alpha=$(echo "$trimmed"|tr -cd  '[:alpha:]')
	capitalize="$(tr '[:lower:]' '[:upper:]' <<< \"${alpha:0:1})${alpha:1}\""
	echo "${capitalize}"
}

function read_decision() {
	read -r -s -n 1 decision
}

# Program modes

function decider() {
	clear
	option_count="${global_option_count:-${default_option_count}}"
	ask_options "$option_count"
	decider
}

function add_option() {
	option=$(sanitize "$1")
	echo "Add option $option"

	query=$(sql query 'select option from options where option='"'$option'"'')
	if [[ -z "$query" && ${#option} -ge 3 ]]; then
		sql query 'insert into options (option,vote,compared) values ('"'$option'"',0,0);'
	else
		echo "Skipping, $option already in DB"
	fi
}

function remove_option() {
	option=$(sanitize "$1")
	echo "Remove option $option"
	sql query 'delete from options where option='"'$option'"''
}

function hiscore() {
	headline "Top 10 options"
	sql column 'select vote, option from options order by vote desc limit 10'
}

function batch_add() {
	# Add options from file
	if [ ! -f "$1" ]; then
		echo "File $1 not found!"
		exit 1
	else
		echo "File is $1"
		while read -r option; do
			add_option "$option"
		done < "$1"
	fi
}

function print_db() {
	headline "Database content"
	sql column "select option,vote,compared from options order by option"
	echo ""
	entries=$(sql query "select count(option) from options")
	echo "Number of options in database: $entries"
}

function change_settings() {
    option_count="${global_option_count:-${default_option_count}}"
    vote_threshold="${global_vote_threshold:-${default_vote_threshold}}"
    compared_threshold="${global_compared_threshold:-${default_compared_threshold}}"


	headline "Change settings"
	echo "[1] Number of voting options: $option_count"
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
			global_option_count="${decision}"
		else
			echo "Value must be between 2 and 9!"
		fi
		;;
		2)
		echo "How many votes needs an option to be picked after it reached the compared threshold?"
		read -r decision
		if [[ "$decision" =~ ^-?[0-9]+$ ]]; then
			global_vote_threshold="${decision}"
		else
			echo "Value must be a number!"
		fi
		;;
		3)
		echo "How many times must an option have been picked before the vote threshold counts?"
		read -r decision
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
