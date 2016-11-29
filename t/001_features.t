use Test::More;
use Test::Mojo;
use POSIX 'strftime';
use Mojo::Util 'slurp';

use FindBin;
use lib "$FindBin::Bin/../lib";
use aliased 'CavePainting::Model::Post';

my $time_created = strftime("%Y-%m-%d %H:%M:%S", gmtime);

my $conf = do "$FindBin::Bin/../config/db.conf";
my $dbh = DBI->connect('DBI:SQLite:dbname=' . $conf->{test}, '', '');
$dbh->do(slurp "$FindBin::Bin/../db/001_create_table_posts.down.sql");
$dbh->do(slurp "$FindBin::Bin/../db/001_create_table_posts.up.sql");
Post->db($dbh);


Post->new(
    title => 'Test title',
    slug  => 'Testslug',
    body  => 'Test body',
)->create;

my $t = Test::Mojo->new('CavePainting');
$t->app->Post->db($dbh);

$t->ua->max_redirects(1);

$t->get_ok('/', 'Visiting homepage')
  ->content_like(qr/Test title/, 'article title displayed');

$t->get_ok('/Testslug', 'visiting test post')
  ->content_like(qr/Test body/, 'article body displayed');

$t->get_ok('/new', 'new post page');

$t->post_ok('/create' => form => { "post[title]" => "judul", "post[slug]" => "newslug", "post[body]" => "content whatever" }, 'can create post')
  ->status_is(200)
  ->content_like(qr/post created: .*?judul/);

$t->get_ok('/newslug', 'visit recently created post')
  ->status_is(200)
  ->content_like(qr/content whatever/);

done_testing();
