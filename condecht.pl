#!/usr/bin/env perl

##LOAD MODULES
#use warnings;
#use strict;
use Getopt::Long;
use Pod::Usage;
use Config::IniFiles;
use File::Copy;
##END LOAD MODULES

##DECLARE EMPTY VARIABLES
my $mode;    #decide, whether install/remove config/package
my @syspkgs; #packages for the system packagemanager
my @pkgs;    #packages of condecht to install
my %main;    #the information of the main-section in $config_main
##DECLARE EMPTY VARIABLES

## DEFAULT VARIABLES
my $config_main = "/etc/condecht";
my $config_pkg = "packages.conf";
##END DEFAULT VARIABLES

##HOOK-Functions
sub hook {
	print "$_";
}
##END USED FUNCTIONS

##READ COMMAND LINE PARAMETERS ##
GetOptions(
	"c|config=s" => \$config_main,
	"check" => \$check_config,

	##deciding mode
	"pi=s@" => sub { if(!$mode){ $mode = "pi"; @pkgs = @_; } else { exit(1); }} ,
	"pr=s@" => sub { if(!$mode){ $mode = "pr"; @pkgs = @_; } else { exit(1); }} ,
	"ci=s@" => sub { if(!$mode){ $mode = "ci"; @pkgs = @_; } else { exit(1); }} ,
	"cr=s@" => sub { if(!$mode){ $mode = "cr"; @pkgs = @_; } else { exit(1); }} ,

	##later
	##updating the repo or the client
	#"Sc" => sub { $sync = "client" },
	#"Ss" => sub { $sync = "server" },

	"help|h" => sub { pod2usage(2) },

	##later
	##list hosts
	#"lh" => sub { if(!$list){ my $list = "hosts"; if($_ != ""){	$mode = $_; } } },
	#"lp" => sub { if(!$list){ my $list = "pkg"; if($_ != ""){	$mode = $_; } } },
);

##CHECK PARAMETERS

##END CHECK PARAMETERS

##READ MAIN CONFIG ##
my $cfg = Config::IniFiles->new(-file => $config_main) or die "@Config::IniFiles::errors";

#check variables of hostfile
#a check of the variables is necessary here

if($cfg->SectionExists("main")){
	for(("path", "backup", "host", "dist", "pkgINS", "pkgREM", "repServerUpd", "repClientUpd")){
		if(defined $cfg->val("main", $_)){
			print $_ . "\n";
			if($_ eq 'path'){
				##DEBUG
				print $_ . ":" . $cfg->val("main", $_) . "\n";
				$main{"config_pkg"} = $cfg->val("main", $_) . $config_pkg;
			}
			$main{$_} = $cfg->val("main", $_);
		}
		##later remove this else if
		elsif($_ == "repServerUpd" || $_ == "repClientUpd"){
			##these options are not necessary yet
			$main{$_} = "";
		}
		else {
			die "Couldn't find definition of $_ in $config_main";
		}
	}
}
else {
	die "No Section host defined in config-file $config_main";
}
undef $cfg;
##END READ MAIN CONFIG

##DEBUG
print "\n";
for(keys %main){
		print "$_";
		print " : ";
		print $main{$_};
		print "\n";
}

##INIT PACKAGES-CONFIG
my $pkg = Config::IniFiles->new(-file => $main{"path"} . $config_pkg);
##END INIT PACKAGES CONFIG

##DO OTHER THINGS THAN DEPLOYING/REMOVING PACKAGES ##
##list packages and hosts
if($list){
	if($list == "hosts"){
		#for($pkg){}
	}
	if($list == "pkg"){
		#for(){}
	}
	exit(0);
}

#Check config, if true -> checkconfig && exit
if($check_config){
	if(checkconfig()){
		exit(0);
	}
}
##END DO OTHER THINGS THAN DEPLOYING/REMOVING PACKAGES ##

#PAKETE AUSLESEN, WELCHE GEBRAUCHT WERDEN
##todo
#hier schauen, ob die if-abfrage unnötig ist und @config::inifiles::errors das auch ausgibt!
print $mode;
for $package (@pkgs){
	if($package == $pkg->val("$main{host} $package", "pkg")){
		hook("pre");

		print $mode;
		if($mode == "pi"){
		print "test";
			hook("pre_pkg_install");

			for $dist ($pkg->val("$main{host} $package", "dist")){
				if($dist =~ /^$main{dist}\s*:(.*)/){
					@syspkgs = split(" ", $1);
				}
			}

			system $main{pkgINS} . " " . @syspkgs;

			if($? != 0){
				print "The packagemanager returned an error code. Continue installing packages? [y/N]";
				if(<STDIN> =~ /y/i){
					#do nothing -> config install will be executed
				}
				else {
					die "Stopped while installing the packages. You may have to fix some errors.";
				}
			}

			hook("post_pkg_install");
		}

		if($mode == "cr" || $mode == "pr"){
			hook("pre_confif_remove");

			for $file ($pkg->val("$main{host} $package", "file")){
				($ffile,$fdest) = split(",", $file);
				if($main{backup}){
					system "mv -v $fdest, $main{path}/backup/$fdest" or die "Backup failed: $!";
				}
				else {
					system "rm -v $fdest";
				}
			}

			hook("post_config_remove");
		}

		if($mode == "pr"){
			hook("pre_pkg_remove");

			for $dist ($pkg->val("$main{host} $package", "dist")){
				if($dist =~ /^$main{dist}\s*:(.*)/){
					@syspkgs = split(" ", $1);
				}
			}

			system $main{pkgREM} . " " . @syspkgs;

			if($? != 0){
				print "The packagemanager returned an error code. Continue removing packages? [y/N]";
				if(<STDIN> =~ /y/i){
					#do nothing -> config install will be executed
				}
				else {
					die "Stopped while removing the packages. You may have to fix some errors.";
				}
			}

			hook("post_pkg_remove");
		}

		if($mode == "ci" || $mode == "pi"){
			hook("pre_config_install");
			
			for $file ($pkg->val("$main{host} $package", "file")){
				my ($ffile,$fdest,$fmode,$fowner,$fgroup) = split(",", $file);
				my ($fuid,$fuid,$fuid) = getpwnam($fowner) or die "$fowner not in passwd file";
				my ($fgid,$fgid,$fgid) = getgrnam($fgroup) or die "$fgroup not passwd file";
				system "rm -v $fdest";
				system "cp -v $ffile $fdest";
				chmod oct($fmode), $fdest;
				chown $fuid, $fguid, $fdest;
			}

			hook("post_config_install");
		}

		else {
			die "There's a heavy failure in the software: \$mode == $mode.";
		}
		hook("post");
	}
}

__END__
=head1 NAME

Conf

=head1 SYNOPSIS

Synopsis-part

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<This program> will read the given input file(s) and do something
useful with the contents thereof.

=cut
