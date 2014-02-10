#!/usr/bin/perl


###############LAST UPDATED JUNE 17, 2011#############
use DBI;
use Cwd qw(abs_path);
use File::Basename;
use List::Util qw[min max];
use Time::HiRes qw(clock_gettime usleep nanosleep);
use Switch;
##############DIRS FILE###################
my $current = dirname(abs_path(__FILE__));
$dirsfile = $current.'/dirs.pl';
require $dirsfile;

my ($rrd_dir) = &get_rrd();
my ($events_config_file) = &get_config_events();
my ($mysql_user) = &get_mysql_user();
my ($mysql_host) = &get_mysql_host();
my ($password) = &get_mysql_login();
my ($mysql_db) = &get_mysql_db();
my ($xbee_commands_file) = &get_xbee_commands();
my ($frametype_file) = &get_frametype_file();
my ($events_profile_dir) = &get_events_profiles_dir();
my ($serial_file) = &get_serial();
############################################

%frametypes = &hash_frametype();
###################MYSQL CONNECTION############
my ($connecting_host) = 'dbi:mysql:'.$mysql_db;
$connect = DBI->connect($connecting_host,$mysql_user,$password);

$network_table = 'network_devices';
##############################################

########################READ events.config##################
sub hash_event_settings{
	local (%returnhash);
	local ($skip) = 0;
	local (@event_name,@event_level);
	open(CONFIG,$events_config_file) or die $!;
		while(<CONFIG>){
			
			if($skip != 0){
				($event_name[$skip],$event_level[$skip]) = split(/:/,$_);
                                $event_level[$skip] = substr($event_level[$skip],0,-1);#removes the \n
                        }

                        ++$skip;
                }
        close(CONFIG) or die $!;

                for($x=1;$x<scalar(@event_name);++$x){
                        $returnhash{$event_name[$x]} = $event_level[$x];
                }

        return %returnhash;	
}

sub hash_serial_settings{
	local (%returnhash);
        local ($skip) = 0;
        local (@serial_name,@serial_value);
        open(CONFIG,$serial_file) or die $!;
                while(<CONFIG>){

                        if($skip != 0){
                                ($serial_name[$skip],$serial_value[$skip]) = split(/:/,$_);
                                $serial_value[$skip] = substr($serial_value[$skip],0,-1);#removes the \n
                        }

                        ++$skip;
                }
        close(CONFIG) or die $!;

                for($x=1;$x<scalar(@serial_name);++$x){
                        $returnhash{$serial_name[$x]} = $serial_value[$x];
                }

        return %returnhash;
}

sub hash_frametype{
        local (%returnhash);
        local ($skip) = 0;
        local (@frame_name,@frame_hex);
        open(CONFIG,$frametype_file) or die $!;
                while(<CONFIG>){

                        if($skip != 0){
                                ($frame_name[$skip],$frame_hex[$skip]) = split(/:/,$_);
                                $frame_hex[$skip] = substr($frame_hex[$skip],0,-1);#removes the \n
                        }

                        ++$skip;
                }
        close(CONFIG) or die $!;

                for($x=1;$x<scalar(@frame_name);++$x){
                        $returnhash{$frame_name[$x]} = $frame_hex[$x];
                }

        return %returnhash;
}

sub hash_reverse_frametype{
		local (%returnhash);
        	local ($skip) = 0;
        	local (@frame_name,@frame_hex);
        	open(CONFIG,$frametype_file) or die $!;
                while(<CONFIG>){

                        if($skip != 0){
                                ($frame_name[$skip],$frame_hex[$skip]) = split(/:/,$_);
                                $frame_hex[$skip] = substr($frame_hex[$skip],0,-1);#removes the \n
                        }

                        ++$skip;
                }
        	close(CONFIG) or die $!;

                	for($x=1;$x<scalar(@frame_name);++$x){
                        	$returnhash{$frame_hex[$x]} = $frame_name[$x];
                	}

        return %returnhash;
}
#############################################################

sub get_current_rrds{

	my @rrdname;
        @rrdname=  `ls $rrd_dir`;
        return @rrdname;
}


############################################################
sub hash_command_settings{
	local (%returnhash);
        local ($skip) = 0;
        local (@command_type,@command_name,@command_abrv);
        open(CONFIG,$xbee_commands_file) or die $!;
                while(<CONFIG>){

                        if($skip != 0){
                                ($command_type[$skip],$command_name[$skip],$command_abrv[$skip]) = split(/:/,$_);
                                $command_abrv[$skip] = substr($command_abrv[$skip],0,-1);#removes the \n
                        }

                        ++$skip;
                }
        close(CONFIG) or die $!;

                for($x=1;$x<scalar(@command_name);++$x){
                        $returnhash{$command_name[$x]}[0] = $command_abrv[$x];
			$returnhash{$command_name[$x]}[1] = $command_type[$x];
                }

        return %returnhash;
}
#############################################################
sub hash_command_reverse{
	local (%returnhash);
        local ($skip) = 0;
        local (@command_type,@command_name,@command_abrv);
        open(CONFIG,$xbee_commands_file) or die $!;
                while(<CONFIG>){

                        if($skip != 0){
                                ($command_type[$skip],$command_name[$skip],$command_abrv[$skip]) = split(/:/,$_);
                                $command_abrv[$skip] = substr($command_abrv[$skip],0,-1);#removes the \n
                        }

                        ++$skip;
                }
        close(CONFIG) or die $!;

                for($x=1;$x<scalar(@command_name);++$x){
                        $returnhash{$command_abrv[$x]}[0] = $command_name[$x];
                        $returnhash{$command_abrv[$x]}[1] = $command_type[$x];
                }

        return %returnhash;
}

sub local_command_contents{
	local (%returnhash);
        local ($skip) = 0;
        local (@command_type,@command_name,@command_abrv,@values);
        open(CONFIG,&get_local_config_dir()) or die $!;
                while(<CONFIG>){

                        if($skip != 0){
                                ($command_type[$skip],$command_name[$skip],$command_abrv[$skip],$values[$skip]) = split(/:/,$_);
                                $values[$skip] = substr($values[$skip],0,-1);#removes the \n
                        }

                        ++$skip;
                }
        close(CONFIG) or die $!;

                for($x=1;$x<scalar(@command_name);++$x){
                        $returnhash{$command_abrv[$x]}[0] = $command_name[$x];
                        $returnhash{$command_abrv[$x]}[1] = $command_type[$x];
			$returnhash{$command_abrv[$x]}[2] = $values[$x];
                }

        return %returnhash;

}
#################################################################

sub prepare_packet{
	local ($checksum) = 0;
        local ($newpacket) = $_[0];
        local ($packetlength) = length($newpacket);
        local ($sendlength) = $packetlength + 2;
	$checksum = &compute_checksum($newpacket,$packetlength);
        local ($packet) = $newpacket.$checksum;
    #    local ($packettosend) = pack("H[$sendlength]",$packet);
	return $packet;
}
################################################################
sub compute_checksum{

	local ($checksum) = 0;
	local ($input) = $_[0];
	local ($packetlength) = $_[1];
	local ($onebyte);
		for($i=6;$i<$packetlength;$i+=2){
                	$onebyte = substr($input,$i,2);
                	$onebyte = pack('H[2]',$onebyte);
                	$checksum += ord($onebyte);
        	}
       	$checksum = 255-$checksum;
        $checksum = sprintf('%02X',$checksum);
        $checksum = substr($checksum,-2,2);
	return $checksum;
}
#####################################################

sub get_mysql_xbee_network{
	local ($counter) = 0;
	local (%returnhash) = ();
        local (@returnvalues);
        local ($newquery) = "SELECT * from $network_table";
        local ($prepare) = $connect->prepare($newquery);
              $prepare->execute();
        		while(@returnvalues = $prepare->fetchrow_array()){
				++$counter;
                		for($x=0;$x<scalar(@returnvalues);++$x){
                			$returnhash{$returnvalues[1]}[$x]= $returnvalues[$x];
                		}

        		}
        return (%returnhash);
}
######################################################
sub compute_timediff{
        local (@storetime);
        local ($time1) = $_[0];
        local ($time2) = $_[1];
        local ($timediff) = $time2-$time1;
        local ($hours) = int($timediff/3600);
        $timediff = $timediff - $hours*3600;
        local $minutes = int($timediff/60);
        $timediff = $timediff - 60*$minutes;
        $seconds = $timediff;
        $storetime[0] = $hours;
        $storetime[1] = $minutes;
        $storetime[2] = $seconds;
        return $storetime;
}
######################################################
sub command2hex{
	local ($hexflag) = 0; #need to discern between hex desired input and ascii
	local ($input) = $_[0];
		if($input =~ m/0x/){$hexflag =1;}
	local ($bit1hex) = '';
	local ($returnhex) = '';
	local ($length) = length($input);
		if($hexflag ==1){
		
			for($x=0;$x<$length;++$x){
				if($x !=2){ #removes the newline character from the file
					if(substr($input,$x,2) eq '0x'){
						$bit1hex = substr($input,$x+2,2);
						$x+=3;
					}else{	
						$bit1hex = sprintf('%02X',ord(substr($input,$x,1)));
					}
					$returnhex = $returnhex.$bit1hex;
				} 
			}
		}else{
			for($x=0;$x<$length;++$x){
                                if($x !=2){
					$bit1hex = sprintf('%02X',ord(substr($input,$x,1)));
					$returnhex.=$bit1hex;
				}
			}	
		}
	return $returnhex;
}

#####################################################		

sub send_AT_command{
	local ($command) = &command2hex($_[0]);
        local ($frametype) = $frametypes{'AT_COMMAND'};
        local ($frameid);
		if($MYSQLwrite){
			$frameid = $frametypes{'MYSQL_WRITE'};
		}elsif($MYSQLupdate){
			$frameid = $frametypes{'MYSQL_UPDATE'};
		}elsif($RRDcreate){
			$frameid = $frametypes{'RRD_CREATE'};
		}elsif($RRDupdate){
			$frameid = $frametypes{'RRD_UPDATE'};
		}elsif($getcoord){
			$frameid = $frametypes{'LOCAL'};
		}else{
			$frameid = '01';
		}
        local ($length) = sprintf("%04X",length($command.$frametype.$frameid)/2);
        local ($packet2send) = '7E'.$length.$frametype.$frameid.$command;
        local ($packet) = &prepare_packet($packet2send);

        local ($packetlength) = length($packet);
        return $packet,$packetlength;
}

sub send_remote_AT_command{
	
	local ($xbeeref) = $_[0];
	local ($command) = $_[1];
	local (%xbeehash) = &get_mysql_xbee_network();
	local ($command) = &command2hex($_[1]);
        local ($frametype) = $frametypes{'ZGB_REMOTE_AT_REQUEST'};
        local ($frameid);
		if($MYSQLwrite){
                        $frameid = $frametypes{'MYSQL_WRITE'};
                }elsif($MYSQLupdate){
                        $frameid = $frametypes{'MYSQL_UPDATE'};
                }elsif($RRDcreate){
                        $frameid = $frametypes{'RRD_CREATE'};
                }elsif($RRDupdate){
                        $frameid = $frametypes{'RRD_UPDATE'};
                }elsif($pins){
			$frameid = $frametypes{'PINS'};	
		}else{
                        $frameid = '01';
                }
	local ($SH) = $xbeehash{$xbeeref}[0];
	local ($SL) = $xbeeref;
	local ($net_addr) = $xbeehash{$xbeeref}[2];
	local ($apply_change) = '02';
	local ($length) = sprintf("%04X",length($frametype.$frameid.$SH.$SL.$net_addr.$apply_change.$command)/2);
	local ($packet2send) = '7E'.$length.$frametype.$frameid.$SH.$SL.$net_addr.$apply_change.$command;
	local ($packet) = &prepare_packet($packet2send);

        local ($packetlength) = length($packet);
        return $packet,$packetlength; 
}

#####################################################
sub at_remote_received {
	local ($ascii_datarx) = '';
	local ($datarx) = '';
	local (%returnhash) = ();	
	local($aref) = @_;
	print "Packet: Remote AT Command Response\n";
	local ($bytecount) = ord(@$aref[1])+ord(@$aref[2])+4;
        local ($frameid) = sprintf('%02X',ord(@$aref[4]));
        local ($SH) = sprintf('%02X',ord(@$aref[5])).sprintf('%02X',ord(@$aref[6])).sprintf('%02X',ord(@$aref[7])).sprintf('%02X',ord(@$aref[8]));
        local ($SL) = sprintf('%02X',ord(@$aref[9])).sprintf('%02X',ord(@$aref[10])).sprintf('%02X',ord(@$aref[11])).sprintf('%02X',ord(@$aref[12]));
        local ($remoteaddr) = sprintf('%02X',ord(@$aref[13])).sprintf('%02X',ord(@$aref[14]));
        local ($sentcommand) = chr(ord(@$aref[15])).chr(ord(@$aref[16]));
        local ($commandstatusbyte) = ord(@$aref[17]);
        switch($commandstatusbyte){
                case 0 {$commandstatus = 'OK'}
                case 1 {$commandstatus = 'ERROR'}
                case 2 {$commandstatus = 'Invalid Command'}
                case 3 {$commandstatus = 'Invalid Parameter'}
                case 4 {$commandstatus = 'TX FAILURE'}
                default {$commandstatus = 'UNKNOWN'}
        }
        for($j=18;$j<$bytecount-1;++$j){
                        $datarx .=sprintf('%02X',ord(@$aref[$j]));
			$ascii_datarx .= chr(ord(@$aref[$j]));	 
                }
        local ($checksum) = sprintf('%02X',ord(@$aref[-1]));
        print "Frame ID: $frameid\nSH: $SH\nSL: $SL\nRemote Addr: $remoteaddr\nSent CMD: $sentcommand\nCommand Status: $commandstatus\nData RX: $datarx\tASCII: $ascii_datarx\nChecksum: $checksum\n";
	$returnhash{'Frame_ID'} = $frameid;
	$returnhash{'Serial_High'} = $SH;
	$returnhash{'Serial_Low'} = $SL;
	$returnhash{'Remote_Addr'} = $remoteaddr;
	$returnhash{'Sent_CMD'} = $sentcommand;
	$returnhash{'Data_RX'}[0] = $datarx;
	$returnhash{'Data_RX'}[1] = $ascii_datarx;
	$returnhash{'Checksum'} = $checksum; 
	return %returnhash;
}

#####################################################

sub resolve_param{

	local ($aref) = @_;
	local ($length) = scalar(@$aref);
	local ($return) = '';
		if($length == 2){
			$return = @$aref[1];
		}else{
			for($x=1;$x<$length+1;++$x){
				$return.=@$aref[$x].' ';	
			}
			$return = substr($return,0,-2);
		}
		if($return =~ m/0x/){$return =~ s/\s//;}
	return $return;

}
##############################################
sub prepare_command{

	local ($command) = $_[0];
	local ($param) = $_[1];
	return $command.' '.$param;
}

##############################################

sub at_received{
	local ($ascii_datarx) = '';
        local ($datarx) = '';
        local (%returnhash) = ();
        local($aref) = @_;

	print "Packet: AT Command Response\n";
	local ($bytecount) = ord(@$aref[1])+ord(@$aref[2])+4;
	local ($frameid) = sprintf('%02X',ord(@$aref[4]));
	local ($sentcommand) = chr(ord(@$aref[5])).chr(ord(@$aref[6]));
	local ($commandstatusbyte) = ord(@$aref[7]);
	local ($commandstatus) = '';
        	switch($commandstatusbyte){
                	case 0 {$commandstatus = 'OK';}
                	case 1 {$commandstatus = 'ERROR';}
                	case 2 {$commandstatus = 'Invalid Command';}
                	case 3 {$commandstatus = 'Invalid Parameter';}
                	case 4 {$commandstatus = 'TX FAILURE';}
                	default {$commandstatus = 'UNKNOWN';}
        	}
        	if($sentcommand eq 'ND'){
                	local ($networkaddr) = sprintf('%02X',ord(@$aref[8])).sprintf('%02X',ord(@$aref[9]));
                	local ($SH) = sprintf('%02X',ord(@$aref[10])).sprintf('%02X',ord(@$aref[11])).sprintf('%02X',ord(@$aref[12])).sprintf('%02X',ord(@$aref[13]));
                	local ($SL) = sprintf('%02X',ord(@$aref[14])).sprintf('%02X',ord(@$aref[15])).sprintf('%02X',ord(@$aref[16])).sprintf('%02X',ord(@$aref[17]));
                	local ($nodeid) = '';
                	local ($devicetype,$devicestatus);
                	local ($count) = 0;
                        	for($i=18;$i<$bytecount;++$i){
                                	$count = $i;
                                	last if(ord(@$aref[$i]) == 0);
                                	$nodeid = $nodeid.chr(ord(@$aref[$i]));
                        	}
                	local ($parentaddr) = sprintf('%02X',ord(@$aref[$count+1])).sprintf('%02X',ord(@$aref[$count+2]));

                        	switch(ord(@$aref[$count+3])){
                                	case 0 {$devicetype = 'COORDINATOR';}
                                	case 1 {$devicetype = 'ROUTER';}
                                	case 2 {$devicetype = 'END';}
                                	default {$devicetype = 'Device Type Not Identifiable';}

                        	}

                        	switch(ord(@$aref[$count+4])){
                                	case 0 {$devicestatus = 'OK';}
                                	case 1 {$devicestatus = 'ERROR';}
                                	case 2 {$devicestatus = 'Invalid Command';}
                        	}
                	my $profileid = sprintf('%02X',ord(@$aref[$count+5])).sprintf('%02X',ord(@$aref[$count+6]));	
			print "Frame ID: $frameid\nAT Command: $sentcommand\nNetwork Address: $networkaddr\nSH: $SH\nSL: $SL\nNode ID: $nodeid\nParent Addr: $parentaddr\n";
                	print "Device Type: $devicetype\nDevice Status: $devicestatus\nProfile ID: $profileid\n";
			
			$returnhash{'Length'} = $bytecount;
			$returnhash{'Frame_ID'} = $frameid;
			$returnhash{'Sent_CMD'} = $sentcommand;
			$returnhash{'Net_Addr'} = $networkaddr;
			$returnhash{'Serial_High'} = $SH;
			$returnhash{'Serial_Low'} = $SL;
			$returnhash{'Node_ID'} = $nodeid;
			$returnhash{'Parent_Addr'} = $parentaddr;
			$returnhash{'Device_Type'} = $devicetype;
			$returnhash{'Device_Status'} = $devicestatus;
			$returnhash{'Profile_ID'} = $profileid;

		}else{

			local ($checksum) = '';
                	$datarx = '';
                	$ascii_datarx = '';
                		for($j=8;$j<$bytecount-1;++$j){
                        		$datarx .=sprintf('%02X',ord(@$aref[$j]));
                        		$ascii_datarx .= chr(ord(@$aref[$j]));
                		}
                	$checksum = sprintf('%02X',ord(@$aref[-1]));
        		print "Frame ID: $frameid\nAT Command: $sentcommand\nCommand Status: $commandstatus\nData Received: $datarx\tASCII_RX: $ascii_datarx\nChecksum: $checksum\n";
			
			$returnhash{'Length'} = $bytecount;
                        $returnhash{'Frame_ID'} = $frameid;
                        $returnhash{'Sent_CMD'} = $sentcommand;
			$returnhash{'Command_Status'} = $commandstatus;
			$returnhash{'Data_RX'}[0] = $datarx;
			$returnhash{'Data_RX'}[1] = $ascii_datarx;
			$returnhash{'Checksum'} = $checksum;
		}
	return %returnhash;
}

###########################################################################

sub helpOptions{
        print "\nThis program is used to interact with Xbee-ZB modules.  Coordinator API should be USB... See serial.config to configure.\nOPTIONS\n--search\t\tSends an 'ND' AT command for node discovery, will list all Xbee's with same PANID\n--packet\t\tcreate custom packet of your own, DO NOT ADD CHECKSUM, this will be calculated for you\n--coord\t\t\tGet pertinent information about Coordinator plugged into USB\n--mysqlw\t\tAttempt to write new values in DB(if exists, will not update)\n--mysqlu\t\tUsed to update current mysql tables if applicable\n--remote\t\tThis is going to be a remote AT command\n--device\t\tinput the SL of the remote device (this command works best if MYSQL updated\n--comand\t\tAT command to send\n--param\t\tSend a parameter\n**IMPORTANT, for hex values type '0xHH' for remote AT\n--graph\t\tOption to use RRDtool graph\n--help\t\tFor this menu\n-h\t\tFor this menu\n\nEXAMPLES\nGET COORDINATOR INFO\n./beehive --coord\nSearch network and update MYSQL\n./beehive --search --mysqlu\nSend remote command\n./beehive --remote --device <SerialLow of device> --command <AT> --param [optional] <parameter, hex or ascii>\nCreate RRD database for certain command\n./beehive [--local|--remote] [--device SL] --command <AT> --RRDcreate\nUpdate RRD for command\n./beehive [--local|--remote] [--device SL] --command <AT> --RRDupdate\nGraph data from database\n./beehive --graph --device [Local|SL] --command <AT> --start <rrd syntax> --end <rrd syntax>\n\n\nHappy Buzzing...\n";

}

sub exitprog{
        print "\nNothing more to do, exiting now...\n\n";
        exit;
}

##############################################################

sub DATA_IO_RX{
	
        local ($ascii_datarx) = '';
        local ($datarx) = '';
	local ($DIO_High) = '';
        local (%returnhash) = ();
        local($aref) = @_;
        print "Packet: Digital IO Received\n";
        local ($bytecount) = ord(@$aref[1])+ord(@$aref[2])+4;
        local ($SH) = sprintf('%02X',ord(@$aref[4])).sprintf('%02X',ord(@$aref[5])).sprintf('%02X',ord(@$aref[6])).sprintf('%02X',ord(@$aref[7]));
        local ($SL) = sprintf('%02X',ord(@$aref[8])).sprintf('%02X',ord(@$aref[9])).sprintf('%02X',ord(@$aref[10])).sprintf('%02X',ord(@$aref[11]));
        local ($remoteaddr) = sprintf('%02X',ord(@$aref[12])).sprintf('%02X',ord(@$aref[13]));
	local ($RX_Options) = ord(@$aref[14]);
		switch($RX_Options){
			case 1 {$RX_Options = 'Packet Acknowledged'}
			case 2 {$RX_Options = 'Packet Broadcast'}
		}
	local ($numsamples) = sprintf('%02X',ord(@$aref[15]));
	local ($DIO_H) = ord(@$aref[16]);
		switch($DIO_H){
			case 1 {$DIO_High = 'D9'}
			case 2 {$DIO_High = 'D10'}
			case 3 {$DIO_High = 'D9:D10'}
			case 4 {$DIO_High = 'D11'}
			case 5 {$DIO_High = 'D9:D11'}
			case 6 {$DIO_High = 'D10:D11'}
			case 7 {$DIO_High = 'D9:D10:D11'}
			case 8 {$DIO_High = 'D12'}
			case 9 {$DIO_High = 'D9:D12'}
			case 10 {$DIO_High = 'D9:D12'}
			case 11 {$DIO_High = 'D9:D10:D12'}
			case 12 {$DIO_High = 'D11:D12'}
			case 13 {$DIO_High = 'D9:D11:D12'}
			case 14 {$DIO_High = 'D10:D11:D12'}
			case 15 {$DIO_High = 'D9:D10:D11:D12'}
		}
	local ($DIO_L) = ord(@$aref[17]);
		switch($DIO_L){
			case 1 {$DIO_Low = 'D0'}
                        case 2 {$DIO_Low = 'D1'}
                        case 3 {$DIO_Low = 'D0:D1'}
                        case 4 {$DIO_Low = 'D2'}      
                        case 5 {$DIO_Low = 'D0:D2'}   
                        case 6 {$DIO_Low = 'D1:D2'}
                        case 7 {$DIO_Low = 'D0:D1:D2'}
                        case 8 {$DIO_Low = 'D3'}      
                        case 9 {$DIO_Low = 'D0:D3'}   
                        case 10 {$DIO_Low = 'D1:D3'}  
                        case 11 {$DIO_Low = 'D0:D1:D3'}
                        case 12 {$DIO_Low = 'D2:D3'}
                        case 13 {$DIO_Low = 'D0:D1:D3'}
                        case 14 {$DIO_Low = 'D1:D2:D3'}
                        case 15 {$DIO_Low = 'D0:D1:D2:D3'}
                        default {$DIO_Low = '00'}
		}
	local ($AIO_RX) = ord(@$aref[18]);
			 switch($AIO_RX){
                        case 1 {$AIO= 'A0'}
                        case 2 {$AIO= 'A1'}
                        case 3 {$AIO= 'A0:A1'}
                        case 4 {$AIO= 'A2'} 
                        case 5 {$AIO= 'A0:A2'} 
                        case 6 {$AIO= 'A1:A2'}
                        case 7 {$AIO= 'A0:A1:A2'}
                        case 8 {$AIO= 'A3'} 
                        case 9 {$AIO= 'A0:A3'} 
                        case 10 {$AIO= 'A1:A3'} 
                        case 11 {$AIO= 'A0:A1:A3'}
                        case 12 {$AIO= 'A2:A3'}
                        case 13 {$AIO= 'A0:A1:A3'}
                        case 14 {$AIO= 'A1:A2:A3'}
                        case 15 {$AIO= 'A0:A1:A2:A3'}
                        default {$AIO= '00'}
                }
	local ($DIO_data) = sprintf('%02X',ord(@$aref[19])).sprintf('%02X',ord(@$aref[20]));
	local ($AIO_Data) = '';
		for($j=21;$j<$bytecount-1;++$j){

			$AIO_Data .=sprintf('%02X',ord(@$aref[$j]));
		}
	print "SH: $SH\nSL: $SL\nRemote Addr: $remoteaddr\nRX Options: $RX_Options\nDigital Pins: $DIO_High $DIO_Low\n Analog Pins: $AIO\nDigital Data: $DIO_data\nAnalog Data: $AIO_Data\t";	


}

sub be_verbose{

	local($rxdata) = $_[0];
	local($length) = length($rxdata);
	local($sentcmd) = $_[1];
		
		if($sentcmd eq 'IS'){
			local ($DIO_High,$DIO_Low,$AIO) = '00';
			local ($datasamples) = substr($rxdata,0,2);
			local ($DIO_H) = hex(substr($rxdata,2,2));
                switch($DIO_H){
                        case 1 {$DIO_High = 'D9'}
                        case 2 {$DIO_High = 'D10'}
                        case 3 {$DIO_High = 'D9:D10'}
                        case 4 {$DIO_High = 'D11'}
                        case 5 {$DIO_High = 'D9:D11'}
                        case 6 {$DIO_High = 'D10:D11'}
                        case 7 {$DIO_High = 'D9:D10:D11'}
                        case 8 {$DIO_High = 'D12'}
                        case 9 {$DIO_High = 'D9:D12'}
                        case 10 {$DIO_High = 'D9:D12'}
                        case 11 {$DIO_High = 'D9:D10:D12'}
                        case 12 {$DIO_High = 'D11:D12'}
                        case 13 {$DIO_High = 'D9:D11:D12'}
                        case 14 {$DIO_High = 'D10:D11:D12'}
                        case 15 {$DIO_High = 'D9:D10:D11:D12'}
                }
		 	local ($DIO_L) = hex(substr($rxdata,4,2));
                switch($DIO_L){
                        case 1 {$DIO_Low = 'D0'}
                        case 2 {$DIO_Low = 'D1'}
                        case 3 {$DIO_Low = 'D0:D1'}
                        case 4 {$DIO_Low = 'D2'}
                        case 5 {$DIO_Low = 'D0:D2'}
                        case 6 {$DIO_Low = 'D1:D2'}
                        case 7 {$DIO_Low = 'D0:D1:D2'}
                        case 8 {$DIO_Low = 'D3'}
                        case 9 {$DIO_Low = 'D0:D3'}
                        case 10 {$DIO_Low = 'D1:D3'}
                        case 11 {$DIO_Low = 'D0:D1:D3'}
                        case 12 {$DIO_Low = 'D2:D3'}
                        case 13 {$DIO_Low = 'D0:D1:D3'}
                        case 14 {$DIO_Low = 'D1:D2:D3'}
                        case 15 {$DIO_Low = 'D0:D1:D2:D3'}
                }
        		local ($AIO_RX) = hex(substr($rxdata,6,2));
                         switch($AIO_RX){
                        case 1 {$AIO= 'A0'}
                        case 2 {$AIO= 'A1'}
                        case 3 {$AIO= 'A0:A1'}
                        case 4 {$AIO= 'A2'}
                        case 5 {$AIO= 'A0:A2'}
                        case 6 {$AIO= 'A1:A2'}
                        case 7 {$AIO= 'A0:A1:A2'}
                        case 8 {$AIO= 'A3'}
                        case 9 {$AIO= 'A0:A3'}
                        case 10 {$AIO= 'A1:A3'}
                        case 11 {$AIO= 'A0:A1:A3'}
                        case 12 {$AIO= 'A2:A3'}
                        case 13 {$AIO= 'A0:A1:A3'}
                        case 14 {$AIO= 'A1:A2:A3'}
                        case 15 {$AIO= 'A0:A1:A2:A3'}
                }
		local($DHactive,$DLactive,$AIOactive) = 'No Information';	
		if($DIO_High ne '00'){
			if(hex(substr($rxdata,8,2)) == 0){
				$DHactive = 'Digital Pins Low';
			}
		}
		
		if($DIO_low ne '00'){
			if(hex(substr($rxdata,10,2)) == 0){
				$DLactive = 'Digital Pins Low';
			}
			switch(hex(substr($rxdata,10,2))){
                        case 1 {$DLactive= 'D0 High'}
                        case 2 {$DLactive= 'D1 High'}
                        case 3 {$DLactive= 'D0:D1 High'}
                        case 4 {$DLactive= 'D2 High'}
                        case 5 {$DLactive= 'D0:D2 High'}
                        case 6 {$DLactive= 'D1:D2 High'}
                        case 7 {$DLactive= 'D0:D1:D2 High'}
                        case 8 {$DLactive= 'D3 High'}
                        case 9 {$DLactive= 'D0:D3 High'}
                        case 10 {$DLactive= 'D1:D3 High'}
                        case 11 {$DLactive= 'D0:D1:D3 High'}
                        case 12 {$DLactive= 'D2:D3 High'}
                        case 13 {$DLactive= 'D0:D1:D3 High'}
                        case 14 {$DLactive= 'D1:D2:D3 High'}
                        case 15 {$DLactive= 'D0:D1:D2:D3 High'}
                	}	
		}
		local($analogdata) = '';	
			if($AIO ne '00'){
				$analogdata = substr($rxdata,12,4);	
			}	
			
		print "\n\nVerbose Output for $sentcmd that is $length bytes long...\n\nHigh Digital Pins Active: $DIO_High\nLow Digital Pins Active: $DIO_Low\nAnalog Pins Active: $AIO\nHigh Digital Pins Status: $DHactive\nLow Digital Pins Status: $DLactive\nAnalog Data: $analogdata\n\nEND VERBOSE OUTPUT\n";

		}else{
			print "\n\nVerbose not available for this command\n";
		}	

}

sub write_rx_log{
	local ($aref) = @_;
	local ($file) = &get_rx_log();
	local ($bytecount) = ord(@$aref[1])+ord(@$aref[2])+4;
	local ($time) = time();
	  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time);
	$year+=1900;
	local ($asciitime) = "$hour:$min:$sec $mon-$mday-$year";
	open FILE, ">>$file" or die $!;
	print FILE "$bytecount bytes received at ($time-$asciitime): [";
		for($k=0;$k<$bytecount;++$k){
        		$hex = sprintf('%02X',ord(@$aref[$k]));
			print FILE " $hex ";
		}
		print FILE "]\n";
		close(FILE);
		return 1;
}

sub analyze_return{
	local ($aref) = @_;
	local (%returnhash);
	local ($hashref,$startbyte,$reflength,$type);
	local ($hexref) = sprintf('%02X',ord(@$aref[3]));
	local (%hexframetypes) = &hash_reverse_frametype();
	local ($profiles_dir) = &get_frametype_profiles_dir();
	local ($command_profiles_dir) = &get_command_profiles_dir();
	local ($file) = $hexframetypes{$hexref}.'.bee';
	local ($returnvalue) = '';
	local ($endspot) = 0;
	local ($skipflag) = 0;
	$file = $profiles_dir.$file;
		open FILE, "<", $file or print "No such file or directory at $file\n";
		local ($skip) =0;
			while(<FILE>){
				if($skip != 0){
					($hashref,$startbyte,$reflength,$type) = split(/:/,$_);
						$type = substr($type,0,-1);
								if($type =~ m/\?/){
									($returnoptions,$endspot) = &handle_options($aref,$startbyte,$reflength,$type);
									$returnhash{$hashref} = $returnoptions;
									$skipflag = 1;
								}
									
						if($skipflag == 0){
							switch($type){
								case "DEC" 
									{	local ($dectemp) = 0;
										for($x=$startbyte;$x<$startbyte+$reflength;++$x){
											$dectemp += ord(@$aref[$x]);	 
										}
										if($hashref eq 'Length'){
											$returnhash{$hashref} = $dectemp+4; #must account for startbyte, 2length byte, checksum
										}else{
											$returnhash{$hashref} = $dectemp;	
											}
										$endspot = $startbyte+$reflength;
									}
								
								case "HEX" 
									{	local($temphex) = '';

										for($x=$startbyte;$x<$startbyte+$reflength;++$x){
											$temphex .=sprintf('%02X',ord(@$aref[$x]));	
										}
										$returnhash{$hashref} = $temphex;
										$endspot = $startbyte+$reflength;
									}
								
								case "CHAR"
									{	local ($tempchar) = '';
										for($x=$startbyte;$x<$startbyte+$reflength;++$x){
                                                                                        $tempchar .=chr(ord(@$aref[$x]));
                                                                                }
                                                                                $returnhash{$hashref} = $tempchar;
										$endspot = $startbyte+$reflength;
									}

							}
					}#for if options... 	
				}
			++$skip;
			$skipflag = 0;	
			}
			close(FILE);
			
			if(!exists $returnhash{'Length'}){  #error checking, see if config file written correctly...
				return 0;
			}
			if(!exists $returnhash{'Serial_Low'}){
				$returnhash{'Serial_Low'} = "Local";
			}
			if($hexref eq '92'){
				$returnhash{'Sent_CMD'} = "IS";
			}
			
			###############LOAD COMMAND PROFILE######################
				$profile_file = $command_profiles_dir.$returnhash{'Serial_Low'}.'/'.$returnhash{'Sent_CMD'}.'.bee';
					if(-e $profile_file){
						open FILE, "<", $profile_file;
					}else{
					&create_profile($returnhash{'Serial_Low'});
				$file = $command_profiles_dir.'default/'.$returnhash{'Sent_CMD'}.'.bee';
				local($errcmd) = $returnhash{'Sent_CMD'};
				open FILE, "<", $file or print "No such file $file\nAdd a profile for $errcmd\n\n";
					}
				local ($skip) =0;
                        while(<FILE>){
                                if($skip != 0){
                                        ($hashref,$startbyte,$reflength,$type) = split(/:/,$_);
                                                $type = substr($type,0,-1);
								if($startbyte eq '^'){
                                                                        $startbyte = $endspot;
                                                                }
								if($reflength eq '#'){
									$reflength = $returnhash{'Length'}-$startbyte-1;	
								}
								if($hashref eq 'Node_ID'){
								($returnvalue,$endspot) = &get_node_id($aref,$startbyte,$returnhash{'Length'},$type);	
									$returnhash{$hashref} = $returnvalue;
									$skipflag = 1;
								}
                                                                if($type =~ m/\?/ && $skipflag == 0){
                                                                        ($returnvalue,$endspot) = &handle_options($aref,$startbyte,$reflength,$type);
                                                                        $returnhash{$hashref} = $returnvalue;
									$skipflag = 1;
                                                                }
								if($type =~ m/\&/ && $skipflag == 0){
									($returnvalue,$endspot) = &handle_math($aref,$startbyte,$reflength,$type);
                                                                        $returnhash{$hashref} = $returnvalue;
                                                                        $skipflag = 1;
								}
										
								
							if($skipflag == 0){	
                                                        switch($type){
                                                                case "DEC"
									{	local($temphex) = '';

                                                                                for($x=$startbyte;$x<$startbyte+$reflength;++$x){
                                                                                        $temphex .=sprintf('%02X',ord(@$aref[$x]));
                                                                                }
                                                                                $returnhash{$hashref} = hex($temphex);
										$endspot = $startbyte+$reflength;
                                                                        }
                                                                
                                                                case "HEX" 
                                                                        {       local($temphex) = '';

                                                                                for($x=$startbyte;$x<$startbyte+$reflength;++$x){
                                                                                        $temphex .=sprintf('%02X',ord(@$aref[$x]));
                                                                                }
                                                                                $returnhash{$hashref} = $temphex;
										$endspot = $startbyte+$reflength;
                                                                        }

                                                                case "CHAR"
                                                                        {       local ($tempchar) = '';
                                                                                for($x=$startbyte;$x<$startbyte+$reflength;++$x){
                                                                                        $tempchar .=chr(ord(@$aref[$x]));
                                                                                }
                                                                                $returnhash{$hashref} = $tempchar;
										$endspot = $startbyte+$reflength;
                                                                        }

                                                        }
                                        }#for if options...     
                                }
			$skipflag = 0;
                        ++$skip;	
		}
		if($returnhash{'Higher_Digital_Pins'} eq "00" && $returnhash{'Lower_Digital_Pins'} eq "00"){
			$returnhash{'Analog_Data'} = $returnhash{'Digital_Data'};
			delete $returnhash{'Digital_Data'};
		}
		$returnhash{'Checksum'} = sprintf('%02X',ord(@$aref[-1]));
		close(FILE);
		foreach my $key (sort(keys %returnhash)){
			print $key.' : '.$returnhash{$key};print "\n";
		}print "\n";	
	return %returnhash;
}

sub handle_math{
	
	local ($aref) = $_[0];
        local ($startbyte) = $_[1];
        local ($reflength) = $_[2];
        local ($type) = $_[3];
        local ($returnvalue);
        local (%optionshash);
        local ($options,@cases);
        local ($endspot) = 0;
                ($type,$options) = split(/\&/,$type);
                @cases = split(/\,/,$options);
				switch($type){
                                                                case "DEC"
                                                                        {       local($temphex) = '';

                                                                                for($x=$startbyte;$x<$startbyte+$reflength;++$x){
                                                                                        $temphex .=sprintf('%02X',ord(@$aref[$x]));
                                                                                }
                                                                                $temphex = hex($temphex);
											for($i=0;$i<scalar(@cases);++$i){
												switch($cases[$i]){
														
														case "\+" 
															{
																++$i;
																$temphex+=$cases[$i];	
															}
														case "\-"       
                                                                                                                        {
                                                                                                                                ++$i;
                                                                                                                                $temphex-=$cases[$i];
                                                                                                                        }
														case "\*"       
                                                                                                                        {
                                                                                                                                ++$i;
                                                                                                                                $temphex*=$cases[$i];
                                                                                                                        }
														case "\/"       
                                                                                                                        {
                                                                                                                                ++$i;
                                                                                                                                $temphex=int($temphex/$cases[$i]);
                                                                                                                        }	
													
												}	
											}
                                                                                $returnvalue = $temphex;
                                                                                $endspot = $startbyte+$reflength;
                                                                        }

                                                                case "HEX"
                                                                        {       local($temphex) = '';

                                                                                for($x=$startbyte;$x<$startbyte+$reflength;++$x){
                                                                                        $temphex .=sprintf('%02X',ord(@$aref[$x]));
                                                                                }
										$temphex = hex($temphex);
											for($i=0;$i<scalar(@cases);++$i){
                                                                                                switch($cases[$i]){

                                                                                                                case "\+"
                                                                                                                        {
                                                                                                                                ++$i;
                                                                                                                                $temphex+=$cases[$i];
                                                                                                                        }
                                                                                                                case "\-"
                                                                                                                        {
                                                                                                                                ++$i;
                                                                                                                                $temphex-=$cases[$i];
                                                                                                                        }
                                                                                                                case "\*"
                                                                                                                        {
                                                                                                                                ++$i;
                                                                                                                                $temphex*=$cases[$i];
                                                                                                                        }
                                                                                                                case "\/"
                                                                                                                        {
                                                                                                                                ++$i;
                                                                                                                                $temphex=int($temphex/$cases[$i]);
                                                                                                                        }

                                                                                                }
                                                                                        }
										$returnvalue = sprintf('%X',$temphex);
                                                                                $endspot = $startbyte+$reflength;
                                                                        }

						}
		return ($returnvalue,$endspot);
}

	
sub handle_options{

	local ($aref) = $_[0];
	local ($startbyte) = $_[1];
	local ($reflength) = $_[2];
	local ($type) = $_[3];
	local ($returnvalue);
	local (%optionshash);
	local ($options,@cases);
	local ($endspot) = 0;
	local ($case,$value,$math);
	local (@cases,@maths);
	local ($mathflag) = 0;
	
		($type,$options) = split(/\?/,$type);
		@cases = split(/\|/,$options);
			for($i=0;$i<scalar(@cases);++$i){
					if($cases[$i] =~ m/\&/){
						($cases[$i],$math) = split(/\&/,$cases[$i]);
						$mathflag = 1;
					}
						
				($case,$value) = split(/\=/,$cases[$i]);
				$optionshash{$case} = $value;	
			}
			
			if($mathflag == 1){
				@maths = split(/\,/,$math);	
			}
			
		switch($type){
                                                                case "DEC"
                                                                        {       local($temphex) = '';

                                                                                for($x=$startbyte;$x<$startbyte+$reflength;++$x){
                                                                                        $temphex .=sprintf('%02X',ord(@$aref[$x]));
                                                                                }
										$temphex = hex($temphex);
											if($mathflag == 1){
												for($i=0;$i<scalar(@maths);++$i){
                                                                                                switch($maths[$i]){

                                                                                                                case "\+"
                                                                                                                        {
                                                                                                                                ++$i;
                                                                                                                                $temphex+=$maths[$i];
                                                                                                                        }
                                                                                                                case "\-"
                                                                                                                        {
                                                                                                                                ++$i;
                                                                                                                                $temphex-=$maths[$i];
                                                                                                                        }
                                                                                                                case "\*"
                                                                                                                        {
                                                                                                                                ++$i;
                                                                                                                                $temphex*=$maths[$i];
                                                                                                                        }
                                                                                                                case "\/"
                                                                                                                        {
                                                                                                                                ++$i;
                                                                                                                                $temphex=int($temphex/$maths[$i]);
                                                                                                                        }

                                                                                                }
                                                                                        	}	
											}
                                                                                if(exists $optionshash{$temphex}){
                                                                                $returnvalue = $optionshash{$temphex};
                                                                                }else{
                                                                                $returnvalue = $temphex;
                                                                                }
										$endspot = $startbyte+$reflength;	
                                                                        }

                                                                case "HEX"
                                                                        {       local($temphex) = '';

                                                                                for($x=$startbyte;$x<$startbyte+$reflength;++$x){
                                                                                        $temphex .=sprintf('%02X',ord(@$aref[$x]));     
                                                                                }
                                                                                        if($mathflag == 1){
												$temphex = hex($temphex);
                                                                                                for($i=0;$i<scalar(@maths);++$i){
                                                                                                switch($maths[$i]){

                                                                                                                case "\+"
                                                                                                                        {
                                                                                                                                ++$i;
                                                                                                                                $temphex+=$maths[$i];
                                                                                                                        }
                                                                                                                case "\-"
                                                                                                                        {
                                                                                                                                ++$i;
                                                                                                                                $temphex-=$maths[$i];
                                                                                                                        }
                                                                                                                case "\*"
                                                                                                                        {
                                                                                                                                ++$i;
                                                                                                                                $temphex*=$maths[$i];
                                                                                                                        }
                                                                                                                case "\/"
                                                                                                                        {
                                                                                                                                ++$i;
                                                                                                                                $temphex=int($temphex/$maths[$i]);
                                                                                                                        }

                                                                                                }
                                                                                                }
											$temphex = sprintf('%X',$temphex);
                                                                                        }
										if(exists $optionshash{$temphex}){
                                                                                $returnvalue = $optionshash{$temphex};
										}else{
										$returnvalue = $temphex;
										}
										$endspot = $startbyte+$reflength;
                                                                        }
                                                                
                                                                case "CHAR"
                                                                        {       local ($tempchar) = '';
                                                                                for($x=$startbyte;$x<$startbyte+$reflength;++$x){
                                                                                        $tempchar .=chr(ord(@$aref[$x]));
                                                                                }
										if(exists $optionshash{$tempchar}){
                                                                       			$returnvalue = $optionshash{$tempchar}; 
										}else{
											$returnvalue = $tempchar;
										}
											$endspot = $startbyte+$reflength;
									}

                                                        }
	return ($returnvalue,$endspot);	
}	

sub get_node_id{
	local ($aref) = $_[0];
	local ($startbyte) = $_[1];
	local ($bytecount) = $_[2];
	local ($type) = $_[3];
	local ($returnvalue) = '';
	local ($count) = 0;
		 switch($type){
                                                                case "HEX"
                                                                        {       local($temphex) = '';

                                                                                for($x=$startbyte;$x<$bytecount;++$x){
											$count = $x;
                                        						last if(ord(@$aref[$x]) == 0);
                                                                                        $temphex .=sprintf('%02X',ord(@$aref[$x]));
                                                                                }
                                                                                $returnvalue = $temphex;
                                                                        }

                                                                case "CHAR"
                                                                        {       local ($tempchar) = '';
                                                                                for($x=$startbyte;$x<$bytecount;++$x){
											$count = $x;
                                                                                        last if(ord(@$aref[$x]) == 0);
                                                                                        $tempchar .=chr(ord(@$aref[$x]));
                                                                                }
                                                                                        $returnvalue = $tempchar;
                                                                        }

                                                        }
							$count+=1;
        return ($returnvalue,$count);
}

sub mysql_write{
	local (%hash) = @_;
	local ($query) = 'insert into network_devices(Serial_High,Serial_Low,Net_Addr,Device_Type,Node_ID,Parent_Addr,Profile_ID,Manufacturer_ID,active)values(\''.$hash{'Serial_High'}.'\',\''.$hash{'Serial_Low'}.'\',\''.$hash{'Net_Addr'}.'\',\''.$hash{'Device_Type'}.'\',\''.$hash{'Node_ID'}.'\',\''.$hash{'Parent_Addr'}.'\',\''.$hash{'Profile_ID'}.'\',\''.$hash{'Manufacturer_ID'}.'\',\'true\')';
	$connect->do($query);
}

sub mysql_update{
	local (%hash) = @_;
	local ($query) = 'UPDATE network_devices set Net_Addr = \''.$hash{'Net_Addr'}.'\' where Serial_Low = \''.$hash{'Serial_Low'}.'\'';
	$connect->do($query);
}

sub rrd_create{
	local ($ISFLAG) = 0;
	local ($command) = $_[0];
	local ($serial) = $_[1];
	local ($name) = '';
	local (@pins);
	local (%rrdhash) = &read_rrd_config($serial);
	local (%commandhash) = &hash_command_reverse();
		if($command =~ m/\,/){			#this assumes that profile has pins entered with comma seperation
			@pins = split(/\,/,$command);
			$ISFLAG = 1;		
		}
	local ($dir) = $rrd_dir.$serial.'/';
	local ($defaultdir) = $rrd_dir.'default/*';
	if(!-e $dir){
		mkdir $dir;
		`cp $defaultdir $dir`;
	}
		if($ISFLAG == 1){
			for($x=0;$x<scalar(@pins);++$x){
				local ($name) = $commandhash{$pins[$x]}[0];
				local ($file) = $dir.$pins[$x].'_'.$serial.'.rrd';
        				if (!-e $file){
        				
        					local ($execution) = 'rrdtool create '.$file.' --start '.$rrdhash{'START'}.' --step '.$rrdhash{'STEP'}.' DS:'.$name.':GAUGE:'.$rrdhash{'WAIT'}.':'.$rrdhash{'RANGE_LOW'}.':'.$rrdhash{'RANGE_HIGH'}.' RRA:'.$rrdhash{'RRA_TYPE'}.':0.5:'.$rrdhash{'PPA'}.':'.$rrdhash{'POINTS'};
        					`$execution`;
        					chmod(0766,$file);
					}
			}
		}else{
	$name = $commandhash{$command}[0];
		if($name eq ''){
			$name = $command;
		}		
	local ($file) = $dir.$command.'_'.$serial.'.rrd';
	if (-e $file){
		print "ERROR: File already exists\n";
		return 0;
	}
	local ($execution) = "rrdtool create $file --start N --step 1 DS:$name:GAUGE:15:0:100000 RRA:MAX:0.5:1:8640";
	`$execution`;
	chmod(0766,$file);
	}
}

sub rrd_update{
	local ($command) = $_[0];
        local ($serial) = $_[1];
	local ($value) = $_[2];
        local ($dir) = $rrd_dir.$serial.'/';
	local (%commandhash) = &hash_command_reverse();
        #local ($name) = $commandhash{$command}[0];
	local ($file) = $dir.$command.'_'.$serial.'.rrd';
		if(-e $file){
			local ($execution) = "rrdtool update $file N:$value";
			`$execution`;
			return 1;
		}
		else{
			print "ERROR: $file not found";
			return 0;
		}	
}

sub create_profile{
	local ($fileref) = $_[0];
	local ($profdir) = &get_command_profiles_dir();
	local ($newdir) = $profdir.$fileref.'/';
		if(!-e $newdir){
			mkdir($newdir);	
		
	local ($defaultdir) = $profdir.'default/*';
	`cp $defaultdir $newdir`;
	}
	
	$newdir = $events_profile_dir.$fileref.'/';
		if(!-e $newdir){
                        mkdir($newdir);

        local ($defaultdir) = $events_profile_dir.'default/*';
        `cp $defaultdir $newdir`;
        }
}

sub rrd_IS{
	local ($serial) = $_[0];
	local ($combineflag) = 0;
	local ($combinedval) = 0;
	local ($combinedname) = '';
	local ($csvpins) = $_[1];
	local ($data) = $_[2];
	local (%storehash);
	local (@pins) = split(/\,/,$csvpins);
	local ($command_profiles_dir) = &get_command_profiles_dir();
	local ($file) = $command_profiles_dir.$serial.'/';
		for($i=0;$i<scalar(@pins);++$i){
			local ($profile) = $file.$pins[$i].'.bee';
			local ($temp) = hex(substr($data,$i*4,4));
			open FILE, "<", $profile;
			local ($skip) = 0;
				while(<FILE>){
					if($skip != 0){
						$_ =~ s/\&//;
						$_ =~ s/\n//;
						local (@maths) = split(/\,/,$_);
							for($x=0;$x<scalar(@maths);++$x){
									switch($maths[$x]){

                                                                                                                case "\+"
                                                                                                                        {
                                                                                                                                ++$x;
																	if(exists $storehash{$maths[$x]}){
																	if($combineflag == 0){
																	$combinedval= $temp+$storehash{$maths[$x]};$combinedname = $pins[$i].$maths[$x];&rrd_create($combinedname,$serial);$combineflag=1;}else{$combinedval+=$storehash{$maths[$x]};}
																	}else{
																if($combineflag == 0){	
                                                                                                                                $temp+=$maths[$x];}else{$combinedval+=$maths[$x];} }
                                                                                                                        }
                                                                                                                case "\-"
                                                                                                                        {
                                                                                                                                ++$x;
																	if(exists $storehash{$maths[$x]}){
																	if($combineflag == 0){
                                                                                                                                        $combinedval=$temp-$storehash{$maths[$x]};$combinedname = $pins[$i].$maths[$x];&rrd_create($combinedname,$serial);$combineflag=1;}else{$combinedval-=$storehash{$maths[$x]};}
                                                                                                                                        }else{
																	if($combineflag == 0){
                                                                                                                                $temp-=$maths[$x];}else{$combinedval-=$maths[$x];} }
                                                                                                                        }
                                                                                                                case "\*"
                                                                                                                        {
                                                                                                                                ++$x;
																	if(exists $storehash{$maths[$x]}){
																	if($combineflag == 0){
                                                                                                                                        $combinedval=$temp*$storehash{$maths[$x]};$combinedname = $pins[$i].$maths[$x];&rrd_create($combinedname,$serial);$combineflag=1;}else{$combinedval*=$storehash{$maths[$x]};}
                                                                                                                                        }else{
																if($combineflag == 0){
                                                                                                                                $temp*=$maths[$x];}else{$combinedval*=$maths[$x];}}
                                                                                                                        }
                                                                                                                case "\/"
                                                                                                                        {
                                                                                                                                ++$x;
																	if(exists $storehash{$maths[$x]}){
																	if($combineflag == 0){
                                                                                                                                        $combinedval=int($temp/$storehash{$maths[$x]});$combinedname = $pins[$i].$maths[$x];&rrd_create($combinedname,$serial);$combineflag=1;}else{$combinedval=int($combinedval/$storehash{$maths[$x]});}
                                                                                                                                        }else{
																	if($combineflag == 0){
                                                                                                                                $temp=int($temp/$maths[$x]);}else{$combinedval = int($combinedval/$maths[$x]);} }
                                                                                                                        }

                                                                                                }	
							}	
					
					
					}
					++$skip;	
				}
			close(FILE);
			$storehash{$pins[$i]} = $temp;
			&rrd_update($pins[$i],$serial,$temp);
			if($combineflag == 1){
				&rrd_update($combinedname,$serial,$combinedval);
			}
		}
		foreach $key (sort(keys %storehash)){
			delete $storehash{$key};
		}
	return 1;		

}

sub check_process{

	local ($range) = 1000;
	local ($cmd) = "ps -ef | grep -c \"beehive_rx.pl\"";
	local ($num) = `$cmd`;
		if($num > 2){
			return 1;	
		}else{
		return 0;
		}
}	


sub cache_events{
	&reset_options();
	local ($refSL) = $_[0];
	local ($sentcmd) = $_[1];
	local ($value) = $_[2];
	local ($file) = $events_profile_dir.$refSL.'/default.evt';
	local (%returnhash);
		if(-e $file){
			open FILE, "<", $file or die $!;
		}else{
			return 0;
		}
	$skip = 0;
		while(<FILE>){
				if($skip !=0){
					local (@bars) = split(/\|/,$_);
						for($i=0;$i<scalar(@bars);++$i){
								%returnhash = &eval_actions($bars[$i],$sentcmd,$value,$refSL);		
						}
				}
			++$skip;	
			}
		close(FILE);
	return %returnhash;
}

sub eval_actions{
	local ($count) = 0;
	local ($colons) = $_[0];
	$colons =~ s/\n//;
	local ($sentcmd) = $_[1];
	local ($value) = $_[2];
	local ($refSL) = $_[3];
	local ($actionflag) = 0;
	local (%returnhash);
	local ($hold) = 0;
	local (@actions) = split(/\:/,$colons);
		for($x=0;$x<scalar(@actions);++$x){
			$hold = $x;
			if($x == 0){
				if($actions[$x] =~ m/\>/){
					$operator = "\>";	
				}elsif($actions[$x] =~ m/\</){
					$operator = "\<";
				}else{
					$operator = "\=";
				}
				local ($command,$compvalue) = split(/$operator/,$actions[$x]);
					$returnhash{'REFVALUE'} = $compvalue;
					$returnhash{'VALUE'} = $value;
					$returnhash{'OPERATOR'} = $operator;
					if($command eq $sentcmd){
						switch($operator){
								case "\>" 
									{
										if($value > $compvalue){
											$actionflag = 1;	
										}	
									}
								case "\<"
									{
									
										if($value < $compvalue){
											$actionflag = 1;	
										}	
									}	
								case "\="
									{
										if($value == $compvalue){
											$actionflag = 1;
										}	
									}	
						
						}
					}
			}
			else{
					if($actionflag == 1){
						local ($keyword,$todo) = split(/\=/,$actions[$x]);
						$returnhash{$keyword} = $todo;
					switch($keyword){
							case "ACTION"
								{
									if($todo =~ m/\#/){
										local($cmd,$param) = split(/\#/,$todo);
										$cmd = &prepare_command($cmd,$param);
										if($refSL eq "Local"){
											local ($packet,$packetlength) = &send_AT_command($cmd);
											local ($sendpacket) = &packpacket($packet,$packetlength);
											$port->write($sendpacket);
											$EVENT_ACTIONS[$count] = $sendpacket;
											++$count;
											$x = $hold;
										}else{
												local ($packet,$packetlength) = &send_remote_AT_command($refSL,$cmd);
												local ($sendpacket) = &packpacket($packet,$packetlength);
												$port->write($sendpacket);
												$EVENT_ACTIONS[$count] = $sendpacket;
												++$count;	
												$x = $hold;
										} 
									}else{
											if($refSL eq "Local"){
												local ($packet,$packetlength) = &send_AT_command($todo);
												local ($sendpacket) = &packpacket($packet,$packetlength);
												$port->write($sendpacket);
												$EVENT_ACTIONS[$count] = $sendpacket;	
												++$count;
												$x = $hold;
											}else{
												local ($packet,$packetlength) = &send_remote_AT_command($refSL,$todo);                                                                                                      local ($sendpacket) = &packpacket($packet,$packetlength);                                                                                                     $port->write($sendpacket);
													$EVENT_ACTIONS[$count] = $sendpacket;
													++$count;	
												$x = $hold;
											}	
										}
								}

							case "DELAY"
								{
									sleep($todo);	
								}		
					}
					}#actionflag		
			}
		}
	if($actionflag == 1){
		print "\n\n";
                print 'Had an event: '.$returnhash{'EVENT'}.' with event level of '.$returnhash{'EVENT_LEVEL'}.' as '.$returnhash{'VALUE'}.' was '.$returnhash{'OPERATOR'}.' '.$returnhash{'REFVALUE'};print "\n";	
	}
	return %returnhash;
}

sub read_rrd_config{
	local ($serial) = $_[0];
	local ($file) = $rrd_dir.$serial.'/rrd.config';
	local ($default) = $rrd_dir.'default/rrd.config';
	local (%returnhash);
	
		if(-e $file){
			open FILE, "<", $file or print "Could not open file resorting to default...";
		}else{
			open FILE, "<", $default or print "$default not found...";}
		$skip = 0;
			while(<FILE>){
				if($skip != 0){
					$_ =~ s/\n//;
					local ($name,$value) = split(/\:/,$_);
					$returnhash{$name} = $value;	
				}
			++$skip;	
			}
		return %returnhash;
}


sub graph_rrd{

	local ($serial) = $_[0];
	local ($cmd) = $_[1];
	local ($start) = $_[2];
	local ($end) = $_[3];
	local ($dsname) = '';
	local (%commandhash) = &hash_command_reverse();	
	$dsname = $commandhash{$cmd}[0];
		if($dsname eq ''){
			$dsname = $cmd;
		}

	local ($filehandle) = "PNG";
	local ($png) = '.png';
	local ($rrd_name) = $cmd.'_'.$serial.'.rrd';
	local ($picname) = $cmd.'_'.$serial.$png;
	local ($rrd_file) = $rrd_dir.$serial.'/'.$rrd_name;
		if(!-e $rrd_file){
			print "File: $rrd_file does not exist";
			return 0;	
		}
	local (%rrdhash) = &read_rrd_config();
	local ($rra_type) = $rrdhash{'RRA_TYPE'};

	local ($graphs_file) = &get_graphs();
	local ($file) = $graphs_file.$serial.'/';
	local ($pic) = $file.$picname;
		if(!-e $file){
			mkdir $file;
		}
		if(!-e $pic){
			`rm -f $pic`;
		}	
	local ($execution) = "rrdtool graph $pic --start $start --end $end -a $filehandle --title=\"$dsname\" 'DEF:x=$rrd_file:$dsname:$rra_type' 'AREA:x#ff0000:$dsname'";
	`$execution`;
}

sub reset_options{
	$MYSQLwrite = '';
	$MYSQLupdate = '';
	$RRDcreate = '';
}

sub get_coord{
	local ($skip) = 0;
	local ($file) = &get_local_config_dir();
        local ($command_type,$command_name,$command_abrv,$currentval);
        open(CONFIG,$file) or die $!;
                while(<CONFIG>){

                        if($skip != 0){
                                ($command_type,$command_name,$command_abrv,$currentval) = split(/:/,$_);
                                $currentval = substr($currentval,0,-1);#removes the \n
				local ($packet,$packetlength) = &send_AT_command($command_abrv);
				local ($sending) = &packpacket($packet,$packetlength);
				$port->write($sending);
                        }

                        ++$skip;
                }
        close(CONFIG) or die $!;	
}

sub update_coord{
	local ($skip) = 0;
	local (%hash) = @_;
	local ($file) = &get_local_config_dir();
	local ($filebak) = "$file.bak";
	local ($tmp) = "$file.tmp";
	local ($command_type,$command_name,$command_abrv,$currentval);
	open OLD, "<", $file or print "Could not open file $file";
	open NEW, ">", $tmp or print "Could not write to $tmp";
		
		while(<OLD>){
				if($skip != 0){
					($command_type,$command_name,$command_abrv,$currentval) = split(/:/,$_);
                                	$currentval = substr($currentval,0,-1);#removes the \n
						if($hash{'Sent_CMD'} eq $command_abrv){
							$currentval = $hash{'Data_RX'};
							print NEW "$command_type:$command_name:$command_abrv:$currentval\n";
						}else{
							print NEW $_;
						}	
				}else{
					print NEW $_;
				}
			++$skip;		
			}
		close(OLD);
		close(NEW);	
	rename($file,$filebak);
	rename($tmp,$file);
			
}

sub get_pins{
	$pins = '1';
	local ($skip) = 0;
        local ($SL) = $_[0];
        local ($file) = &get_command_profiles_dir();
	local ($default) = $file.'default/pins.config';
	$file .= $SL.'/pins.config';
		if(!-e $file){
			$file = $default;
		}
        local ($command_name,$command_abrv,$currentval);
        open FILE, "<", $file or print "Could not open file $file";
                while(<FILE>){
                                if($skip != 0){
                                        ($command_name,$command_abrv,$currentval) = split(/:/,$_);
                                        $currentval = substr($currentval,0,-1);#removes the \n
					local ($packet,$packetlength) = &send_remote_AT_command($SL,$command_abrv);
                                	local ($sending) = &packpacket($packet,$packetlength);
                                	$port->write($sending);
					sleep(1);
                                }
                        ++$skip;
                        }
                close(FILE);
}

sub update_pins{
	local ($skip) = 0;
        local (%hash) = @_;
        local ($file) = &get_command_profiles_dir();
	local ($default) = $file.'default/pins.config';
		$file .= $hash{'Serial_Low'}.'/pins.config';
		if(!-e $file){
			$file = $default;
		}
        local ($filebak) = "$file.bak";
        local ($tmp) = "$file.tmp";
        local ($command_name,$command_abrv,$currentval);
        open OLD, "<", $file or print "Could not open file $file";
        open NEW, ">", $tmp or print "Could not write to $tmp";

                while(<OLD>){
                                if($skip != 0){
                                        ($command_name,$command_abrv,$currentval) = split(/:/,$_);
                                        $currentval = substr($currentval,0,-1);#removes the \n
                                                if($hash{'Sent_CMD'} eq $command_abrv){
                                                        $currentval = $hash{'Data_RX'};
                                                        print NEW "$command_name:$command_abrv:$currentval\n";
                                                }else{
                                                        print NEW $_;
                                                }
                                }else{
                                        print NEW $_;
                                }
                        ++$skip;
                        }
                close(OLD);
                close(NEW);
        rename($file,$filebak);
        rename($tmp,$file);
}

sub get_pins_config{
	local ($skip) = 0;
        local ($SL) = $_[0];
	local (%returnhash);
        local ($file) = &get_command_profiles_dir();
	local ($default) = $file.'default/pins.config';
	$file .= $SL.'/pins.config';
		if(!-e $file){
			$file = $default;
		}
        local (@command_name,@command_abrv,@currentval);
        open FILE, "<", $file or print "Could not open file $file";
                while(<FILE>){
                                if($skip != 0){
                                        ($command_name,$command_abrv,$currentval) = split(/:/,$_);
                                        $currentval = substr($currentval,0,-1);#removes the \n
					$returnhash{$command_abrv}[0] = $command_name;
					$returnhash{$command_abrv}[1] = $currentval;
                                }
                        ++$skip;
                        }
                close(FILE);
	return %returnhash;
			
}

sub postanalysis{
	my (%hash) = @_;
	local ($redirect) = $postcgi->redirect($ENV{'HTTP_REFERER'});
	foreach $key (sort(keys %hash)){
		local ($type,$SL,$cmd,$param) = split(/\./,$key);
			if($cmd eq "updatepins"){
				&get_pins($SL);
				print "Location: $redirect\n\n";
			}elsif($cmd eq "search"){
					if($param eq "mysqlu"){
						$MYSQLupdate = '1';
					}
					if($param eq "mysqlw"){
						$MYSQLwrite = '1';
					}
					local($packet,$packetlength) = &send_AT_command($xbee_commands{'Search_Network'}[0]);
        				local ($hexpacket) = pack("H[$packetlength]",$packet);
        				$port->write($hexpacket);	
					print "Location: $redirect\n\n";
			}elsif($cmd eq "rrd"){
				if($param eq "create"){
				$RRDcreate = 1;
				local ($packet,$packetlength) = &send_remote_AT_command($SL,$hash{$key});
                                        local ($sending) = &packpacket($packet,$packetlength);
                                        $port->write($sending);
					print "Location: $redirect\n\n";
				}elsif($param eq "update"){
				$RRDupdate = 1;
					local ($packet,$packetlength) = &send_remote_AT_command($SL,'IS');
                                        local ($sending) = &packpacket($packet,$packetlength);
                                        $port->write($sending);
					print "Location: $redirect\n\n";
				}else{
					print "Location: $redirect\n\n";
				}
					
			
			}else{
			$cmd = &prepare_command($cmd,$param);
			local ($packet,$packetlength) = &send_remote_AT_command($SL,$cmd);
                                        local ($sending) = &packpacket($packet,$packetlength);
                                        $port->write($sending);
			}
			}
		print "Location: $redirect\n\n";
}

sub read_bee_file{
	local ($SL) = $_[0];
	local ($command) = $_[1];
	local (@return);
	local ($file) = &get_command_profiles_dir();
	$file .= $SL.'/'.$command.'.bee';
		local ($skip) = 0;
		if(-e $file){
			open FILE, "<", $file;
			while(<FILE>){
				if($skip != 0){
					$_ =~ s/\n//;
					(@return) = split(/\:/,$_);
				}
				++$skip;
			}
		}
	return @return;
}

sub read_evt_file{
	local ($file) = &get_events_profiles_dir();
	local ($SL) = $_[0];
	local (@return);
	$file.=$SL.'/default.evt';
	if(-e $file){
		local ($skip) = 0;
			open FILE, "<",$file;
			while(<FILE>){
				if($skip != 0){
					$_ =~ s/\n//;
					@return = split(/\:/,$_);
				}
				++$skip;
			}
	}
	return @return;
}

sub get_command_profiles_contents{
	local ($SL) = $_[0];
	local ($file) = &get_command_profiles_dir();
	local (@return);
	$file .= $SL.'/';
	if(-e $file){
		@return = `ls $file`;
		return @return;
	}else{
		return 0;
	}
}
		
				
		
				
