package Apache::RandomLocation;

use Apache::Constants ':common';
use strict;
use vars qw ($VERSION);

$VERSION = '0.01';

=head1 NAME

Apache::RandomLocation - Perl extension for mod_perl to handle random locations.

=head1 SYNOPSIS

  You can use this in your Apache *.conf files to activate this module.

  <Location /scripts/random-image>
  SetHandler perl-script
  PerlSetVar BaseURL /images/
  PerlSetVar ConfigFile /usr/local/apache/etc/sponsors
  PerlHandler Apache::RandomLocation
  </Location>

=head1 DESCRIPTION

Given a list of locations in B<ConfigFile>, this module will instruct the
browser to redirect to one of them given the B<BaseURL>. 

For example, you could use it to implement a banner in an HTML page: 
<IMG SRC=/scripts/random-image>      

B<BaseURL> is where all your image files are located.  B<BaseURL> can be a
full or partial URL.  It almost always terminates in a slash ("/"). 
B<BaseURL> is optional.

B<ConfigFile> is where the list of all the images you want to display are
located.  Images should be listed one per line.  The parser stops reading
after a space is located in the line.  Lines begining with # are ignored.

This module is not really random.  It goes through the entries in
B<ConfigFile> in order.  Because usual multiple copies of httpd running,
continually clicking on the URL that generates the random location will
most likely not lead to seeing the images in order. 

Note: because the counters are global on a per httpd process basis, make
sure your don't set your B<MaxRequestsPerChild> too low, otherwise you'll
keep seeing the same images. 

The module will re-read the B<ConfigFile> after either

	a) each time a new httpd process starts.

	b) it has reached the end of the list of locations.

=head1 BUGS

When starting, the random image program always starts at the start of the
list.  It should start at a random location in the list. 

URLs should be urlencoded before sending them to the browser.

There has been no testing done to see if you can use multiple
Apache::RandomLocation modules in one server (it probably doesn't work
very well because they use the same namespace). 

=head1 AUTHOR

Matthew Darwin, matthew@davin.ottawa.on.ca

=head1 SEE ALSO

perl(1), Apache(3), mod_perl(3)

=cut

sub handler {
	my ($r) = shift;
	my ($baseurl, $configfile, $num, @files);

	return DECLINED unless $configfile = $r->dir_config("ConfigFile");
	$baseurl = "" unless $baseurl = $r->dir_config("BaseURL");
	$num = $main::Apache::RandomLocation::num;

	if ($main::Apache::RandomLocation::files) {
		@files = @{$main::Apache::RandomLocation::files};
	}
	
	if (! defined ($num)) {
		$num = -1;
	} elsif ($num >= $#files) {
		$num = -1;
	}
	if ($num == -1) {
		read_config($r, $configfile) || return DECLINED;
		@files = @{$main::Apache::RandomLocation::files};
	}
	$num++;
	$main::Apache::RandomLocation::num = $num;

	$r->send_cgi_header("Location: $baseurl$files[$num]\r\n\r\n");   
	return OK;
}

sub read_config {
	my ($r, $configfile) = @_;
	my ($file);
	my (@files);

	if (! open (FILE, $configfile)) {
		$r->warn ("Apache::RandomLocation: cannot read config file: $configfile: $!");
		return 0;
	}
	while (<FILE>) {
		next if /^#/;
		next if /^\s*$/;
		($file) = split (/\s+/, $_, 2);
		push (@files, $file);
	}
	close (FILE);

	$main::Apache::RandomLocation::files = \@files;
	return 1;
}

1;
