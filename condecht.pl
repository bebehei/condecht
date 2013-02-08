#!/usr/bin/env perl

##LOAD MODULES
use warnings;
#use strict;
use Getopt::Long;
use Pod::Usage;
use File::Path;
#use Config::IniFiles or
use lib "./lib";
use Config::IniFiles;
##END LOAD MODULES

##DECLARE EMPTY VARIABLES
my $mode;    #decide, whether install/remove config/package
my @syspkgs; #packages for the system packagemanager
my @pkgs;    #packages of condecht to install
my %main;    #the information of the main-section in $config_main
my %files;   #all values of the parameter file at the depending
             #sections to all @pkgs
my $host;
##DECLARE EMPTY VARIABLES

## DEFAULT VARIABLES
my $config_main = "/etc/condecht";
my $config_pkg = "packages.conf";
##END DEFAULT VARIABLES

##HOOK-Functions
sub hook {
	for $package (@pkgs){
		if(-x $main{path} . $main{host} . "/" . $package . "/" . $_[0]){
			system $main{path} . $main{host} . "/" . $package . "/" . $_[0];
		}
	}
}
##END USED FUNCTIONS

##READ COMMAND LINE PARAMETERS ##
GetOptions(
	##general options
	"c|config=s"	=> \$config_main,
	"h|host=s"		=> \$host,
	"check"				=> sub { if(!$mode){ $mode = "cc"; } else { exit(1); }},
	"help|h"			=> sub { pod2usage(1) },

	##install/remove configs/packages
#print @_ . "\n";
#print @pkgs . "\n";
	"pi=s{,}"			=> sub { if(!$mode or ($mode eq "pi")){ $mode = "pi"; shift(@_); push @pkgs, @_; } else { exit(1); }},
	"pr=s{,}"			=> sub { if(!$mode or ($mode eq "pr")){ $mode = "pr"; shift(@_); push @pkgs, @_; } else { exit(1); }},
	"ci=s{,}"			=> sub { if(!$mode or ($mode eq "ci")){ $mode = "ci"; shift(@_); push @pkgs, @_; } else { exit(1); }},
	"cr=s{,}"			=> sub { if(!$mode or ($mode eq "cr")){ $mode = "cr"; shift(@_); push @pkgs, @_; } else { exit(1); }},

	##list packages
	"lp"					=> sub { if(!$mode){ $mode = "lp"; } else { exit(1); }},
	#backup
	"b|backup"		=> sub { if(!$mode){ $mode = "ba"; } else { exit(1); }},
);

##CHECK PARAMETERS
if(!$mode){
	die "No mode specified!";
}
##END CHECK PARAMETERS

##READ MAIN CONFIG ##
my $cfg = Config::IniFiles->new(-file => $config_main) or die "@Config::IniFiles::errors";
if($cfg->SectionExists("main")){
	for(("path", "backup", "host", "dist", "pkgINS", "pkgREM", "repServerUpd", "repClientUpd")){
		if(defined $cfg->val("main", $_)){
			$main{$_} = $cfg->val("main", $_);

			if(defined $host and $_ eq "host"){
				$main{$_} = $host;
				undef $host;
			}
			if($_ eq 'path'){
				##add trailing slash
				unless($main{path} =~ /\/$/){
					$main{path} = $main{path} . "/";
				}
				unless($main{path} =~ /^\//){
					die "Path is no absolute path";
				}
				$main{"config_pkg"} = $main{path} . $config_pkg;
			}
			if($_ eq "pkgINS" || $_ eq "pkgREM" || $_ eq "repServerUpd" || $_ eq "repClientUpd"){
				unless($main{$_} =~ / $/){
					$main{$_} = $main{$_} . " ";
				}
			}
		}
		##later remove this elsif, when repServer* is implemented
		elsif($_ eq "repServerUpd" || $_ eq "repClientUpd"){
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

##INIT PACKAGES-CONFIG
my $pkg = Config::IniFiles->new(-file => $main{config_pkg}) or die "@Config::IniFiles::errors";
##END INIT PACKAGES CONFIG

##DO OTHER THINGS THAN DEPLOYING/REMOVING PACKAGES ##
if($mode eq "lp"){
	for $package ($pkg->Groups){
		print "$package\n";
	}
	exit(0);
}
#check config
if($mode eq "cc"){
	die "check config not implemented";
	#checkconfig();
}

if($mode eq "ba"){
	($mday,$mon,$year) = (localtime(time))[3,4,5];
	$year = $year + 1900;
	$mon = $mon + 1;

	for $package ($pkg->Groups){
		$mkpath = 0;
		for $file ($pkg->val("$package all", "file"), $pkg->val("$package $main{host}", "file")){
			mkpath "$main{path}backup.d/$main{host}/$mday-$mon-$year/$package/"
				if($mkpath == 0);
			$mkpath = 1;
			my ($fdest,$ffile,$fmode,$fowner,$fgroup) = split(",", $file);
		
			system "cp -v $fdest $main{path}backup.d/$main{host}/$mday-$mon-$year/$package/$ffile";
		}
	}
	system "cp -v $config_main $main{path}backup.d/$main{host}/$mday-$mon-$year/condecht";

	system "chmod 755 -R $main{path}backup.d/$main{host}/";
	system "chown `id -nu`:`id -ng` -R $main{path}backup.d/$main{host}/";
	exit(0);
}
##END DO OTHER THINGS THAN DEPLOYING/REMOVING PACKAGES ##

#READ PACKAGE CONFIGS
for $package (@pkgs){
	unless($pkg->SectionExists("$package all")){
		die "Section [$package all] missing in $main{config_pkg}";
	}
	unless($pkg->SectionExists("$package $main{host}")){
		warn "Section [$package $main{host}] missing in $main{config_pkg}";
	}
	
	for $note ($pkg->val("$package all", "note"), $pkg->val("$package $main{host}", "note")){
		print "$package: $note\n";
	}

	for $dist ($pkg->val("$package all", "dist"), $pkg->val("$package $main{host}", "dist")){
		if($dist =~ /^$main{dist}\s*:(.*)/){
			push @syspkgs, split(" ", $1);
		}
	}

	for $dep ($pkg->val("$package all", "deps"), $pkg->val("$package $main{host}", "deps")){
		for(split(" ", $dep)){
			print "ADDED package $_ as dependency from $package\n";
			push @pkgs, $_;
		}
	}

	for $file ($pkg->val("$package all", "file"), $pkg->val("$package $main{host}", "file")){
		($fdest,$ffile,$fmode,$fuser,$fgroup) = split(",", $file);
		if($files{$fdest}){
			print "Overwriting\n$files{$ffile}\nwith\n$file";
		}
		$files{$fdest} = join(",", ($fdest, "$main{path}$main{host}/$package/$ffile", $fmode, $fuser, $fgroup));
	}
	
}
	
hook("pre");


if($mode eq "pi"){
	hook("pre_pkg_install");

	system $main{pkgINS} . join(" ", @syspkgs);

	if($? != 0){
		print "The packagemanager returned an error code. Continue installing configfiles? [y/N]";
		unless(<STDIN> =~ /y/i){
			die "Stopped while installing the packages. You may have to fix some errors.";
		}
	}

	hook("post_pkg_install");
}

if($mode eq "cr" || $mode eq "pr"){
	hook("pre_config_remove");

	for $file (values %files){
		($fdest) = split(",", $file);

		if($main{backup}){
			my $fdest2 = $fdest;
			$fdest2 =~ s/^\///;
			$fdest2 =~ s/\//-/g;

			system "mv -v $fdest $main{path}backup/$fdest2";
		}
		else {
			system "rm -v $fdest";
		}
	}
	
	hook("post_config_remove");
}
	
if($mode eq "pr"){
	hook("pre_pkg_remove");

	system $main{pkgREM} . @syspkgs;

	if($? != 0){
		print "The packagemanager returned an error code. Continue removing configfiles? [y/N]";
		unless(<STDIN> =~ /y/i){
			die "Stopped while removing the packages. You may have to fix some errors.";
		}
	}
	
	hook("post_pkg_remove");
}
	
if($mode eq "ci" || $mode eq "pi"){
	hook("pre_config_install");
	
	for $file (values %files){
		my ($fdest,$ffile,$fmode,$fowner,$fgroup) = split(",", $file);
		
		system "cp -v $ffile $fdest";
		system "chown $fowner:$fgroup $fdest";
		system "chmod $fmode $fdest";
	}
	
	hook("post_config_install");
}
	
hook("post");

exit(0);

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
