#!/bin/bash

set -e

# First make sure the invoking user's umask is set properly

Umask=$(umask)
echo User $USER, umask is $Umask
if [ "$Umask" != "0007" ] ; then
cat << __UMASK__
*** To ensure all project members can work with newly-created files and directories,
*** and that all newly-created files and directories are private to project members,
*** the umask should be set to 0007.  Add

umask 0007

to the end of the file .bashrc in the UPPMAX home directory.
__UMASK__
else
	echo umask ensures project member access and content privacy
fi
echo


# Now process args and prepare to scan

Head=$1
Project=$2
User=$3

if [ "$Head" = "" -o ! -e "$Head" -o "$Project" = "" ] ; then
cat << __USAGE__
Usage:  ${0##*/} head-directory project [ user ]

Scan head-directory, which is part of the specified UPPMAX project, and look
for files and directories owned by the user which do not match the match the
following rules:

  1. directory does not have the set-group-id bit set (the 's' in drwxrws---)
  2. directory or file group does not match the project group
  3. directory or file has any 'other' permissions set (read, write, execute)

If head-directory is . then the current directory is made explicit by getting
the value of the PWD environment variable and the scan is started using its
value.

If the user is not specified, then directories/files owned by all users will
be examined.  Note that in either case, permission problems may appear when
examining directory trees.

An additional check for the user's current umask is performed at startup, with
the expectation that the umask should be 0007.

__USAGE__
exit 1
fi

if [ "$Head" = "." ] ; then
	Head=$PWD
fi
HeadName=$(echo $Head | tr '/' '-')
# If a user was specified, include the -user clause
if [ "$User" != "" ] ; then
	UserOpt="-user $User"
else
	UserOpt=
	User=all-users
fi

OutputStem=report.check-dirs.$User.$Project.$HeadName.$$
# echo $OutputStem

OUT="$OutputStem.missing-set-group-id.txt"
find "$Head" $UserOpt -type d -perm -g-s -not -perm /g+s -exec ls -ld {} \; > $OUT 2>&1
# inverse is 
# find "$Head" $UserOpt -type d -perm /g+s -exec ls -ld {} \; > $OUT 2>&1
if [ -s "$OUT" ] ; then
cat << __SETGROUPID__
** Directories found with missing set-group-id setting
** Full 'ls' output in $OUT

Correct this by executing the following command:

    find $Head $UserOpt -type d -perm -g-s -not -perm /g+s -exec chmod g+s {} \;

__SETGROUPID__
else
	echo All directories have correct set-group-id setting, good
	echo
	rm -f $OUT
fi

OUT="$OutputStem.group-not-equals-project.txt"
find "$Head" $UserOpt -not -group $Project -exec ls -ld {} \; > $OUT 2>&1
if [ -s "$OUT" ] ; then
cat << __GROUP__
** Directories found with group not equal to $Project
** Full 'ls' output in $OUT

Correct this by executing the following command:

    find $Head $UserOpt -not -group $Project -exec chgrp $Project {} \;

__GROUP__
else
	echo All directories have correct group setting, good
	echo
	rm -f $OUT
fi

OUT="$OutputStem.other-permissions-set.txt"
#find "$Head" $UserOpt -perm /o+rwx -not -perm -o-rwx -exec ls -ld {} \; > $OUT 2>&1
find "$Head" $UserOpt -perm /o+rwx -exec ls -ld {} \; > $OUT 2>&1
if [ -s "$OUT" ] ; then
cat << __OTHERPERMS__
** Directories and/or files found with some 'other' permissions set
** Full 'ls' output in $OUT

Correct this by executing the following command:

    find $Head $UserOpt -perm /o+rwx -exec chmod o-rwx {} \;
	
__OTHERPERMS__
else
	echo All directories and files do not have any \'other\' permissions set, good
	echo
	rm -f $OUT
fi

echo Done.
