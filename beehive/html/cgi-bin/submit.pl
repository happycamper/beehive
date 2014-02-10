#!/usr/bin/perl
use CGI;
$cgi = CGI->new();
%params = $cgi->Vars;
$size = scalar keys %params;

print "Content-type:text/html\n\n";
print $size;
