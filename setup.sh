#!/bin/bash

#Function to check a command is present or not
command_exists()
{
	command -V "$1" > /dev/null 2>&1
}


check_password()
{
	if [ "$1" == "$2" ]; then
		return 0
	else
		return 1
	fi
}


#Creating .env file for python-dotenv package
if [ -f .env ]; then
	rm .env
	touch .env
else
	touch .env
fi
#now adding credentials to .env file created previously
#if [ -f "credential_setup_for_dotenv.py" ]; then
#	python3 credential_setup_for_dotenv.py
#else
#	echo "Error: credential_setup_for_dotenv.py file is missing....."
#	exit 1
#fi
read -p "Enter Mysql Host : " MYSQL_HOST
read -p "Enter Mysql UserName : " MYSQL_USER
while true; do
	read -s -p "Enter Mysql Password : " MYSQL_PASSWORD1
	echo
	read -s -p  "Confirm  Mysql Password : " MYSQL_PASSWORD2
    if check_password "$MYSQL_PASSWORD1" "$MYSQL_PASSWORD2"; then
        MYSQL_PASSWORD="$MYSQL_PASSWORD1"
        break
    else
        echo -e "\nPassword not matched try again"
    fi
done
echo  "MYSQL_HOST=$MYSQL_HOST" >> .env
echo  "MYSQL_USER=$MYSQL_USER" >> .env
echo  "MYSQL_PASSWORD=$MYSQL_PASSWORD" >> .env
#checking mysql and python3-venv are present or not if not then try to install them
if command_exists mysql; then
	echo -e "\nMysql Found..\n $(mysql --version)"
else
	echo "Mysql not found............."
	echo "Installing mysql server"
	#Ubuntu/Debian:
	if command_exists apt; then
		sudo apt update
		sudo apt install mysql-server
		sudo apt install python3-venv
		sudo apt install python3-pip
	#Ubuntu/Debian:
	elif command_exists apt-get; then
		sudo apt-get update
		sudo apt-get install mysql-server
		sudo apt-get install python3-venv
		sudo apt-get install python3-pip
	#macOS (using Homebrew):
	elif command_exists brew; then
		brew update
		brew install mysql
	#Arch Linux:
	elif command_exists pacman; then
		sudo pacman -Syu
		sudo pacman -S mysql
		sudo pacman -S python3-venv
		sudo pacman -S python-pip
	#CentOS/RHEL:
	elif command_exists yum; then
		sudo yum update
		sudo yum install mysql-server
		sudo yum install python3-venv
		sudo yum install python3-pip
	#Fedora:
	elif command_exists dnf; then
		sudo dnf install mysql-server
		sudo dnf install python3-venv
		sudo dnf install python3-pip
	#FreeBSD:
	elif command_exists pkg; then
		pkg update
		pkg install mysql80-server
		pkg install python3-venv
	#OpenSUSE:
	elif command_exists zypper; then
		sudo zypper refresh
		sudo zypper install mysql-community-server
		sudo zypper install python3-venv
		sudo zypper install python3-pip
	else
		echo "Mysql not found unable to install automatically. Install mysql manually......."
		exit 1
	fi
fi
#Again verifying mysql is present or not .
if ! command_exists mysql; then
	echo "Mysql not found install it first."
	exit 1
fi
#instaalling python packages
if [ -f "requirements.txt" ]; then
	echo -e "Installing python packages from requirements.txt file......\nRunning python virtual environment...."
	if [ -n "$VIRTUAL_ENV" ]; then
    	echo "Python virtual environment is active : $VIRTUAL_ENV"
		echo "VIRT_ENV=$VIRTUAL_ENV" >> .env
	else
    	echo -e "Python virtual environment is not active.....\nStarting python virtual environment"
		python3 -m venv student
		source student/bin/activate
		echo "Python virtual environment is activated from : $VIRTUAL_ENV"
		echo "VIRT_ENV=$VIRTUAL_ENV" >> .env
	fi
	if command_exists pip; then
		pip install -r requirements.txt
	elif command_exists pip3; then
		pip3 install -r requirements.txt
	else
		echo "Pip not found.......Install pip or start your virtual environment if needed..........."
		exit 1
	fi
else
	echo "requirements.txt file is missing"
fi
#Again Check if the .env file exists
if [ -f .env ]; then
    # Read the contents of the .env file
    source .env
	output=$(sudo mysql <<EOF
	select Host, user, plugin from mysql.user where user='$MYSQL_USER';
EOF
)
	#checking authenticaion plugin is mysql_native_password or not for existing user if not then modifing it
	if [ -n "$output" ]; then
    	host=$(echo "$output" |awk '{print $1}' | grep -v 'Host')
    	user=$(echo "$output" |awk '{print $2}' | grep -v 'user')
    	plugin=$(echo "$output" |awk '{print $3}' | grep -v 'plugin')
    	if [  "$plugin" == "mysql_native_password" ]; then
        	echo "User $MYSQL_USER present and can be connect with mysql.connector."
    	else
			echo "User present...$MYSQL_USER using $plugin authentication plugin which will be changed ---> mysql_native_password";
        	sudo mysql <<EOF
        	alter  user "$MYSQL_USER"@"$MYSQL_HOST" identified with mysql_native_password by "$MYSQL_PASSWORD";
EOF
    	fi
	else
		#creating user if not exists
    	echo "User Not Exists......"
    	echo "creating User $MYSQL_USER with mysql_native_password plugin for connect through mysql.connector"
        if command_exists mariadb; then
            sudo mysql <<EOF
            create user "$MYSQL_USER"@"$MYSQL_HOST" identified by "$MYSQL_PASSWORD";
EOF
        else
            sudo mysql <<EOF
            create user "$MYSQL_USER"@"$MYSQL_HOST" identified with mysql_native_password by "$MYSQL_PASSWORD";
EOF
        fi
#    	sudo mysql <<EOF
#    	create user "$MYSQL_USER"@"$MYSQL_HOST" identified with mysql_native_password by "$MYSQL_PASSWORD";
#EOF
	fi
    #Creating DB and tables for students
    sudo mysql <<EOF
    SELECT 'Removing students database if already present.' as 'INFO';
	drop database if exists students;
	SELECT 'Now creating fresh students database if not already done before.' as 'INFO';
	create database if not exists students;
	use students;


	create table Attributes_Details(
    	Attribute_Name varchar(100),
    	Data_Type varchar(50));

	create table student(
    	RollNo int primary key,
	    Name varchar(50) not NULL);

	insert into Attributes_Details (Attribute_Name, Data_Type) values
    	('RollNo', 'int'),
	    ('Name', 'varchar');

	grant all privileges on students.* to "$MYSQL_USER"@'localhost';
EOF
else
    echo "Error: .env file not found."
    exit 1
fi
#Renaming setup.sh --> reset.sh
if [ -f "setup.sh" ]; then
	echo "Renaming setup.sh --> reset.sh"
	mv setup.sh reset.sh
else
	if [ -f reset.sh ]; then
		echo "setup.sh already changed to reset.sh"
	else
		echo "setup.sh missing"
	fi
fi
echo "Now run python3 main.py to manage students details."
exit 0
