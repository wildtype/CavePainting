use Test::Spec;
use Test::MockTime ':all';
use RedisDB;
use DateTime;
use aliased 'CavePainting::Post' => 'Post';

describe "Post" => sub {
  describe "#save" => sub {
    my $con = RedisDB->new(database => 1);
    Post->db($con);
    my $post;

    before sub {
      $post = Post->new(
        {
          title      => 'New title',
          body       => 'New body',
          slug       => 'newpost',
          created_at => time
        }
      );
      set_fixed_time(0);
      $post->save;
    };

    after sub {
      $con->del('post:newpost');
      $con->del('post_creates_at');
      $con->del('updated_at');
      restore_time;
    };

    it "save post to redis with provided slug" => sub {
      is($con->hget('post:newpost', 'title'), 'New title');
    };

    it "store created_at time into sorted set `post_created_at`" => sub {
      my $created_at = $post->created_at;
      is($con->zscore('post_created_at', 'newpost'), $created_at);
    };

    it "store updated time into sorted set `updated_at`" => sub {
      is($con->zscore('updated_at', 'newpost'), time);
    };
  };

  describe "#updated" => sub {
    my $post;
    my $con = RedisDB->new(database => 1);

    before sub {
      $post = Post->new(
        {
          title      => 'New title',
          body       => 'New body',
          slug       => 'newpost',
          created_at => time
        }
      );
    };

    after sub {
      $con->del('post:newpost');
      $con->del('post_created_at');
      $con->del('updated_at');
    };

    context "default" => sub {
      it "returns the time when post saved to redis" => sub {
        set_fixed_time(100);
        $post->save;
        restore_time;

        is($post->updated, 100)
      };
    };

    context "unsaved post" => sub {
      it "returns undef on unsaved post" => sub {
        is($post->updated, undef);
      };
    };
  };

  describe ".create" => sub {
    my $con = RedisDB->new(database => 1);

    after sub {
      $con->del('post:newslug');
      $con->del('updated_at');
      $con->del('post_created_at');
    };

    context "default" => sub {
      it "returns new post object with assigned attributes" => sub {
        my $post = Post->create({
            slug       => 'newslug',
            title      => 'judul',
            body       => 'b',
            created_at => time
        });

        is($post->slug, 'newslug');
      };

      it "save new post to redis with new keys" => sub {
        my $created_at = DateTime->now->subtract(hours => 1)->epoch;
        my $post = Post->create({
            slug       => 'newslug',
            title      => 'judul',
            body       => 'b',
            created_at => $created_at
        });

        is($con->hget('post:newslug', 'title'), 'judul');
        is($con->zscore('post_created_at', 'newslug'), $created_at);
      };
    };

    context "posted time is not assigned" => sub {
      it "automatically sets posted time" => sub {
        set_fixed_time(196);
        my $post = Post->create({
            slug   => 'newslug',
            title  => 'judul',
            body   => 'b',
        });
        restore_time;

        is($con->zscore('post_created_at', 'newslug'), 196);
      };
    };

    context "same slug already exists" => sub {
      it "won't save if slug already exists and return undef" => sub {
        Post->create({
            slug       => 'newslug',
            title      => 'judul',
            body       => 'b',
            created_at => time
        });

        my $post = Post->create({
            slug       => 'newslug',
            title      => 'judul2',
            body       => 'b',
            created_at => time
        });

        isnt($con->hget('post:newslug', 'title'), 'judul2');
        is($post, undef);
      };
    };
  };

  describe "#update" => sub {
    context "default" => sub {
      it "sets attributes to new value" => sub {
        my $post = Post->new({title=>'judul awal'});
        $post->update({title=>'judul pengganti', body=>'body'});
        is($post->title, 'judul pengganti');
        is($post->body, 'body');
      };
    };

    context "attribute value not defined in update params" => sub {
      it "keeps original attribute value" => sub {
        my $time = time;
        my $post = Post->new(
          {
            title      => 'judul awal',
            body       => 'body',
            created_at => $time
          }
        );
        $post->update({body => 'body baru'});
        is($post->title, 'judul awal');
        is($post->body, 'body baru');
        is($post->created_at, $time);
      };
    };
  };

  describe "#body_html" => sub {
    it "returns html parsed of body from textile" => sub {
      my $post = Post->new({body=>'h1. header'});
      is($post->body_html, '<h1>header</h1>');
    };
  };

  describe ".find" => sub {
    my $con = RedisDB->new(database => 1);
    Post->db($con);

    describe "when found" => sub {
      my $post;
      my $posted = time;

      before sub {
        $con->hmset('post:pertama1',
          'title', 'Judul Artikel 1',
          'body', 'Body artikel 1',
          'summary', 'Summary artikel 1'
        );

        $con->zadd('post_created_at', $posted, 'pertama1');
        $post = Post->find('pertama1');
      };

      after sub {
        $con->del('post:pertama1');
        $con->del('post_created_at');
        $con->del('updated_at');
      };

      it "return post with correct title" => sub {
        is($post->title, 'Judul Artikel 1');
      };

      it "return post with correct body" => sub {
        is($post->body, 'Body artikel 1');
      };

      it "return post with correct slug" => sub {
        is($post->slug, 'pertama1');
      };

      it "return post with correct timestamp" => sub {
        is($post->created_at, $posted);
      };
    };

    describe "when not found" => sub {
      my $post;

      it "return undef" => sub {
        $post = Post->find('pertama10');
        is($post, undef);
      };
    };
  };

  describe ".find_all" => sub {
    my $con = RedisDB->new(database => 1);
    Post->db($con);
    my @posts;
    my ($posted1, $posted2, $posted3);

    context "when not empty" => sub {
      before sub {
        $posted1 = DateTime->now->subtract(hours => 1)->epoch;
        $posted2 = DateTime->now->subtract(hours => 2)->epoch;
        $posted3 = DateTime->now->subtract(hours => 3)->epoch;
        $con->zadd('post_created_at', $posted1, 'baru');
        $con->zadd('post_created_at', $posted2, 'lama');
        $con->zadd('post_created_at', $posted3, 'lama-banget');

        $con->hmset('post:baru',
          'title', 'baru', 
          'body', 'body baru',
          'summary', 'summary baru'
        );

        $con->hmset('post:lama',
          'title', 'lama', 
          'body', 'body lama',
          'summary', 'summary lama'
        );

        $con->hmset('post:lama-banget',
          'title', 'lama-banget', 
          'body', 'body lama',
          'summary', 'summary lama'
        );
      };

      after sub {
        $con->del('post:baru');
        $con->del('post:lama');
        $con->del('post:lama-banget');
        $con->del('post_created_at');
        $con->del('updated_at');
      };

      context "default" => sub {
        it "returns array of post" => sub {
          @posts = Post->find_all;
          is(scalar @posts, 3);
        };

        it "gives array with newest post first" => sub {
          @posts = Post->find_all;

          is_deeply( [$posts[0]->title, $posts[1]->title],
                     ['baru', 'lama'] );
        };
      };

      context "with limit" => sub {
        it "returns post limited to params" => sub {
          @posts = Post->find_all(2);
          is (scalar @posts, 2);
        };
      };
    };
  };
};

runtests unless caller;
