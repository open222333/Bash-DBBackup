source `dirname -- "$0"`/.env

if [ $2 ]; then
	PM_NAME=$2
else
	PM_NAME=$1
fi

if [ -x "$(command -v apt-get)" ]; then
	if [ $USE_SUDO == 1 ]; then
		echo $SUDO_PASSWORD | sudo -S apt-get install $PM_NAME -y
	else
		apt-get install $PM_NAME -y
	fi
elif [ -x "$(command -v yum)" ]; then
	if [ $USE_SUDO == 1 ]; then
		echo $SUDO_PASSWORD | sudo -S yum install $PM_NAME -y
	else
		yum install $PM_NAME -y
	fi
else
	echo "other"
fi
