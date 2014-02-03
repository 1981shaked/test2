#!/usr/bin/perl 
##############################################################################
#
# Name    : general_cc_function.pm
# Purpose : Defined sub-routines used bt show_str script
#
# General Flow:
#
# Usage: Called internally by show_str 
#
# Dependencies: show_str
# Author  : George Goldenberg
# Supervisor : Doron K
# Updates
# date: 27.07.2004   User: George  G       Purpose:   Creation
# date: 31.10.2004   User: Rajaram S       Purpose:   Fixed LEL bugs
# date: Dec 2006  Ishay Azoulay   Enable Ensemble projects to use -L and -C parameters       
#########################################################################################################

        ##########################################################
        #                     SUBROUTINS                         #
        ##########################################################

##############################################################################
# Name    : product_list
# Purpose :
##############################################################################
#use Env qw (CCVARIANT_DELIMITER); 
$CCVARIANT_DELIMITER="V";

sub product_list{
   if (!(-d "$ccpath/product/$product"))
   {
     die "Product $product doesnt exist\n";
   }
   
   my $modbo_file ="$ccpath/product/$product/$version/config/${product}_${version}_modbo.dat";
   $output_file ="/tmp/product_list$timestamp";
   open (OUTPUT, ">>$output_file");
   open(MODBO_FILE, $modbo_file)|| die "Error: Can't open the $modbo_file\n\nPlease check the version number\n\n";
   %module_hash = ();
   while(<MODBO_FILE>){
      $bit ="";
      s/[0-9] //g;
      s/^[0-9]//g;
      if(/ /){$module =$`};
      $module_hash{$module}++;
      if($module_hash{$module} == 1){
         chomp ($ccpath,$module,$version,);
         my $module_profile ="$ccpath/module/$module/$version/config/module_profile";
         my $module_variants ="$ccpath/module/$module/$version/config/module_variants";
         my %seen = ();
         my @vva=();
         if (defined $vrt){   # variant entered
              if ($vrt =~ /32/ || $vrt eq "" || $vrt eq "default") { 
              	    $bit = "";
              } else {     # check valid variant
                   	$bit = $vrt;
                   	open(VARIANTS, $module_variants);
                   	#unless (grep {$bit} <VARIANTS>) {
                   	@vva = (<VARIANTS>);
                   	chomp @vva;
                   	%seen = map { $_ => 1 } @vva;
                   	unless ($seen{$bit}) {
                   	   die "No such variant $bit in file $module_variants\n";
                   	}
             	   	if ($CCVARIANT_DELIMITER){
             	   	$bit = "$CCVARIANT_DELIMITER" . "$bit";
                	} else {
                		die "Dont know which delimiter to add...\n";
                	}
                   
              }
         } else {             # no variant take default.
             open(VARIANTS, $module_variants);
             @vva = <VARIANTS>;
             chomp @vva;
             if (scalar @vva ==  0) {
             	die "variant file $module_variants is empty...exiting..\n";
             } 
             if ("$vva[0]" eq "32") {
             	$bit = "";
             } else {
             	if ($CCVARIANT_DELIMITER){
             	   $bit = "$CCVARIANT_DELIMITER" . "$vva[0]";
                } else {
                	die "Dont know which delimiter to add \$CCVARIANT_DELIMITER is empty...\n";
                }
             }
         }
         close VARIANTS;
         open(PROFILE, $module_profile)|| die "Error: Can't open the $module_profile\n\nPlease check the version number\n\n";
         while(<PROFILE>){
            if(!/PROJnames/&&!/Base =/){
               s/ [0-9]//g;chomp;
                    $project ="$_$bit";
               my $proj_profile ="$ccpath/proj/$project/proj_profile";
               open(PROJ_PROFILE, $proj_profile);
               while(<PROJ_PROFILE>){
                  if(!/BBnames/&&!/SubProjects/){
                     #s/ [0-9]//g;
                     chomp;s/ /:/g;
                     print OUTPUT "${product}:${module}:${version}:${project}:$_\n";
                  }
               }
            }
         }
         close PROFILE;
      }      
   }
   close MODBO_FILE;
   close OUTPUT;
}
##############################################################################
# Name    : print_result
# Purpose :
##############################################################################

sub print_result{
   my @splited = ();
   my $field;

   open (PRINT, $output_file);
   @find ="";
   @level ="";
   if (defined($opt_l)){
       @level = split /:/,$opt_l;
   } elsif (defined($opt_L)||defined($opt_C)){
       @level = (7,8,9);
   }
   while(<PRINT>){
      $row =$_;
      #==== PRODUCT ====
      if (defined($opt_P)){
         if(defined($opt_L)){
           if ($ENV{'CCPROD'} eq "ensemble") {
                #==== ensemble ====
                @splited = split /:/,$_;
                pop @splited;
                $field =  pop @splited;
                if ($opt_v eq $field) {
                   print;
                }
           } else {
                #==== enabler ====
	            foreach $level(@level){if(/[a-z][a-z]${level}:/ || /[a-z]${level}[a-z]/){print}}
           }
         }elsif(defined($opt_C)){
           if ($ENV{'CCPROD'} eq "ensemble") {
                 #==== ensemble ====
                 @splited = split /:/,$_;
                 pop @splited;
                 $field =  pop @splited;
                 #print "opt_v = $opt_v field = $field\n";
                 if ($opt_v ne $field) {
                    print;
                 }
           } else {
                #==== enabler ====
                if(!/[a-z][a-z]7/&& !/[a-z][a-z]8/&& !/[a-z][a-z]9/){print}
           }
         }elsif (defined($opt_l)){
           foreach $level(@level){if(/${ver}:$level/){print}}
         }else{print}

      #==== MODULE ====
      }elsif (defined($opt_M)){
         @module = split /:/,$opt_M;
         foreach $modul(@module){
            if (/:${modul}:/) {push @find, $modul}
               if(defined($opt_L)||!defined($opt_C)){
                  if ($ENV{'CCPROD'} eq "ensemble") {
                      #==== ensemble ====
                      @splited = split /:/,$_;
                      pop @splited;
                      $field =  pop @splited;
                      if ($opt_v eq $field) {
                         print;
                         push @find, $modul;
                      }
                 } else {
                      #==== enabler ====
                      foreach $level(@level){ if(/${product}:${modul}:$version/&&/[a-z][a-z]${level}/){print;push @find, $modul}
                 }
            }   

            }elsif (defined($opt_C)||!defined($opt_L)){
               if(/${product}:${modul}:$version/){
                  if ($ENV{'CCPROD'} eq "ensemble") {
                     #==== ensemble ====
                     @splited = split /:/,$_;
                     pop @splited;
                     $field =  pop @splited;
                     #print "opt_v = $opt_v field = $field\n";
                     if ($opt_v ne $field) {
                        print;
                        push @find, $modul;
                     }
                   } else {
                       #==== enabler ====
                       if(!/[a-z][a-z]7/&& !/[a-z][a-z]8/&& !/[a-z][a-z]9/){print;push @find, $modul}
                   }

               }
            }elsif (defined($opt_l)){
               foreach $level(@level){
                  if(/:${modul}:/ && /${ver}:$level/){print}
               }
         
            }elsif(/${product}:${modul}:$version/){print;push @find, $modul}
         }

      #==== PROJECT ====
      } elsif (defined($opt_p)){
         @proj = split /:/,$opt_p;
         foreach $proj(@proj){
           chomp($proj);
           if (/:${proj}:/) {push @find, $proj} 
           if(defined($opt_L)) {
              if (/:${version}:${proj}:/) {
                  if ($ENV{'CCPROD'} eq "ensemble") {
                      #==== ensemble ====
                         @splited = split /:/,$_;
                         pop @splited;
                         $field =  pop @splited;
                         if ($opt_v eq $field) {
                            print;
                            push @find, $proj;
                         }
                 } else {
                      #==== enabler ====
                      foreach $level(@level) { if(/:${version}:${proj}:/&&/[a-z]${level}[a-z]*/) {print;push @find, $proj} }
                 }
               }

           } elsif (defined($opt_C)) {

             if (/:${version}:${proj}:/) {
                  if ($ENV{'CCPROD'} eq "ensemble") {
                     #==== ensemble ====
                     @splited = split /:/,$_;
                     pop @splited;
                     $field =  pop @splited;
                     #print "opt_v = $opt_v field = $field\n";
                     if ($opt_v ne $field) {
                        print;
                        push @find, $proj;
                     }
                   } else {
                       #==== enabler ====
                       if(!/[a-z][a-z]7/&& !/[a-z][a-z]8/&& !/[a-z][a-z]9/){print;push @find, $proj}
                   }

             }

           }

           else { 
               if(/:${version}:${proj}:/){print;push @find, $proj}
           } 
         }

      #==== BB ====
      } elsif (defined($opt_b)){
         @bb = split /:/,$opt_b;
         foreach $bb(@bb){
            if (/:${bb}:/) {push @find, $bb}

            if(defined($opt_L)) {
              if (/${bb}:$bbver/) {

                 if ($ENV{'CCPROD'} eq "ensemble") {
                    #==== ensemble ====
                    @splited = split /:/,$_;
                    pop @splited;
                    $field =  pop @splited;
                    if ($opt_v eq $field) {
                       print;
                    }
                  } else {
                    #==== enabler ====
                    foreach $level(@level) { if(/$product/&&/:${bb}:v/&&/$version/&&/[a-z][a-z]${level}/) {print;push @find, $bb} }
                  }
                }

            } elsif (defined($opt_C)) {
              if ($ENV{'CCPROD'} eq "ensemble") {
#print "bb=$bb bbver =$bbver $_\n";
               if (/:${bb}:/) {
                 #==== ensemble ====
                 @splited = split /:/,$_;
                 pop @splited;
                 $field =  pop @splited;
#print "opt_v = $opt_v field = $field\n";
                 if ($opt_v ne $field) {
                    print;
                 }
               }
           } else {
                #==== enabler ====
                if (/${bb}:$bbver/) { if(!/[a-z][a-z]7/&& !/[a-z][a-z]8/&& !/[a-z][a-z]9/){print;push @find, $bb} }
           }

            }  else {

                if(/$product/&&/:${bb}:v/&&/$version/){print;push @find, $bb}

            }

         }
      }
   }
   chomp @find;
   chomp @module;
   chomp @proj;
   chomp @bb;
   if (defined($opt_M)){
      foreach $module(@module){
         $no_find =1;
         foreach $find(@find){
            if("$module" eq "$find"){$no_find =0;next}
         }
         #if($no_find){print "\n\tError: The module: $module doesn't exist in $product $version\n\n";next}
      }
   }
   if (defined($opt_p)){
      foreach $proj(@proj){
         $no_find =1;
         foreach $find(@find){
            if("$proj" eq "$find"){$no_find =0;next}
         }
         #if($no_find){print "\n\tError: The project: $proj doesn't exist in $product $version\n\n";next}
      }
   }
   if (defined($opt_b)){
      foreach $bb(@bb){
         $no_find =1;
         foreach $find(@find){
            if("$bb" eq "$find"){$no_find =0;next}
         }
         #if($no_find){print "\n\tError: The BB: $bb doesn't exist in $product $version\n\n";next}
      }
   }

   `/usr/xpg4/bin/rm -f $output_file`;
}
##############################################################################
# Name    : initial_var
# Purpose :
##############################################################################

sub initial_var {

   $ccpath ="$ENV{'CCPROJECTHOME'}";
   $timestamp =`timestamp`;
   $bit ="";
   $product ="";
   $modul ="";
   $project ="";
   $proj ="";
   $bb ="";
   $levels ="";
   $version ="";
   $vrt = "";
   $bbver = ""; 
}

##############################################################################
# Name    : usage
# Purpose : 
##############################################################################

sub usage{
        
   my($message) = @_;
   $Name = $1;
   if ($message ne ''){print "$message\n\n"}
   else{
      print "\nUSAGE : $Name [-h] {-P<Product> -t <variant> | -M<module> -t <variant> | -p<project>... | -b<bb>...} -v<version> -l<level> [-L] [-C] -m<e-mail>"; 
      print "-b bb name:[bb name]:[bb name]....\n" ;
      print "-t <variant> (variant = 32| 64 | O2)\n";
   }
   exit ;
}

##############################################################################
# Name    : analize_parms
# Purpose : check params and names of the Product, Modul, Project and BB.
##############################################################################

sub analize_parms{
    
   &getopt('hLCP:M:p:b:l:m:v:t:');
#   $argum =@_;if($argum==0){&usage()}
   if (defined($opt_h)){&usage()}
#  if (!defined($opt_P)){$product ="$ENV{'CCPROD'}"}
   if (defined($opt_P)){
      $product =$opt_P;
      }elsif (defined($opt_M)&&!defined($opt_P)&&!defined($opt_p)&&!defined($opt_b)){
          $modul =$opt_M;
      }elsif (defined($opt_p)&&!defined($opt_P)&&!defined($opt_M)&&!defined($opt_b)){
          $proj =$opt_p;
      }elsif (defined($opt_b)&&!defined($opt_P)&&!defined($opt_M)&&!defined($opt_p)){
          $bb =$opt_b;
      }else{&usage("Please use or -P or -M or -p or -b flags")}
       
      if (defined($opt_v)){$version =$opt_v;$bbver=$opt_v;$version =~s/_//g}else{&usage("Please use the -v option")}
      if (defined($opt_m)){$sw_mail =1}
      if (defined($opt_t))
              {$vrt = $opt_t;}
          else
             {undef $vrt;}
}

####################################################################
#get options function
####################################################################
sub getopt{

    local($argumentative) = @_;
    local(@args,$_,$first,$rest);
    local($errs) = 0;
    local($[) = 0;
    @input_line = @ARGV;

    @args = split( / */, $argumentative );
    while(@ARGV && ($_ = $ARGV[0]) =~ /^-(.)(.*)/) {
        ($first,$rest) = ($1,$2);
        $pos = index($argumentative,$first);
        if($pos >= $[) {
            if($args[$pos+1] eq ':') {
                shift(@ARGV);
                if($rest eq '') {
                    ++$errs unless @ARGV;
                    $rest = shift(@ARGV);
                }
                eval "\$opt_$first = \$rest;";
            }else{
                eval "\$opt_$first = 1";
                if($rest eq '') {shift(@ARGV)}
                else {$ARGV[0] = "-$rest"}
            }
        }else{
            print STDERR "Unknown option: $first\n";
            ++$errs;
            if($rest ne '') {$ARGV[0] = "-$rest"}
            else{shift(@ARGV)}
        }
    }
    $errs == 0;
}

1;
