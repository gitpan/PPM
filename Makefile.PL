use ExtUtils::MakeMaker;
use Config;
use strict;

my $ppm_version;
VERSION: {
  (eval {require PPM;}) and do {
    unless ($@) {
      $ppm_version = 2;
      last VERSION;
    }
  };
  (eval {require PPM::Config;}) and do {
    unless ($@) {
      $ppm_version = 3;
      last VERSION;
    }
  };
  (eval {require ActivePerl::PPM;}) and do {
    unless ($@) {
      $ppm_version = 4;
      last VERSION;
    }
  };
  $ppm_version = undef;
}

if (defined $ppm_version and $ppm_version != 2) {
  warn <<"DEATH";

Version $ppm_version of PPM was found, which probably indicates
you've installed an ActivePerl binary distribution. To prevent
installation of this (older) PPM version over an ActivePerl PPM
version, I'm going to exit now.
DEATH
  exit 0;
}

my $eu_version = $ExtUtils::MakeMaker::VERSION;
my %opts;
if ($eu_version >= 5.43) {
  $opts{ABSTRACT_FROM} = q{bin/ppm.pl};
  $opts{AUTHOR} = 'Randy Kobes <r.kobes@uwinnipeg.ca>';
}
if ($eu_version > 6.11 ) {
  $opts{NO_META} = 1;
}
WriteMakefile(
	      'NAME'          => 'PPM',
	      'VERSION_FROM'  => 'bin/ppm.pl', # finds $VERSION
	      'EXE_FILES'     => [ "bin/ppm.pl" ],
	      'PREREQ_PM'     => { 'Archive::Tar'     => 1.08,
				   'Compress::Zlib'   => 0,
				   'XML::Parser'      => 2.09,
				   'Archive::Zip'     => 1.02,
				 },
	      'dist'          =>  { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	      clean => {FILES => 'ppm.xml t_conf/ppm.xml'},
	      %opts,
	     );

my $repositories =
  {'5.6' => {
	     'ActiveState' =>
	     {location => 'http://ppm.ActiveState.com/cgibin/PPM/ppmserver.pl?urn:/PPMServer',
	      summaryfile => 'fetch_summary',
	     },
	     'Bribes' =>
	     {location => 'http://www.bribes.org/perl/ppm',
	      summaryfile => 'searchsummary.ppm',
	     },
	     'UWinnipeg' =>
	     {location => 'http://theoryx5.uwinnipeg.ca/cgi-bin/ppmserver?urn:/PPMServer',
	      summaryfile => 'fetch_summary',
	     },
	    },
   '5.8' => {
	     'ActiveState' =>
	     {location => 'http://ppm.activestate.com/PPMPackages/5.8-windows',
	      summaryfile => 'searchsummary.ppm',
	     },
	     'Bribes' =>
	     {location => 'http://www.bribes.org/perl/ppm',
	      summaryfile => 'searchsummary.ppm',
	     },
	     'UWinnipeg' =>
	     {location => 'http://theoryx5.uwinnipeg.ca/ppms',
	      summaryfile => 'searchsummary.ppm',
	     },
	     'Trouchelle' =>
	     {location => 'http://trouchelle.com/ppm',
	      summaryfile => 'searchsummary.ppm',
	     },
	    },
   '5.10' => {
	      'ActiveState' =>
	      {location => 'http://ppm.activestate.com/PPMPackages/5.10-windows',
	       summaryfile => 'searchsummary.ppm',
	      },
	      'Bribes' =>
	      {location => 'http://www.bribes.org/perl/ppm',
	       summaryfile => 'searchsummary.ppm',
	      },
	      'UWinnipeg' =>
	      {location => 'http://cpan.uwinnipeg.ca/PPMPackages/10xx',
	       summaryfile => 'searchsummary.ppm',
	      },
	      'Trouchelle' =>
	      {location => 'http://trouchelle.com/ppm10',
	       summaryfile => 'package.xml',
	      },
	     },
  };

ppm_config();

sub ppm_config {
   my $ppm = 'ppm.xml';
   my ($perl_version);
 PERLV: {
     ($] < 5.008) and do {
       $perl_version = '5.6';
       last PERLV;
     };
     ($] < 5.01) and do {
       $perl_version = '5.8';
       last PERLV;
     };
     $perl_version = '5.10';
   }
   my $reps = $repositories->{$perl_version};

   my %subs = ( '%OSNAME%'    => $Config{osname},
                '%OSVERSION%' => '4,0,0,0',
                '%TEMP%'      => $ENV{TMP} || $ENV{TEMP},
                '%SITELIB%'   => $Config{sitelib},
                '%PERLDIR%'   => $Config{prefix},
		'%INSTDATE%'  => scalar localtime,
              );
   open(PPM, ">$ppm") or die "Cannot open $ppm: $!";
   while(<DATA>) {
     if ($_ =~ /^\s+<PPMPRECIOUS>/) {
       foreach my $name(sort keys %$reps) {
	 my $loc = $reps->{$name}->{location};
	 my $sf = $reps->{$name}->{summaryfile};
	 print PPM << "END";
    <REPOSITORY LOCATION="$loc" NAME="$name" SUMMARYFILE="$sf" />
END
       }
       print PPM $_;
       next;
     }
     foreach my $key (keys %subs) {
       s/$key/$subs{$key}/g;
     }
     print PPM $_;
   }
   close PPM;
}

sub MY::postamble {

my $copy = $^O eq 'MSWin32' ? 'copy ppm.xml blib\lib' : 'cp ppm.xml blib/lib';
my $postamble = '
all ::';

$postamble .= '
	mv blib/script/ppm.pl blib/script/ppm
	mv blib/man1/ppm.pl.1 blib/man1/ppm.1' unless ($^O eq 'MSWin32');

$postamble .= "
	$copy" unless -f "$Config{sitelib}/ppm.xml";

    $postamble;
}

__DATA__
<PPMCONFIG>
    <PPMVER>0,01_01,0,0</PPMVER>
    <PLATFORM CPU="x86" OSVALUE="%OSNAME%" OSVERSION="%OSVERSION%" />
    <OPTIONS BUILDDIR="%TEMP%" CLEAN="1" CONFIRM="1" DOWNLOADSTATUS="16384" FORCEINSTALL="1" IGNORECASE="1" MORE="24" ROOT="" TRACE="0" TRACEFILE="PPM.LOG" VERBOSE="1" />
    <PPMPRECIOUS>Compress-Zlib;Archive-Tar;Digest-MD5;File-CounterFile;Font-AFM;HTML-Parser;HTML-Tree;MIME-Base64;URI;XML-Element;libwww-perl;XML-Parser;SOAP-Lite;PPM;libnet;libwin32</PPMPRECIOUS>
</PPMCONFIG>
