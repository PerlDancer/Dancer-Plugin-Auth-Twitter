package TwitterApp;
use Dancer ':syntax';
use Dancer::Plugin::Auth::Twitter;

auth_twitter_init();

before sub {
    return if request->path =~ /callback/;

    if (not session('twitter_user')) {
        debug "twitter_user not found in session";
        return redirect(auth_twitter_authenticate_url());
    }
};

get '/' => sub {
    template 'index', {
        'twitter' => session('twitter_user'), 
        'dump' => to_yaml(session('twitter_user'))
    };
};

get '/fail' => sub { to_yaml(session()) };

1;
