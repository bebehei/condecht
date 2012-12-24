#!/usr/bin/perl

my $file = "bashrc,/home/user/.bashrc,700,user,user";

my @array = split(",", $file);
my ($test1, $test2) = qw( split(",", $file) )[0,2];
print $test1 $test2;
#print @array[1,2];
