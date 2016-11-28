package CavePainting;
use Mojo::Base 'Mojolicious';
use CavePainting::Model::Post;
use FindBin;

has dbconfig => sub {
  my $app = shift;
  return $app->plugin('Config', file => 'config/db.conf');
};

sub startup {
  my $self = shift;
  my $r    = $self->routes;

  $self->plugin('database', dsn => $self->dsn);
  $self->helper(Post => sub { state $Post = 'CavePainting::Model::Post'; });
  $self->Post->db($self->db);

  $self->defaults(layout => 'application');

  $r->get ('/'          )->to('post#index');
  $r->get ('/archive'   )->to('post#archive');
  $r->get ('/new'       );
  $r->get ('/#slug'     )->to('post#show');
  $r->get ('/edit/#slug')->to('post#edit');
  $r->post('/create'    )->to('post#create');
  $r->post('/update'    )->to('post#update');
}

sub dsn {
  my $app = shift;
  my $env = $ENV{CAVEPAINTING_ENV} || 'production';
  my $dbf = $app->dbconfig->{$env};

  return"dbi:SQLite:dbname=$dbf";
};

1;
