#!/usr/bin/env perl

use warnings;
use Getopt::Long;
use Pod::Usage;
use Config::IniFiles;

sub variables {
	my $condechtHOST='';
	my $condechtDIST='';
	my $pkgINS='';
	my $pkgREM='';
	my $repServerUPD='';
	my $repClientUPD='';

}

my $gethostfile = "/etc/condecht";
my $config = "./condecht.conf";
my %conf;

my @conf_packages;

#array
my @inscfg = ();
my @remcfg = (); 
my @inspkg = ();
my @rempkg = (); 
my %packages; 

#read parameters
GetOptions(	"b|backup!" => \$backup,
						"B" => sub { $backup = "false" }, "c=s" => \$config,
						"config=s" => \$config,
						"C" => \$check_config,
						"pi=s@" => \@inspkg,
						"pr=s@" => \@rempkg,
						"ci=s@" => \@inscfg,
						"cr=s@" => \@remcfg,
						"Sc" => sub { $sync = "client" },
						"Ss" => sub { $sync = "server" },
						"help|h" => sub { pod2usage(2) },
);

#now we will check after highest priority/safest way
#if p or c is not specified

#Check config, if true -> checkconfig && exit
if($check_config){
	checkconfig();
	exit();
}

#alternative config-file, if true -> take it && check if readable
#read condecht-config
my $cfg = Config::IniFiles->new(-file => $config) or die "@Config::IniFiles::errors";

#print $cfg->sections;
for($cfg->val("pkg:ssh:bebe-arch-lap", "file")){
	print "$_\n";
}

#read Gethostfile
my $host = Config::IniFiles->new(-file => $gethostfile) or die "@Config::IniFiles::errors";

print $host->val("hostdef", "host") or die "@Config::IniFiles::errors";

print "\n\n".$0;

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
