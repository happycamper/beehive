#!/usr/bin/perl


@dirs = `ls`;



	for($x=0;$x<scalar(@dirs);++$x){
		open FILE, "+<", $dirs[$x];
			$skip = 0;
				while(<FILE>){
						$_ =~ s/Data_RX\:8/Data_RX\:\^/g;		
			print FILE $_;	


				++$skip;
				}
				close(FILE);
		}
