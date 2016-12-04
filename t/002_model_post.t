use DBI;
use FindBin;
use Mojo::Util 'slurp';
use POSIX 'strftime';
use Test::Spec;
use Test::Time;

use lib "$FindBin::Bin/../lib";
use CavePainting::Model::Post;
use constant Post => 'CavePainting::Model::Post';

my $conf = do "$FindBin::Bin/../config/db.conf";

describe "CavePainting::Model::Post" => sub {
  my $dbh;
  my $post;

  before all => sub {
    $dbh = DBI->connect('DBI:SQLite:dbname=' . $conf->{test}, '', '');
    $dbh->do(slurp "$FindBin::Bin/../db/001_create_table_posts.down.sql");
    $dbh->do(slurp "$FindBin::Bin/../db/001_create_table_posts.up.sql");
    Post->db($dbh);

    $post = Post->new(
      title => 'Test title', 
      slug  => 'test', 
      body  => 'body'
    );
  };

  after all => sub {
    $dbh->do(slurp "$FindBin::Bin/../db/001_create_table_posts.down.sql");
  };

  describe "default values" => sub {
    it "id is undef" => sub {
      is($post->id, undef);
    };

    it "is_persisted is false" => sub {
      isnt($post->is_persisted, 1);
    };

    it "created_at is undef" => sub {
      is($post->created_at, undef);
    };

    it "updated_at is undef" => sub {
      is($post->updated_at, undef);
    };
  };

  describe "#create" => sub {
    my ($result, $time);

    before each => sub {
      $result = sub { return $dbh->selectrow_hashref('select * from posts'); };
      $post->create;
    };

    after each => sub {
      $dbh->do('delete from posts');
    };

    it "saves title data" => sub {
      is($result->()->{title}, 'Test title');
    };

    it "saves body data" => sub {
      is($result->()->{body},  'body');
    };

    it "gives value to id attribute" => sub {
      isnt($post->id, undef);
    };

    it "set is_persisted to true" => sub {
      ok($post->is_persisted);
    };

    it "change and set updated at to when object saved" => sub {
      $time = strftime("%Y-%m-%d %H:%M:%S", gmtime);
      is($result->()->{updated_at}, $time);
    };

    it "set created_at to current time" => sub {
      $time = strftime("%Y-%m-%d %H:%M:%S", gmtime);
      is($result->()->{created_at}, $time);
    };
  };

  describe "#find" => sub {
    my ($id, $post, $time_created, $time_updated);

    describe "when found" => sub {
      before each => sub {
        $time_created = strftime("%Y-%m-%d %H:%M:%S", gmtime);
        sleep 1000;
        $time_updated = strftime("%Y-%m-%d %H:%M:%S", gmtime);

        $dbh->begin_work;
        $dbh->do(
          'INSERT INTO posts (title, slug, body, created_at, updated_at) VALUES (?,?,?,?,?)',
          undef,
          'title', 'slug', 'body', $time_created, $time_updated
        );
        $id = $dbh->sqlite_last_insert_rowid;
        $dbh->commit;

        $post = Post->find($id);
      };

      after each => sub {
        $dbh->do('delete from posts where id=?', undef, $id);
      };

      it "returns post object" => sub {
        ok($post->isa('CavePainting::Model::Post'));
      };

      describe "post object have the right attributes" => sub {
        it "post id" => sub {
          is($post->id, $id);
        };

        it "post title" => sub {
          is($post->title, 'title');
        };

        it "post slug" => sub {
          is($post->slug, 'slug');
        };

        it "post body" => sub {
          is($post->body, 'body');
        };

        it "post created_at" => sub {
          is($post->created_at, $time_created);
        };

        it "post updated_at" => sub {
          is($post->updated_at, $time_updated);
        };

        it "is persisted" => sub {
          ok($post->is_persisted);
        };
      };
    };

    describe "when not found" => sub {
      it "returns undef" => sub {
        $post = Post->find(1);

        is($post, undef);
      };
    };
  };

  describe "#find_by_slug" => sub {
    my ($id, $post, $time_created, $time_updated);

    describe "when found" => sub {
      before each => sub {
        $time_created = strftime("%Y-%m-%d %H:%M:%S", gmtime);
        sleep 1000;
        $time_updated = strftime("%Y-%m-%d %H:%M:%S", gmtime);

        $dbh->begin_work;
        $dbh->do(
          'INSERT INTO posts (title, slug, body, created_at, updated_at) VALUES (?,?,?,?,?)',
          undef,
          'title', 'slug_dicari', 'body', $time_created, $time_updated
        );
        $id = $dbh->sqlite_last_insert_rowid;
        $dbh->commit;

        $post = Post->find_by_slug('slug_dicari');
      };

      after each => sub {
        $dbh->do('delete from posts where id=?', undef, $id);
      };

      it "returns post object" => sub {
        ok($post->isa('CavePainting::Model::Post'));
      };

      describe "post object have the right attributes" => sub {
        it "post id" => sub {
          is($post->id, $id);
        };

        it "post title" => sub {
          is($post->title, 'title');
        };

        it "post slug" => sub {
          is($post->slug, 'slug_dicari');
        };

        it "post body" => sub {
          is($post->body, 'body');
        };

        it "post created_at" => sub {
          is($post->created_at, $time_created);
        };

        it "post updated_at" => sub {
          is($post->updated_at, $time_updated);
        };

        it "is persisted" => sub {
          ok($post->is_persisted);
        };
      };
    };

    describe "when not found" => sub {
      it "returns undef" => sub {
        $post = Post->find_by_slug('slug_tidakada');

        is($post, undef);
      };
    };
  };

  describe "#timeline" => sub {
    before each => sub {
      foreach my $num ('pertama', 'kedua', 'ketiga') {
        my $time_created = strftime("%Y-%m-%d %H:%M:%S", gmtime);
        my $time_updated = strftime("%Y-%m-%d %H:%M:%S", gmtime);
        my $title = 'post '. $num;
        my $slug = 'slug '. $num;

        $dbh->do(
          'INSERT INTO posts (title, slug, body, created_at, updated_at) VALUES (?,?,?,?,?)',
          undef,
          $title, $slug, 'body', $time_created, $time_updated
        );
        sleep 1000;
      }
    };

    it "returns array of post ordered by created desc" => sub {
      my @posts = Post->timeline;
      is($posts[2]->title, 'post ketiga');
      is($posts[1]->title, 'post kedua');
      is($posts[0]->title, 'post pertama');
    };

    after each => sub {
      $dbh->do('delete from posts');
    };
  };

  describe "#parsed_body" => sub {
    it "returns markdown parsed body" => sub {
      my $post = Post->new(body => '*bold*');
      is($post->parsed_body =~ s/^\s+|\s+$//gr, '<p><em>bold</em></p>');
    };
  };
};

runtests unless caller;
