package CavePainting::Model::Post;
use strict;
use warnings;

use Moo;
use MooX::ClassAttribute;

use DBI;
use POSIX 'strftime';
use Text::Markdown 'markdown';

class_has db => (
  is => 'rw'
);

has id             => (is => 'ro', writer => '_set_id');
has title          => (is => 'rw');
has body           => (is => 'rw');
has slug           => (is => 'ro', writer => '_set_slug');
has created_at     => (is => 'ro', writer => '_set_created_at');
has updated_at     => (is => 'ro', writer => '_set_updated_at');
has is_persisted   => (is => 'ro', default => 0, writer => '_set_persistence');

sub create {
  my $self = shift;
  my $time = strftime("%Y-%m-%d %H:%M:%S", gmtime(time));

  $self->db->do(
    'INSERT INTO posts (title, slug, body, created_at, updated_at) VALUES (?,?,?,?,?)',
    undef,
    $self->title, $self->slug, $self->body, $time, $time
  ) or die $self->db->errstr;

  $self->_set_id($self->db->sqlite_last_insert_rowid());
  $self->_set_persistence(1);
  return $self;
}

sub find {
  my ($class, $id_query) = @_;

  my $result = $class->db->selectrow_hashref(
    'select * from posts where id=?', 
    undef,
    $id_query
  );

  return $class->new(
    id    => $id_query,
    title => $result->{title},
    slug  => $result->{slug},
    body  => $result->{body},
    created_at  => $result->{created_at},
    updated_at  => $result->{updated_at},
    is_persisted => 1
  ) if $result;
}

sub find_by_slug {
  my ($class, $slug_query) = @_;

  my $result = $class->db->selectrow_hashref(
    'select * from posts where slug=?', 
    undef,
    $slug_query
  );

  return $class->new(
    id    => $result->{id},
    title => $result->{title},
    slug  => $result->{slug},
    body  => $result->{body},
    created_at  => $result->{created_at},
    updated_at  => $result->{updated_at},
    is_persisted => 1
  ) if $result;
}

sub timeline {
  my ($class) = @_;
  my @results;

  my @posts = $class->db->selectall_array('select * from posts order by created_at desc');
  foreach my $post (@posts) {
    push @results, $class->new(
      id         => $post->[0],
      title      => $post->[1],
      slug       => $post->[2],
      body       => $post->[3],
      created_at => $post->[4],
      updated_at => $post->[5]
    );
  }

  return @results;
}

sub parsed_body {
  my $self = shift;
  return markdown($self->body);
}

1;
