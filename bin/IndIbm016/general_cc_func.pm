#!/usr/bin/perl
use Env qw (CCVARIANT_DELIMITER CCPRODUCT CCVARIANT HOME);
sub module_list{
	my ($product,$version)=@_;
	my @module_list=();
	my $modbofile="$HOME/product/${product}/v${version}/config/${product}_v${version}_modbo.dat";
	open (MODBO, "$modbofile") || die "cannot locate modbo file under $modbofile";
	@module_list=<MODBO>;
	close (MODBO);
	chomp (@module_list);
	foreach $modbo(@module_list){
			push (@modbomodule,(split /\s+/, $modbo)[1]);
	}
	return @modbomodule;
}
sub proj_list{
	my ($module,$version)=@_;
	my (@tmpprojs,@proj_list,$tmpproj)=();
	open (PROJS, "$HOME/module/$module/v${version}/config/module_profile") || warn "cannot locate module_profile file under $HOME/module/$module/v${version}/config/module_profile";
	@tmpprojs=<PROJS>;
	chomp (@tmpprojs);
	foreach $tmpproj (@tmpprojs){
		next if $tmpproj=~/PROJnames/;
		next if $tmpproj=~/Base/;
		push (@proj_list, ((split ' ',$tmpproj)[0]).$CCVARIANT_DELIMITER.$CCVARIANT);
	} 
	return @proj_list;
}
sub bb_list{
	my ($proj)=@_;
	my ($bb_name,@bb_list,@proj_profile,$bb_ver);
	open(PROJ_PROFILE,"$HOME/proj/$proj/proj_profile" ) || die "Can't open $HOME/proj/$proj/proj_profile";
	@proj_profile=<PROJ_PROFILE>;
	close(PROJ_PROFILE);
	chomp @proj_profile;
	foreach (@proj_profile) {
		next if ( ( /BBNames/i ) || ( /SubProjects/i ) ) ;
		($bb_name,$bb_ver) = (split(/\s+/,$_))[0,1];
		push (@bb_list,$bb_name);
	}
	return @bb_list;
}
sub print_array{
	my($scriptname,$printtype,@array_to_print)=(@_);
	my $line,$logdir;
	my $ts=`timestamp`;
	chomp $ts;
	$logdir="$HOME/log/$scriptname";
	system "mkdir -p $logdir" if (!-d $logdir);
	my $logfile="$logdir/$scriptname_$ts.log" if (($printtype eq "log")||($printtype eq "mail"));
	if (($printtype eq "log")||($printtype eq "mail")) {
		open (LOGFILE,">$logfile") ;
		print "log file - $logfile\n";
	}
	foreach $line(@array_to_print){
		print LOGFILE "$line\n" if (($printtype eq "log")||($printtype eq "mail"));
		print "$line\n" if ($printtype eq "screen");
	}
	close LOGFILE if (($printtype eq "log")||($printtype eq "mail"));
	return $logfile if ($printtype eq "mail"); 
}
sub send_mail{
	my ($scriptname,$logfile,$emailaddresses)=(@_);
	my $mail;
	foreach $mail(split /,/,$emailaddresses){
		system "cat $logfile | mailx -s \"$scriptname\" $mail";
	}
}
	
			
1;
	