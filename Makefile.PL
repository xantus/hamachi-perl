use warnings;
use strict;

use lib 'lib';

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Hamachi',
    AUTHOR        => 'David Davis <xantus@xantus.org>',
    ABSTRACT      => 'A Perl interface to Hamachi',
    VERSION_FROM  => 'lib/Hamachi.pm', # finds $VERSION
    PREREQ_PM => {
        'Mojo'    => 0.991250,
        'JSON'    => 0,
        'Scalar::Util' => 0,
    },
    dist => {
        COMPRESS  => 'gzip -9f',
        SUFFIX    => 'gz',
    },
);

