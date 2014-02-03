#!/bin/csh -f
# Linux users have to change $8 to $9
awk '\
BEGIN	{ print "File\t\t\t\tOwner" }\
		{ print $8, "\t", \\
		$3}\
END		{ print "done"}\
'
