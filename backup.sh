#!/bin/sh

BACKUPDIR='./backup'
TARGET="$BACKUPDIR/$(/bin/date '+%Y-%m-%d_%H-%M-%S')"

if [ ! -f compose ]
then
	echo 'Error: compose script not found' 1>&2
	exit 1
fi

# use export variables from compose
$(grep '^export ' compose)

if ! mkdir -p "$TARGET"
then
	echo "Error: Can't create the target $TARGET directory." 1>&2
	exit 1
fi

if ! /bin/tar --create --one-file-system "$JUKEBOX_LOG" | xz -zc > "$TARGET/log.tar.xz"
then
	echo "Error: backup from logs failed." 1>&2
	exit 2
fi

exit 0
