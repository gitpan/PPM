use ExtUtils::MakeMaker;

my @program = qw(ppm.pl);

WriteMakefile(
    'NAME'          => 'PPM',
    'VERSION_FROM'  => 'bin/ppm.pl', # finds $VERSION
    'ABSTRACT_FROM' => 'bin/ppm.pl',
    'EXE_FILES'     => [ "bin/ppm.pl" ],
    'AUTHOR'        => 'Murray Nesbitt &lt;murray@ActiveState.com&gt;',
    'PREREQ_PM'     => { 'Archive::Tar'     => 0,
                         'Compress::Zlib'   => 0,
                         'XML::Parser'      => 2.09,
                         'XML::Element'     => 0.10,
                       },
    'dist'          =>  { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);

sub MY::postamble {
my $postamble = '
all ::
	mv blib/script/ppm.pl blib/script/ppm
	mv blib/man1/ppm.pl.1 blib/man1/ppm.1
' unless ($^O eq 'MSWin32');

    $postamble;
}
