package Dancer::Plugin::Auth::Twitter;
use strict;
use warnings;

use Dancer ':syntax';
use Dancer::Plugin;
use Carp 'croak';
use Net::Twitter;

our $VERSION = 0.01;

# Net::Twitter singleton, accessible via 'twitter'
my $_twitter;
sub twitter { $_twitter }
register 'twitter' => \&twitter;

# init method, to create the Net::Twitter object
my $consumer_key;
my $consumer_secret;
my $callback_url;

register 'auth_twitter_init' => sub {
    my $config = plugin_setting;
    $consumer_secret = $config->{consumer_secret};
    $consumer_key    = $config->{consumer_key};
    $callback_url    = $config->{callback_url};

    for my $param (qw/consumer_key consumer_secret callback_url/) {
        croak "'$param' is expected but not found in configuration" 
            unless $config->{$param};
    }

    warn "new twitter with $consumer_key , $consumer_secret, $callback_url";

    $_twitter = Net::Twitter->new({ 
        'traits'            => ['API::REST', 'OAuth'],
        'consumer_key'      => $consumer_key, 
        'consumer_secret'   => $consumer_secret,
    });

};

# define a route handler that bounces to the OAuth authentication process
register 'auth_twitter_authenticate_url' => sub {
    if (not defined twitter) {
        croak "auth_twitter_init must be called first";
    }

    my $uri = twitter->get_authorization_url( 
        'callback' => $callback_url
    );

    session request_token        => twitter->request_token;
    session request_token_secret => twitter->request_token_secret;
    session access_token         => '';
    session access_token_secret  => '';

    debug "auth URL : $uri";
    return $uri;
};

get '/auth/twitter/callback' => sub {

    debug "in callback...";

    if (   !session('request_token')
        || !session('request_token_secret')
        || !params->{'oauth_verifier'})
    {
        return send_error 'no request token present, or no verifier';
    }

    my $token               = session('request_token');
    my $token_secret        = session('request_token_secret');
    my $access_token        = session('access_token');
    my $access_token_secret = session('access_token_secret');
    my $verifier            = params->{'oauth_verifier'};

    if (!$access_token && !$access_token_secret) {
        twitter->request_token($token);
        twitter->request_token_secret($token_secret);
        ($access_token, $access_token_secret) = twitter->request_access_token('verifier' => $verifier);

        # this is in case we need to register the user after the oauth process
        session access_token        => $access_token;
        session access_token_secret => $access_token_secret;
    }

    # get the user
    twitter->access_token($access_token);
    twitter->access_token_secret($access_token_secret);

    my $twitter_user_hash;
    eval {
        $twitter_user_hash = twitter->verify_credentials();
    };

    if ($@ || !$twitter_user_hash) {
        core("no twitter_user_hash or error: ".$@);
        return redirect '/fail';
    }

    $twitter_user_hash->{'access_token'} = $access_token;
    $twitter_user_hash->{'access_token_secret'} = $access_token_secret;

    # save the user
    session 'twitter_user'                => $twitter_user_hash;
    session 'twitter_access_token'        => $access_token,
    session 'twitter_access_token_secret' => $access_token_secret,

    debug "got twitter_user : ".to_yaml($twitter_user_hash);
    redirect '/';
};
 
register_plugin;

__END__
=head1 NAME

Dancer::Plugin::Auth::Twitter - Authenticate with Twitter

=head1 SYNOPSIS

    package SomeDancerApp;
    use Dancer ':syntax';
    use Dancer::Plugin::Auth::Twitter;

    auth_twitter_init();

    before sub {
        if (not session('twitter_user')) {
            redirect auth_twitter_authenticate_url;
        }
    };

    get '/' => sub {
        "welcome, ".session('twitter_user')->{'screen_name'};
    };

    get '/fail' => sub { "FAIL" };

    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub function1 {
}

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

Alexis Sukrieh, C<< <sukria at sukria.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer-plugin-auth-twitter at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer-Plugin-Auth-Twitter>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::Auth::Twitter


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer-Plugin-Auth-Twitter>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer-Plugin-Auth-Twitter>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer-Plugin-Auth-Twitter>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer-Plugin-Auth-Twitter/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Alexis Sukrieh.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Dancer::Plugin::Auth::Twitter
