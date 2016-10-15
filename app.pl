use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/lib" }

use Mojolicious::Lite;
use Redis::Fast;
use aliased 'CavePainting::Post';


get  '/'           => \&index;
get  '/archive'    => \&archive;
get  '/new';
get  '/#slug'      => \&show;
get  '/edit/#slug' => \&edit;
post '/create'     => \&create;
post '/update'     => \&update;

sub index {
  my $c = shift;
  my @posts = Post->find_all;
  $c->stash({posts => \@posts});
  $c->render(template => 'index');
}

sub archive {
  my $c = shift;
  my @posts = Post->find_all;
  $c->stash({posts => \@posts});
  $c->render(template => 'archive');
}

sub create {
  my $c  = shift;
  my $post = Post->create(_post_params($c));

  if ($post) {
    $c->render(text => 'post created: <a href="/'.$post->slug.'">'.$post->title.'</a>');
  }
};

sub update {
  my $c  = shift;
  my $params = _post_params($c);
  my $post = Post->find($params->{slug});
  $post->update($params);

  $c->render(text => 'post created: <a href="/'.$post->slug.'">'.$post->title.'</a>') if $post->save;
};

sub show {
  my $c = shift;
  my $slug = $c->param('slug');

  my $post = Post->find($slug);
  return $c->render(text => '404', status => 404) unless $post;

  $c->stash({post => $post});
  $c->render(template => 'show');
};

sub edit {
  my $c = shift;
  my $slug = $c->param('slug');
  my $post = Post->find($slug);
  $c->stash(post => $post);
  $c->render(template => 'edit');
};


sub _get_obj_params {
  my ($controller, $object_name) = (shift, shift);
  my @param_names = @_;
  my $retval = {};

  foreach my $param_name (@param_names) {
    $retval->{$param_name} = $controller->param($object_name.'['.$param_name.']');
  }

  return $retval;
}

sub _post_params {
  return _get_obj_params(shift, 'post', 'title', 'slug', 'body');
}

app->defaults(layout => 'application');
app->start;
