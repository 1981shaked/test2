#!/usr/local/bin/perl -w

use strict;

my ($LOCK_SH) = 1;
my ($LOCK_EX) = 2;
my ($LOCK_NB) = 4;
my ($LOCK_UN) = 8;

sub lock  ()
{
	my ($fd) = @_;

	flock ($fd, $LOCK_EX);
}
sub unlock  ()
{
	my ($fd) = @_;

	flock ($fd, $LOCK_UN);
}

sub LogAndDie()
{
	my ($name, $data) = @_;
	&LogWrite ($name, $data . "\n");
	die $data;
}

sub LogWrite()
{
	my ($name, $data) = @_;

        die "Can't open file $name $!" if (!open (LOGFILE, ">>" .  $name));
	flock (LOGFILE,$LOCK_EX);
	print LOGFILE "$data\n";
	flock (LOGFILE,$LOCK_UN);
	close (LOGFILE);

}
1;
