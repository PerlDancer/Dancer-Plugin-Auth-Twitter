use strict;
use warnings;

use Dancer::Test;
use HTTP::Request::Common;
use Test::MockObject;
use Test::More import => ['!pass'];

# Mock Net::Twitter
my $twitter = Test::MockObject->new;
$twitter->fake_new('Net::Twitter');
$twitter->set_always(get_authentication_url => 'https://twitter.burp/auth');
$twitter->set_always(request_token => 'request_token');
$twitter->set_always(request_token_secret => 'request_token_secret');
$twitter->set_always(request_access_token => 'request_access_token');
$twitter->set_always(access_token => 'access_token');
$twitter->set_always(access_token_secret => 'access_token_secret');

my %user = (
    id => 'bumblebee',
    access_token => 'abc123',
    access_token_secret => 'def456',
);

$twitter->mock('verify_credentials' => sub {
    return \%user;
});

{
    use Dancer;
    use Dancer::Plugin::Auth::Twitter;

    config->{plugins}->{'Auth::Twitter'} = {
        consumer_key        => 'consumer_key',
        consumer_secret     => 'consumer_secret',
        callback_url        => 'http://localhost:3000/auth/twitter/callback',
        callback_success    => '/success',
        callback_fail       => '/fail',
    };
    config->{session} = 'Simple';

    auth_twitter_init();
     
    hook before => sub {
        return if request->path =~ m{/auth/twitter/callback};

        if (not session('twitter_user')) {
            redirect auth_twitter_authenticate_url;
        }
    };
     
    get '/' => sub {
        'This is index.'
    };

    get '/success' => sub {
        'Welcome, ' . session('twitter_user')->{'screen_name'};
    };
     
    get '/fail' => sub { 'FAIL' };

    true;
}

my $resp;

$resp = dancer_response GET => '/';
response_redirect_location_is $resp, $twitter->get_authentication_url,
    'Unauthenticated access redirects to authentication URL';

ok defined session('request_token'), 'Request token is stored in session';

# Failed authentication
$resp = dancer_response GET => '/auth/twitter/callback?denied=1';
response_redirect_location_is $resp, 'http://localhost/fail',
    'Failed authentication redirects to callback_fail URL';

# Successful authentication
$resp = dancer_response GET => '/auth/twitter/callback?oauth_verifier=1';
response_redirect_location_is $resp, 'http://localhost/success',
    'Successful authentication redirects to callback_success';

is_deeply session('twitter_user'), \%user,
    'Twitter user data is stored in session';

done_testing;
