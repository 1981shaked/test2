#!/usr/local/bin/perl 
#--------------------------------------------------------
#   Name:        
#   Purpose:     
#   Description: 
#   Writen By:  George Goldenberg
#   Date:       29.07.2004
#--------------------------------------------------------
#use lib "$ENV{'CCPROJECTHOME'}/bin";
use lib "$ENV{'HOME'}/bin";
push (@INC, "$ENV{'CCMNGRHOME'}/bin");
#push (@INC, "$ENV{'HOME'}/bin");
require general_cc_function;
&initial_var();
&analize_parms();
if (!defined($opt_P)){
	@all_files = <$ENV{'CCPROJECTHOME'}/product/*/$version/config/*_modbo.dat>;
	if (!defined(@all_files))
	{
		print "Error: Can't open file $ENV{'CCPROJECTHOME'}/product/*/$version/config/*_modbo.dat\n";
		print "\nPlease check the version number\n\n";	
	}
	foreach $file (@all_files)
	{
		@temp = split("/product/",$file);
		@temp1 = split("/",$temp[1]);
		$product =$temp1[0];
		&product_list();
		&print_result();
	}
}
else
{
	&product_list();
	&print_result();
}

