#!/usr/bin/bash
pip install -r requirements.txt
if [ -f .env ]; then
	rm .env
	touch .env
else
	touch .env
fi
if [ -f "credential_setup_for_dotenv.py" ]; then
	python3 credential_setup_for_dotenv.py
else
	echo "Error: credential_setup_for_dotenv.py file is missing....."
	exit 1
fi
if which mysql > /dev/null 2>&1; then
	echo "Mysql Found..\n $(mysql --version)"
#	continue
else
	echo "Mysql not found............."
	echo "Installing mysql server"
	sudo apt install mysql-server
fi
#db="student_db.sql"
env_file=".env"
# Check if the .env file exists
if [ -f "$env_file" ]; then
    # Read the contents of the .env file
    source "$env_file"
	output=$(sudo mysql <<EOF
	select Host, user, plugin from mysql.user where user='$MYSQL_USER';
EOF
)
	if [ -n "$output" ]; then
    	host=$(echo "$output" |awk '{print $1}' | grep -v 'Host')
    	user=$(echo "$output" |awk '{print $2}' | grep -v 'user')
    	plugin=$(echo "$output" |awk '{print $3}' | grep -v 'plugin')
    	if [  "$plugin" == "mysql_native_password" ]; then
        	echo "User $MYSQL_USER present and can be connect with mysql.connector."
    	else
        	sudo mysql <<EOF
        	update user "$MYSQL_USER"@"$MYSQL_HOST" identified with mysql_native_password by "$MYSQL_PASSWORD";
EOF
    	fi
	else
    	echo "User Not Exists......"
    	echo "creating User $MYSQL_USER with mysql_native_password plugin for connect througn mysql.connector"
    	sudo mysql <<EOF
    	create user "$MYSQL_USER"@"$MYSQL_HOST" identified with mysql_native_password by "$MYSQL_PASSWORD";
EOF
	fi
    # You can now use the variables defined in the .env  file
    #mysql -u $MYSQL_USER -p$MYSQL_PASSWORD < $db
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
if [ -f "setup.sh" ]; then
	echo "Renaming -> reset.sh"
	mv setup.sh reset.sh
fi
echo "Now run python3 main.py to manage students details."
exit 0
