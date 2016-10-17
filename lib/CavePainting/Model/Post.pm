package CavePainting::Model::Post;
use strict;
use warnings;

use Moo;
use MooX::ClassAttribute;
use Redis::Fast;
use Text::Textile 'textile';

class_has db => (
  is => 'rw',
  default => sub { Redis::Fast->new }
);

has title       => (is => 'rw');
has body        => (is => 'rw');
has slug        => (is => 'ro');
has created_at  => (is => 'rw');

sub save {
  my $self = shift;
  $self->db->hmset('post:' . $self->slug,
    'title', $self->title,
    'body', $self->body
  );

  $self->db->zadd('post_created_at', $self->created_at, $self->slug);
  $self->db->zadd('updated_at', time,$self->slug);
  return $self;
}

sub update {
  my $self = shift;
  my ($params) = @_;

  $self->title($params->{title}) if $params->{title};
  $self->body($params->{body}) if $params->{body} ;
  $self->created_at($params->{created_at}) if $params->{created_at};

  return $self;
}

sub updated {
  my $self = shift;
  my $updated = undef;
  $updated = $self->db->zscore('updated_at', $self->slug);
  return $updated;
}

sub body_html {
  my $self = shift;
  return textile($self->body);
}

sub create {
  my $class = shift;
  my ($arg) = @_;
  $arg->{created_at} //= time;
  my $obj = $class->new($arg);

  unless ($class->find($arg->{slug})) {
    $obj->save;
    return $obj;
  }

  return undef;
}

sub find {
  my ($class, $slug) = @_;
  my $posted = $class->db->zscore('post_created_at', $slug);
  my $result = $class->db->hmget('post:'.$slug, 'title', 'body');

  return undef if (_is_all_undef(@{$result}));

  my ($title, $body) = @{$result};
  return $class->new(
    {
      slug       =>$slug, 
      created_at => $posted,
      title      =>$title, 
      body       =>$body
    }
  );
}

sub find_all {
  my ($class, $limit) = @_;
  $limit //= 0;
  my @result = ();
  my @slugs = @{$class->db->zrevrange('post_created_at', 0, $limit-1)};

  foreach my $slug (@slugs) {
    my $post = $class->find($slug);
    push @result, $post;
  }

  return @result;
}

sub _is_all_undef {
  return !(scalar grep defined, @_);
}

1;
