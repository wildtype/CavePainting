use Mojolicious::Lite;
use Redis::Fast;
use Text::WikiCreole;

my $redis = Redis::Fast->new;

get  '/archive' => sub { shift-> render };
get  '/#slug'   => \&show;
get  '/new';
post '/save'    => \&save;


post '/save' => sub {
  my $c  = shift;
  my $p  = get_params_for($c, 'post', 'title', 'slug', 'body', 'summary');
  my $kp = 'post:'.$p->{slug};

  $redis->set($kp.':title', $p->{title});
  $redis->set($kp.':body:creole', $p->{body});
  $redis->set($kp.':summary:creole', $p->{summary});

  $redis->set($kp.':body:html', swim_parse($p->{body}));
  $redis->set($kp.':summary:html', swim_parse($p->{summary}));

  $c->render(text => 'post created: <a href="/'.$p->{slug}.'">'.$p->{title}.'</a>');
};

get '/archive' => sub {
  shift->render;
};

get '/#slug' => sub {
  my $c = shift;
  my $slug = $c->param('slug');
  my $post = {};
  $post = { 
    title => $redis->get('post:'.$slug.':title'),
    body => $redis->get('post:'.$slug.':body:html'),
    slug => $slug
  };
  $c->stash($post);
  $c->render(template => 'show');
};

get '/edit/#slug' => sub {
  my $c = shift;
  my $slug = $c->param('slug');
  my $post = {};
  $post = { 
    title => $redis->get('post:'.$slug.':title'),
    body => $redis->get('post:'.$slug.':body:creole'),
    summary => $redis->get('post:'.$slug.':summary:creole'),
    slug => $slug
  };
  $c->stash($post);
  $c->render(template => 'edit');
};

app->start;

sub get_params_for {
  my ($controller, $object_name) = (shift, shift);
  my @param_names = @_;
  my $retval = {};

  foreach my $param_name (@param_names) {
    $retval->{$param_name} = $controller->param($object_name.'['.$param_name.']');
  }

  return $retval;
}

sub swim_parse {
  my $text = shift;
  $text =~ s/\r\n/\n/g;
  return creole_parse($text);
}
