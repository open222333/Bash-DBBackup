if $1 -v apt-get >/dev/null; then
	apt-get install sshpass -y
elif $1 -v yum >/dev/null; then
	yum install sshpass -y
else
	echo "other"
fi
