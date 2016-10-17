package CavePainting;
use Mojo::Base 'Mojolicious';
use CavePainting::Model::Post;

sub startup {
  my $self = shift;
  my $r    = $self->routes;

  $self->helper(Post => sub { state $Post = CavePainting::Model::Post->new; });
  $self->defaults(layout => 'application');

  $r->get ('/'          )->to('post#index');
  $r->get ('/archive'   )->to('post#archive');
  $r->get ('/new'       );
  $r->get ('/#slug'     )->to('post#show');
  $r->get ('/edit/#slug')->to('post#edit');
  $r->post('/create'    )->to('post#create');
  $r->post('/update'    )->to('post#update');
}

1;
