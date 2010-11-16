use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Dancer::Plugin::Auth::Twitter',
    AUTHOR              => q{Alexis Sukrieh <sukria@sukria.net>},
    VERSION_FROM        => 'lib/Dancer/Plugin/Auth/Twitter.pm',
    ABSTRACT            => 'Twitter authentication for Dancer applications',
    LICENSE             => 'perl',
    PREREQ_PM => {
        'Test::More'   => 0,
        'Net::Twitter' => 0,
        'Dancer'       => '1.1999_04',
      },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Dancer-Plugin-Auth-Twitter-*' },
);
