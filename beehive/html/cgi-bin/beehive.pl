#!/usr/bin/perl 

###################LOAD PM ##########################
use Device::SerialPort;
use Time::HiRes qw(clock_gettime usleep nanosleep);
use Switch;
use DBI;
use Getopt::Long;
use File::Basename;
use Cwd qw(abs_path);
#################################################
##################DIRS FILE##################
my ($current) = dirname(abs_path(__FILE__));
$dirsfile = $current.'/dirs.pl';
$xbee_subs = $current.'/xbee_subs.pl';
require $dirsfile;
require $xbee_subs;
####################################

###############GET HASHES FROM CONFIG###############
%event_settings = &hash_event_settings();
%xbee_commands = &hash_command_settings();
%frametypes = &hash_frametype();
%serial_settings = &hash_serial_settings();
#####################################

################GET REQUIREMENTS########
my ($rrd_dir) = &get_rrd();
my ($events_config_file) = &get_config_events();
my ($mysql_user) = &get_mysql_user();
my ($mysql_host) = &get_mysql_host();
my ($password) = &get_mysql_login();
my ($mysql_db) = &get_mysql_db();
my ($xbee_commands_file) = &get_xbee_commands();

#######################################

##################FOR MAIN SWITCH##############
$at_response = hex($frametypes{'AT_RESPONSE'});
$remote_at_response = hex($frametypes{'ZGB_REMOTE_AT_RESPONSE'});
$data_io_response = hex($frametypes{'ZGB_RX_IO'});
#########################################################

#######SET TIMEOUT GLOBAL TIMEOUT######################
$global_timeout = 5.0; #wait 5 seconds
$time_passed = 0.0;
#########################################

############SETUP PORT###################
$port = Device::SerialPort->new($serial_settings{'PORT'});
$port->databits($serial_settings{'DATABITS'});
$port->baudrate($serial_settings{'BAUDRATE'});
$port->parity($serial_settings{'PARITY'});
$port->stopbits($serial_settings{'STOPBITS'});
################################################

###############SETUP MYSQL CONNECTION##########
my ($connecting_host) = 'dbi:mysql:'.$mysql_db;
$connect = DBI->connect($connecting_host,$mysql_user,$password);
$network_table = 'network_devices';
$coord_table = 'coordinators';
####################GLOBAL STRUCTURES#############################
my (%RX_DATA);
my (%HASH_RX_DATA);
my ($packets_rx) = 0;
@EVENT_ACTIONS;
$EVENT_COUNT=0;
$EVENT_FLAG=0;
#################################################
while(1){
last if(&check_process);
}
################SEARCH OPTIONS##################
my ($searchoption) = '';
my ($helpOption) = '';
my ($IDoption) = '';
$constructpacket = '';
$MYSQLwrite = '';
$MYSQLupdate = '';
$getcoord = '';
$RRDcreate = '';
$RRDupdate = '';
$RRDFLAG = 0;
my ($remoteAToption) = '';
my ($localAToption) = '';
my ($remotedevice) = '';
my ($inputcommand) = '';
my (@parameter) = '';
my ($beverbose) = '';
my ($graphstart) = '';
my ($graphend) = '';
my ($dograph) = '';

	GetOptions ('help' => \$helpOption,'h' => \$helpOption,'packet=s' => \$constructpacket, 'mysqlw' => \$MYSQLwrite, 'mysqlu' => \$MYSQLupdate, 'coord' => \$getcoord, 'RRDcreate' => \$RRDcreate, 'RRDupdate' => \$RRDupdate,'search' => \$searchoption, 'remote' => \$remoteAToption,'device=s' => \$remotedevice, 'command=s' => \$inputcommand, 'param=s{,}'=> \@parameter,'local' => \$localAToption, 'verbose' => \$beverbose, 'start=s' => \$graphstart, 'end=s' => \$graphend, 'graph' => \$dograph);
if($helpOption){
	&helpOptions();
	exit;
}

if($dograph){
	&graph_rrd($remotedevice,$inputcommand,$graphstart,$graphend);
	&exitprog();
}

if($searchoption){
	local($packet,$packetlength) = &send_AT_command($xbee_commands{'Search_Network'}[0]);
	local ($hexpacket) = pack("H[$packetlength]",$packet);
	$port->write($hexpacket);
	&startwatch();
	&looking();
	&exitprog();
}
elsif($localAToption != ''){
	local ($newparam) = '';
        if(scalar(@parameter)>1){
                $newparam = &resolve_param(\@parameter);
        }
        local ($command) = &prepare_command($inputcommand,$newparam);
        local($packet,$packetlength) = &send_AT_command($command);
        local($sendpacket) = &packpacket($packet,$packetlength);
        $port->write($sendpacket);
	&startwatch();
        &looking();
	&exitprog();
}
elsif($remoteAToption != '' ){
	local ($newparam) = '';
	if(scalar(@parameter)>1){
		$newparam = &resolve_param(\@parameter);
	}
	local ($command) = &prepare_command($inputcommand,$newparam);
	local($packet,$packetlength) = &send_remote_AT_command($remotedevice,$command);
	local($sendpacket) = &packpacket($packet,$packetlength);
	$port->write($sendpacket);
	&startwatch();
        &looking();
        &exitprog();
}		
elsif($getcoord){
	
	local($packet,$packetlength) = &send_AT_command($xbee_commands{'Serial_High'}[0]);
	local($sendpacket) = &packpacket($packet,$packetlength);	
        $port->write($sendpacket);
	
	($packet,$packetlength) = &send_AT_command($xbee_commands{'Serial_Low'}[0]);
        $sendpacket = &packpacket($packet,$packetlength);
        $port->write($sendpacket);
	
	($packet,$packetlength) = &send_AT_command($xbee_commands{'Node_ID'}[0]);
        $sendpacket = &packpacket($packet,$packetlength);
        $port->write($sendpacket);
	
	($packet,$packetlength) = &send_AT_command($xbee_commands{'Software_Version'}[0]);
        $sendpacket = &packpacket($packet,$packetlength);
        $port->write($sendpacket);
	
	($packet,$packetlength) = &send_AT_command($xbee_commands{'Hardware_Version'}[0]);
        $sendpacket = &packpacket($packet,$packetlength);
        $port->write($sendpacket);
	
	&startwatch();
        &looking();
	&exitprog();
}
elsif($constructpacket != null){
local($sending) = &packetsend($constructpacket);
$port->write($sending);
&startwatch();
&looking();
&exitprog();
}

else{
	&helpOptions();
	exit;
}

sub looking(){

	while(1){
		usleep(4000); 
		($count,$startbyte) = $port->read(1);
		$hex = sprintf('%02X', ord($startbyte));
		$startbyte = ord($startbyte);
		if($startbyte == 126){
			&packetreceived();
				%RX_DATA = &analyze_return(\@bytearray);
					&cache_events($RX_DATA{'Serial_Low'},$RX_DATA{'Sent_CMD'},$RX_DATA{'Data_RX'});
					&storepacket(%RX_DATA);
					if($MYSQLwrite){
						&mysql_write(%RX_DATA);
					}
					if($MYSQLupdate){
						&mysql_update(%RX_DATA);
					}
					if($RRDcreate){
						if($RX_DATA{'Sent_CMD'} eq "IS"){
							&rrd_create($RX_DATA{'Analog_Pins'},$RX_DATA{'Serial_Low'});
							}else{
						&rrd_create($RX_DATA{'Sent_CMD'},$RX_DATA{'Serial_Low'});
						}
					}
					if($RRDupdate){
						if($RX_DATA{'Sent_CMD'} eq "IS"){
							&rrd_IS($RX_DATA{'Serial_Low'},$RX_DATA{'Analog_Pins'},$RX_DATA{'Analog_Data'});
						}else{
						&rrd_update($RX_DATA{'Sent_CMD'},$RX_DATA{'Serial_Low'},$RX_DATA{'Data_RX'});
						}
						&exitprog();	
					}
				&startwatch();	
=cut				switch(ord($bytearray[3])){

					case  "$at_response"
							{
								%RX_DATA = &at_received(\@bytearray);
									&storepacket(%RX_DATA);	
									if($beverbose){
										&be_verbose($RX_DATA{'Data_RX'}[0],$RX_DATA{'Sent_CMD'});	
									}
								&startwatch(); 
							}
					case "$data_io_response"
							{
								%RX_DATA = &DATA_IO_RX(\@bytearray); 
								&startwatch();
							}
					case "$remote_at_response"
						{ 
							%RX_DATA = &at_remote_received(\@bytearray);
							if($beverbose){
                                                                                &be_verbose($RX_DATA{'Data_RX'}[0],$RX_DATA{'Sent_CMD'});
                                                                        } 
							&startwatch();
						}	
=cut				}
		}

		$time_passed = clock_gettime(CLOCK_REALTIME);
		
			if(($time_passed-$global_start) > $global_timeout){
				print "\nTimeout of $global_timeout seconds reached without response\n";
=cut					foreach $entry (keys %HASH_RX_DATA){
						 print $entry;
						foreach $subentry (keys %{$HASH_RX_DATA{$entry}}){
			
							foreach $subsub (keys %{$HASH_RX_DATA{$entry}{$subentry}}){
								print "$subentry => $subsub"; print "=> ";print $HASH_RX_DATA{$entry}{$subentry}{$subsub}; print "\n";	
							}	
						}
=cut					}
			}
	return if(($time_passed-$global_start) > $global_timeout);		
#	&exitprog();
	}
	

}

#############################################################################################

##################Begin Functions###########################################################
sub packetreceived{
 $bytearray[0] = pack('H[2]','7E');
for($i=1;$i<3;++$i){
	usleep(4000);
	($count,$bytearray[$i]) = $port->read(1);
}
$bytecount = ord($bytearray[1])+ord($bytearray[2])+4;#+4 for startbyte, MSB, LSB, Checksum

for($j=3;$j<$bytecount;++$j){
	usleep(4000);
	($count,$bytearray[$j]) = $port->read(1);
}
print "\n$bytecount Bytes in Packet Received: ";
for($k=0;$k<$bytecount;++$k){
	$hex = sprintf('%02X',ord($bytearray[$k]));
	print " $hex ";
}
print "\n\n";
&write_rx_log(\@bytearray);
return $bytearray;
}

sub packetsend{
	local ($newpacket) = $_[0];
	local ($length) = length($newpacket);
	local ($checksum) = &compute_checksum($newpacket,$length);
	local ($sendlength) = $length+2; #for checksum	
	my ($packettosend) = pack("H[$sendlength]",$newpacket.$checksum);
return $packettosend;
}

sub packpacket{
	local($packet) =$_[0];
	local($length) = $_[1];
	local($packettosend) = pack("H[$length]",$packet);
	return $packettosend;
}

sub startwatch{
	$global_start = clock_gettime(CLOCK_REALTIME);
	}


sub storepacket{
	local (%hash) = @_;
		foreach $key (sort(keys %hash)){
			$HASH_RX_DATA{$hash{'Serial_Low'}}->{$hash{'Sent_CMD'}}->{$key} = $hash{$key};
		}
}	
