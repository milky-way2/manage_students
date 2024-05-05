if [ -f .env ]; then
	source .env
else
	echo "No .env file found"
	exit 1
fi
if [ -n "$VIRTUAL_ENV" ]; then
	if [ "$VIRTUAL_ENV" != "$VIRT_ENV" ]; then
		echo "Changing python virtual environment....."
		deactivate
		source "$VIRT_ENV/bin/activate"
	fi
else
	echo "Starting python virtual environment....."
    source "$VIRT_ENV/bin/activate"
fi
python3 main.py
deactivate
