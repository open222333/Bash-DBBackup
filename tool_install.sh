if [ $2 ]; then
	PM_NAME=$2
else
	PM_NAME=$1
fi

if $1 -v apt-get >/dev/null; then
	apt-get install $PM_NAME -y
elif $1 -v yum >/dev/null; then
	yum install $PM_NAME -y
else
	echo "other"
fi
