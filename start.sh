#!/bin/bash

function present_options() {

echo "[1] $1"
echo "[2] $2"

}

function read_decision() {
read -n 1 decision
}

#present_options foo bar
#read_decision
