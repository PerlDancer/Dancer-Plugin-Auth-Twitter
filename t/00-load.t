#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dancer::Plugin::Auth::Twitter' ) || print "Bail out!
";
}

diag( "Testing Dancer::Plugin::Auth::Twitter $Dancer::Plugin::Auth::Twitter::VERSION, Perl $], $^X" );
