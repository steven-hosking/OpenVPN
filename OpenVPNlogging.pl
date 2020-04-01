#!/usr/bin/perl -w
#
# Logs OpenVPN users and activity
# Reads the openvpn-status.log and reports changes to a log

# Cron job:
# * * * * * /usr/bin/perl/script/location/OpenVPNLogging.pl 

use strict;
use warnings; 

my $input_file  = '/etc/openvpn/openvpn-status.log';
my $output_file = '/var/log/openvpn/openvpn-clients.log';
my $temp_file   = '/etc/openvpn/openvpn-tmp.log';
my $sep = ",";
my $clientlist = 0;
my $routingtable = 0;
my @tokens = "";
my %arraytemp = ();	
my %arraybuff = ();	
my $debug = 0;
	
if(open TEMP, , "<", $temp_file) 
{	
# Read temp file	
	my $dummy = <TEMP>;   #Skip header in file
	my @linestemp = <TEMP>;
	close TEMP;
	foreach my $line (@linestemp) {
		chop($line);
		@tokens = split(/,/, $line);
		#ID,IP,CN,BS,BR,CS,LR
		$arraytemp{$tokens[0]}{'IP'}=$tokens[1];
		$arraytemp{$tokens[0]}{'CN'}=$tokens[2];
		$arraytemp{$tokens[0]}{'BS'}=$tokens[3];
		$arraytemp{$tokens[0]}{'BR'}=$tokens[4];
		$arraytemp{$tokens[0]}{'CS'}=$tokens[5];
		$arraytemp{$tokens[0]}{'LR'}=$tokens[6];
	}	
}

open( INPUTF, "<", $input_file ) || die "Can't open $input_file: $!";
my @lines = <INPUTF>;
close INPUTF;

foreach my $line (@lines) 
{
	chop($line);
	if($line  =~ m/^GLOBAL STATS/)
	{
		last;
	}
	if($clientlist eq 1)
	{
		if($line  =~ m/^ROUTING TABLE/)
		{
			next;
		}
		if($line  =~ m/^Virtual Address,Common Name,Real Address,Last Ref/)
		{
			$clientlist = 0;
			$routingtable = 1;
			next;
		}	
		@tokens = split(/,/, $line);
		$arraybuff{$tokens[1]}{'CN'}=$tokens[0];
		$arraybuff{$tokens[1]}{'BR'}=$tokens[2];
		$arraybuff{$tokens[1]}{'BS'}=$tokens[3];
		$arraybuff{$tokens[1]}{'CS'}=$tokens[4];
	}
	if($line  =~ m/^Common Name,Real Address,Bytes Received,Bytes Sent,Connected Since/)
	{
		$clientlist = 1;
		next;
	}
	if($routingtable eq 1)
	{
		@tokens = split(/,/, $line);
		$arraybuff{$tokens[2]}{'IP'}=$tokens[0];
		$arraybuff{$tokens[2]}{'LR'}=$tokens[3];
	}
}

open( TEMP, ">", $temp_file ) || die "Can't open $temp_file: $!";
print TEMP 'ID'.$sep.'IP'.$sep.'CN'.$sep.'BS'.$sep.'BR'.$sep.'CS'.$sep.'LR'."\n";
foreach my $id ( keys %arraybuff) 
{
	if($debug eq 1)
	{
		if((!defined($arraybuff{$id}{'IP'}))||(!defined($arraybuff{$id}{'CN'}))||(!defined($arraybuff{$id}{'BS'}))||(!defined($arraybuff{$id}{'BR'}))||(!defined($arraybuff{$id}{'CS'}))||(!defined($arraybuff{$id}{'LR'})))
		{
			print "== VAR:   ===============================\n";
			print "id is [$id]\n";
			print "IP is [$arraybuff{$id}{'IP'}]\n";
			print "CN is [$arraybuff{$id}{'CN'}]\n";
			print "BS is [$arraybuff{$id}{'BS'}]\n";
			print "BR is [$arraybuff{$id}{'BR'}]\n";
			print "CS is [$arraybuff{$id}{'CS'}]\n";
			print "LR is [$arraybuff{$id}{'LR'}]\n";
			print "== FILE:  ===============================\n";
			foreach my $line (@lines)
			{
				print $line."\n";
			}
			print "== ARRAY: ===============================\n";
			use Data::Dumper;
			print Dumper(\%arraybuff);
		}
	}
	if(defined($arraybuff{$id}{'IP'}))
	{
		print TEMP $id.$sep.$arraybuff{$id}{'IP'}.$sep.$arraybuff{$id}{'CN'}.$sep.$arraybuff{$id}{'BS'}.$sep.$arraybuff{$id}{'BR'}.$sep.$arraybuff{$id}{'CS'}.$sep.$arraybuff{$id}{'LR'}."\n";
	}
}
close TEMP;	

(my $sec,my $min,my $hour,my $mday,my $mon,my $year,my $wday,my $yday,my $isdst) = localtime();
$year += 1900;
$mon++;
my $now_string = sprintf ("%02d-%02d-%04d %02d:%02d:%02d", $mday, $mon, $year, $hour, $min, $sec);

open( OUTPUT, ">>", $output_file ) || die "Can't open $output_file: $!";
foreach my $id ( keys %arraytemp) 
{	
	if (!defined($arraybuff{$id}{'IP'})) 
	{
  		print OUTPUT $now_string.$sep.$id.$sep.$arraytemp{$id}{'IP'}.$sep.$arraytemp{$id}{'CN'}.$sep.$arraytemp{$id}{'BS'}.$sep.$arraytemp{$id}{'BR'}.$sep.$arraytemp{$id}{'CS'}.$sep.$arraytemp{$id}{'LR'}."\n";
  	}
}
close OUTPUT;