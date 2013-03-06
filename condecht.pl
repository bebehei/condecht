#!/usr/bin/env perl

# vim set ts=2; 
#
#   Copyright (C) 2013, Benedikt Heine
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#   You'll find the GNU General Public License in the file
#   with the name LICENSE.
#

##LOAD MODULES ##
use warnings;
use strict;
# extra modules
use lib "./lib";
use Config::IniFiles;
use List::MoreUtils qw(any);
# standard modules
use Getopt::Long;
use Pod::Usage;
use File::Path;
use File::Copy;
use File::Basename;
##END LOAD MODULES ##

##DECLARE EMPTY VARIABLES ##
my $mode;    #decide, whether install/remove config/package
my @syspkgs; #packages for the system packagemanager
my @pkgs;    #packages of condecht to install
my %main;    #the information of the main-section in $config_main
my %files;   #all values of the parameter file at the depending
             #sections to all @pkgs
my @notes;   #saves all notes, to print them at the end again
##END DECLARE EMPTY VARIABLES ##

##DEFAULT VARIABLES ##
my $config_main = "/etc/condecht";
my $config_pkg = "packages.conf";
my @hooks = (	"pre", "pre_pkg_install", "post_pkg_install",
							"pre_config_remove", "post_config_remove",
							"pre_pkg_remove", "post_pkg_remove",
							"pre_config_install", "post_config_install", "post");
##END DEFAULT VARIABLES ##

##FUNCTIONS ##
sub hook {
	for my $package (@pkgs){
		if(-x "$main{path}$main{host}/$package/$_[0]"){
			system "$main{path}$main{host}/$package/$_[0]";
			if($? != 0){
				printf STDERR "The hook $_[0] of $package " .
											"returned the error code %d." .
											"Do you want to contiunue? [y/N]", $? >> 8;
				unless(<STDIN> =~ /y/i){
					die "Stopped while installing the packages. " .
							"You may have to fix some errors.\n";
				}
			}
		}
	}
}

sub fcp {
	my ($ffile,$fdest,$fmode,$fuid,$fgid) = @_;
	my $fowner = getpwuid($fuid);
	my $fgroup = getgrgid($fgid);
	my $fail = 0;
##todo
#think about verbose option of mkpath
#think about error option of mkpath
	mkpath(dirname($fdest), 
				{	owner => $fowner,
					group => $fgroup,
					mode => oct($main{perm_d})
				})
		or $fail = 1;

	#copy file $ffile, $fdest
	if(!$fail){
		copy($ffile, $fdest) or $fail = 2;
	}

	#chmod file $fmode, $fdest
	if(!$fail){
		chmod oct($fmode), $fdest or $fail = 3;
	}

	#chown file $fuid, $fgid, $fdest
	if(!$fail){
		chown $fuid, $fgid, $fdest or $fail = 4;
	}
	
	warn "PATH: failed creating path " . dirname($fdest) . ": $!\n"
		if($fail == 1);
	warn "COPY: failed at $fdest: $!"
		if($fail == 2);
	warn "CHMOD: failed at $fdest: $!"
		if($fail == 3);
	warn "CHOWN: failed at $fdest: $!"
		if($fail == 4);

	return $fail;
}
##END FUNCTIONS ##

##READ COMMAND LINE PARAMETERS ##
GetOptions(
	# general options
	"c|config=s"	=> \$config_main,
	"h|host=s"		=> \$main{host},
	"d|dir=s"			=> \$main{home},
	"g|group=s"		=> \$main{group},
	"u|user=s"		=> \$main{user},
	"v|verbose"		=> \$main{verb},
	"debug"				=> \$main{debug},
	"p|prefix=s"	=> \$main{prefix},
	"opt=s%"			=> \%main,
	"help"				=> sub { pod2usage(1) },
	# install/remove configs/packages
	"pi=s{,}"			=> sub	{
													if(!$mode or ($mode eq "pi")) {
														$mode = "pi"; shift(@_); push @pkgs, @_;
													} else { exit(1); }
												},
	"pr=s{,}"			=> sub	{
													if(!$mode or ($mode eq "pr")) {
															$mode = "pr"; shift(@_); push @pkgs, @_;
													} else { exit(1); }
												},
	"ci=s{,}"			=> sub	{
													if(!$mode or ($mode eq "ci")) {
														$mode = "ci"; shift(@_); push @pkgs, @_;
													} else { exit(1); }
												},
	"cr=s{,}"			=> sub	{
													if(!$mode or ($mode eq "cr")) {
														$mode = "cr"; shift(@_); push @pkgs, @_;
													} else { exit(1); }
												},
	# list packages
	"lp"					=> sub	{
													if(!$mode or ($mode eq "lp")){
														$mode = "lp";
													} else { exit(1); }
												},
	# backup
	"b|backup"		=> sub	{
													if(!$mode or ($mode eq "ba")){
														$mode = "ba";
													} else { exit(1); }
												},
	# check config
	"check"				=> sub	{
													if(!$mode or ($mode eq "cc")){
														$mode = "cc";
													} else { exit(1); }
												},
);

##CHECK PARAMETERS ##
if(!$mode){
	die "No mode specified!\n";
}
if($main{debug}){
	warn "The option debug is not in use yet!\n";
}
if(!$main{prefix}){
	# define prefix as empty -> no error for uninitialized value
	$main{prefix} = "";
}
else {
	unless($main{prefix} =~ /^\//){
		die "OPTION: prefix is no absolute path!\n";
	}
	# delete last slash of prefix to prevent double-slash
	# after joining with $fdest, which has got leading slash
	$main{prefix} =~ s/\/$//;
}

##END CHECK PARAMETERS ##
##END READ COMMAND LINE PARAMETERS ##

##INIT CONFIG_MAIN ##
my $cfg = Config::IniFiles->new(-file => $config_main, -nocase => 1)
	or die "@Config::IniFiles::errors";
##END INIT MAIN CONFIG ##

##READ CONFIG_MAIN ##
if($cfg->SectionExists("main")){
	for((	"path", "backup", "host", "dist", "pkgINS",
				"pkgREM", "user", "group", "home","perm_f", "perm_d")){
		if(defined $cfg->val("main", $_)){
			# the value of the config file will be written into the $main{$_}
			# only if it is not defined over commandline already
			if(!$main{$_}){
				$main{$_} = $cfg->val("main", $_);
			}
		}
		else {
			die "CONFIG: Missing definition $_ in $config_main!\n";
		}
	}
}
else {
	die "CONFIG: Missing section main $config_main!\n";
}
##END READ CONFIG_MAIN ##

##CHECK CONFIG_MAIN ##

#CHECK: values of main config
# add trailing space to execute systemcommand in an appropriate way
$main{pkgINS} = $main{pkgINS} . " "
	unless($main{pkgINS} =~ / $/);
$main{pkgREM} = $main{pkgREM} . " "
	unless($main{pkgREM} =~ / $/);

#CHECK: user and group existence
#  -> if exists write into $main{uid/gid}
if(defined getpwnam($main{user})){
	$main{uid} = (getpwnam($main{user}))[2];
}
else {
	die "CONFIG: No user $main{user}!\n";
}
if(defined getgrnam($main{group})){
	$main{gid} = (getgrnam($main{group}))[2];
}
else {
	die "CONFIG: No group $main{group}!\n";
}

#CHECK: absolute path and trailing shlash of home and path
unless($main{path} =~ /\/$/){
	$main{path} = $main{path} . "/";
}
unless($main{path} =~ /^\//){
	die "CONFIG: definition path is not absolute in $config_main\n";
}
unless($main{home} =~ /\/$/){
	$main{home} = $main{home} . "/";
}
unless($main{home} =~ /^\//){
	die "CONFIG: definition home is not absolute in $config_main\n";
}

#CHECK: default permissions of perm_d perm_f
if(length($main{perm_d}) == 3){
	$main{perm_d} = "0$main{perm_d}";
}
else {
	die "CONFIG: perm_d permissions not valid!\n";
}
for my $char (split(//, $main{perm_d})){
	die "CONFIG: perm_d permissions not valid\n"
		if(!(0 <= $char && $char <= 7));
}

if(length($main{perm_f}) == 3){
	$main{perm_f} = "0$main{perm_f}";
}
else {
	die "CONFIG: perm_f permissions not valid!\n";
}
for my $char (split(//, $main{perm_f})){
	die "CONFIG: perm_f permissions not valid\n"
		if(!(0 <= $char && $char <= 7));
}

# set path of packages.conf file
$main{config_pkg} = $main{path} . $config_pkg;
##END CHECK CONFIG_MAIN ##

##INIT PACKAGES-CONFIG ##
my $pkg = Config::IniFiles->new(-file => $main{config_pkg}, -nocase => 1)
	or die "@Config::IniFiles::errors";
##END INIT PACKAGES CONFIG ##

##DO OTHER THINGS THAN DEPLOYING/REMOVING PACKAGES ##
# list packages
if($mode eq "lp"){
	for my $package ($pkg->Groups){
		print "$package\n";
	}
}

##CHECK CONFIG_PKG ##
if($mode eq "cc"){
	print "PKGCONF: Location $main{config_pkg}\n";

	# $pkg->Groups: use all packages to check whole config
	for my $package ($pkg->Groups){
		#CHECK: Section Exists
		unless($pkg->SectionExists("$package all")){
			warn "PKGCONF: $package: missing section [$package all]!\n";
			next;
		}

		#CHECK: Section Exsists for host
		unless($pkg->SectionExists("$package $main{host}")){
			warn "PKGCONF: $package: missing section [$package $main{host}]!\n";
		}

		#PRINT: Every note of Sections
		for my $note ($pkg->val("$package all", "note"),
									$pkg->val("$package $main{host}", "note")){
			print "NOTE: $package: $note\n";
		}
		
		#CHECK: System packages
		my $count = 0;
		for my $dist ($pkg->val("$package all", "dist"),
									$pkg->val("$package $main{host}", "dist")){
			if($dist =~ /^$main{dist}\s*:(.*)/){
				push @syspkgs, split(" ", $1);
				$count++;
			}
		}
		warn "PKGCONF: $package: No Systempackages are defined!\n"
			if($count == 0);
	
		#CHECK: Dependencies
		for my $dep (	$pkg->val("$package all", "deps"),
									$pkg->val("$package $main{host}", "deps")){
			for(split(" ", $dep)){
				warn "PKGCONF: $package: unresolved dependency $_\n"
					unless($pkg->SectionExists("$_ all"));
			}
		}

		#CHECK: Every File
		for my $file ($pkg->val("$package all", "file"),
									$pkg->val("$package $main{host}", "file")){
			my ($fdest,$ffile,$fmode,$fuser,$fgroup) = split(",", $file);
			my ($fuid, $fgid);

			# replace the strings $home$ $user$ and $group$
			# used to prevent a double slash after home-dir
			$fdest =~ s/\$home\$\//$main{home}/; 
			$fdest =~ s/\$home\$/$main{home}/;
			$fuser =~ s/\$user\$/$main{user}/;
			$fgroup =~ s/\$group\$/$main{group}/;

			$ffile = "$main{path}$main{host}/$package/$ffile";
			$fdest = $main{prefix} . $fdest;
	
			if($files{$fdest}){
				warn "PKGCONF: $package: duplicate definiton of file $fdest\n";
			}

			# check config, if all users are existing, groups too
			# check if user exists, if yes -> write uid to $fuid
			if(defined getpwnam($fuser)){
				$fuid = (getpwnam($fuser))[2];
			}
			else {
				warn "PKGCONF: $package: No user $fuser!\n";
			}
			# same as above, just for the group
			if(defined getgrnam($fgroup)){
				$fgid = (getgrnam($fgroup))[2];
			}
			else {
				warn "PKGCONF: $package: No group $fgroup!\n";
			}

			$files{$fdest} = join(",", ($fdest, $ffile, $fmode,
																	$fuser, $fuid, $fgroup, $fgid));
			
			#check the file-existence
			# check for installed files
			# check for permissions, owner, group of installed files
			if(-f $fdest){
				#check filemode
				if($fmode != sprintf "%o\n", (stat($fdest))[2] & 07777){
					warn "SYSTEM: $package: File $fdest has not mode $fmode\n";
				}

				#read uid and gid of files
				my ($efuid, $efgid) = (stat($fdest))[4,5];
				#transform uid and gid to usernames
				my $efgroup = getgrgid($efgid);
				my $efowner = getpwuid($efuid);

				#warn if uid and gid are not the same as defined in packages.conf
				warn "SYSTEM: $package: File $fdest has user " .
						 "$efowner($efuid) instead of $fuser($fuid)!\n"
					if($fuid != $efuid);
				warn "SYSTEM: $package: File $fdest has group " .
						 "$efgroup($efuid) instead of $fgroup($fgid)!\n"
					if($fgid != $efgid);
			}
			else {
				warn "SYSTEM: $package: File $fdest is not available.\n";
			}
			# check config, if all files are in repo
			if(! -f $ffile){
				warn "REPO: $package: File $ffile is not available.\n";
			}
		}
	}
	print "INFO: Registered system-packages:\n@syspkgs\n";
}
##END CHECK CONFIG_PKG ##

##BACKUP ##
if($mode eq "ba"){
	# get date of $today
	my ($mday,$mon,$year) = (localtime(time))[3,4,5];
	$year = $year + 1900;
	$mon = $mon + 1;
	my $today = "$mday-$mon-$year";

	#SAVE: $config_main
	fcp($config_main,
			"$main{path}backup.d/$main{host}/$today/condecht",
			$main{perm_f},
			$main{uid},
			$main{gid}, );

	for my $package ($pkg->Groups){
		#SAVE: files
		for my $file ($pkg->val("$package all", "file"),
									$pkg->val("$package $main{host}", "file")){

			my ($fdest,$ffile,$fmode,$fowner,$fgroup) = split(",", $file);
			# used to prevent a double slash after home-dir
			$fdest =~ s/\$home\$\//$main{home}/; 
			$fdest =~ s/\$home\$/$main{home}/;

			# copy, chmod and chown
			fcp($fdest,
					"$main{path}backup.d/$main{host}/$today/$package/$ffile",
					$main{perm_f},
					$main{uid},
					$main{gid});
		}

		#SAVE: hooks
		for my $hook (@hooks){
			# check if file available -> create path only, if there are hooks
			if( -f $main{path} . $main{host} . "/" . $package . "/" . $hook){

				# copy, chmod and chown
				fcp("$main{path}$main{host}/$package/$hook",
						"$main{path}backup.d/$main{host}/$today/$package/$hook",
						$main{perm_f},
						$main{uid},
						$main{gid});

			}
		}
	}
}
##END BACKUP ##
##END DO OTHER THINGS THAN DEPLOYING/REMOVING PACKAGES ##

##READ CONFIG_PKG ##
for my $package (@pkgs){
	#CHECK: Section Exists
	unless($pkg->SectionExists("$package all")){
		die "PKGCONF: $package: missing section [$package all]!\n";
	}

	#CHECK: Section Exsists for host
	unless($pkg->SectionExists("$package $main{host}")){
		warn "PKGCONF: $package: missing section [$package $main{host}]!\n"
				if($main{verbose});
	}
	#PRINT: notes and save them to @notes (will print it at the end again)
	for my $note ($pkg->val("$package all", "note"),
								$pkg->val("$package $main{host}", "note")){
		print "NOTE: $package: $note\n";
		push @notes, "NOTE: $package: $note";
	}

	#READ: systempackages for distribution
	my $count = 0;
	for my $dist ($pkg->val("$package all", "dist"),
								$pkg->val("$package $main{host}", "dist")){
		if($dist =~ /^$main{dist}\s*:(.*)/){
			push @syspkgs, split(" ", $1);
			$count++;
		}
	}
	warn "$package: No Systempackages are defined!\n"
		if($count == 0 && $main{verbose});

	#READ: Dependencies
	for my $dep (	$pkg->val("$package all", "deps"),
								$pkg->val("$package $main{host}", "deps")){
		for(split(" ", $dep)){
			print "PKGCONF: $package: dependency $_ added.\n"
				if($main{verbose});
			die "PKGCONF: $package: unresolved dependency $_!\n"
				unless($pkg->SectionExists("$_ all"));
##todo nur überprüfen ob funktioniert
			push @pkgs, $_
				unless( any { /^$_$/ } @pkgs);
		}
	}

	#READ: Every File
	for my $file ($pkg->val("$package all", "file"),
								$pkg->val("$package $main{host}", "file")){
		my ($fdest,$ffile,$fmode,$fuser,$fgroup) = split(",", $file);
		my ($fuid, $fgid);

		# replace the strings $home$ $user$ and $group$
 		# used to prevent a double slash after home-dir
		$fdest =~ s/\$home\$\//$main{home}/;
		$fdest =~ s/\$home\$/$main{home}/;
		$fuser =~ s/\$user\$/$main{user}/;
		$fgroup =~ s/\$group\$/$main{group}/;

		$ffile = "$main{path}$main{host}/$package/$ffile";
		$fdest = $main{prefix} . $fdest;

		if($files{$fdest}){
			warn "PKGCONF: $package: duplicate definiton of: $fdest\n"
				if($main{verbose});
		}

		# check config, if all users are existing, groups too
		# check if user exists, if yes -> write uid to $fuid
		if(defined getpwnam($fuser)){
			$fuid = (getpwnam($fuser))[2];
		}
		else {
			die "PKGCONF: $package: No user $fuser!\n";
		}
		# same as above, just for the group
		if(defined getgrnam($fgroup)){
			$fgid = (getgrnam($fgroup))[2];
		}
		else {
			die "PKGCONF: $package: No group $fgroup!\n";
		}

		$files{$fdest} = join(",", ($fdest, $ffile, $fmode,
																$fuser, $fuid, $fgroup, $fgid));
	}
}
##END READ CONFIG_PKG ##

hook("pre");

#MODE: install packages
if($mode eq "pi"){
	hook("pre_pkg_install");

	# execute package install command
	system $main{pkgINS} . join(" ", @syspkgs);

	# catch the error code
	if($? != 0){
		printf STDERR "The packagemanager returned the error code %d. " .
									"Continue installing configfiles? [y/N]", $? >> 8;
		unless(<STDIN> =~ /y/i){
			die "Stopped while installing the packages. " .
					"You may have to fix some errors.\n";
		}
	}

	hook("post_pkg_install");
}

#MODE: remove configs (packages)
if($mode eq "cr" || $mode eq "pr"){
	hook("pre_config_remove");

	for my $file (values %files){
		my ($fdest) = split(",", $file);

		if($main{backup}){
			my $fdest2 = $fdest;
			$fdest2 =~ s/^\///;
			$fdest2 =~ s/\//-/g;
			$fdest2 =~ s/\.//g;

			my $exitcode = fcp(	$fdest,
													"$main{path}backup.d/$main{host}/old/$fdest2",
													$main{perm_f},
													$main{uid},
													$main{gid}, );

			my @errors = (
				"No error!",
				"create the path",
				"backup the file",
				"chmod the file",
				"chown the file",
				);

			printf STDERR "The subroutine failed to $errors[$exitcode]. " .
										"Press Enter to go ahead or hit <Ctrl>-C to bail out.";
			$exitcode = <STDIN>;
			undef(@errors);
			undef($exitcode);

		}
		unlink($fdest)
			or warn "Could not remove file $fdest\n";
	}
	
	hook("post_config_remove");
}
	
#MODE: remove packages
if($mode eq "pr"){
	hook("pre_pkg_remove");

	# execute package remove command
	system $main{pkgREM} . @syspkgs;

	# catch the error code
	if($? != 0){
		printf STDERR "The packagemanager returned the error code %d. " .
									"Continue removing configfiles? [y/N]", $? >> 8;
		unless(<STDIN> =~ /y/i){
			die "Stopped while removing the packages. " .
					"You may have to fix some errors.\n";
		}
	}
	
	hook("post_pkg_remove");
}
	
#MODE: install configs (packages)
if($mode eq "ci" || $mode eq "pi"){
	hook("pre_config_install");
	
	for my $file (values %files){
		my ($fdest,$ffile,$fmode,$fowner,$fuid,$fgroup,$fgid) = split(",", $file);

		my $exitcode = fcp(	$ffile,
												$fdest,
												$fmode,
												$fuid,
												$fgid, );

		my @errors = (
			"No error!",
			"create the path",
			"deploy the file",
			"chmod the file",
			"chown the file",
			);

		printf STDERR "The subroutine failed to $errors[$exitcode]. " .
									"Press Enter to go ahead or hit <Ctrl>-C to bail out.";
		$exitcode = <STDIN>;

		undef(@errors);
		undef($exitcode);
	}
	
	hook("post_config_install");
}
	
hook("post");

# check if installing/removing packages/configs
if($mode =~ m/^(c|p)(r|i)$/){
	# print out notes again
	for my $note (@notes){
		print "$note\n";
	}
}

exit(0);

__END__
=head1 NAME

Condecht

=head2 Condecht
Condecht is a config-file distribution software.

=head1 SYNOPSIS

condecht <ACTION> @packages

=over 8
=item B<--help>

Print this help-page.

=item B<--ci>


=back

=head1 DESCRIPTION

B<This program> will read the given input file(s) and do something
useful with the contents thereof.

=cut
