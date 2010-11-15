package SomeDancerApp;
use Dancer ':syntax';
use Dancer::Plugin::Auth::Twitter;

set show_errors => 1;
set session => 'Simple';
set logger => "console";
set 'log' => 'core';

set plugins => {
    'Auth::Twitter' => {
        consumer_key => '8Hl2BhunaUuRdVxhqkoS2w',
        consumer_secret => 'W7hID0KRqU2ZHL5hNu8Nr2E1voq9EgFWjtpcEPKQnJw',
        callback_url => 'http://localhost:3000/auth/twitter/callback',
    },
};

auth_twitter_init();

get '/' => sub {
    if (not session('twitter_user')) {
        return redirect(auth_twitter_authenticate_url());
    }
    else {
        return "welcome, ".session('twitter_user')->{'screen_name'};
    }
};

dance;
1;
