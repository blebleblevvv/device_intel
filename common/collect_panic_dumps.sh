#!/system/bin/sh

set -x

mkdir /data/pstore
mount -t pstore none /data/pstore

# if pstore dir is empty, no crash occured
NO_CRASH=0
for F in `ls /data/pstore`; do
	NO_CRASH=1
done

if [ $NO_CRASH -eq 1 ]; then
	DEST_DIR=/data/panic_dumps/`date +%F-%H:%M`
	mkdir -p $DEST_DIR

	for F in `ls /data/pstore`; do
		dd if=/data/pstore/$F of=$DEST_DIR/$F &> /dev/null
		rm /data/pstore/$F
	done
fi

umount /data/pstore
rmdir /data/pstore

set +x
