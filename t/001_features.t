use Test::More;
use Test::Mojo;
use FindBin;
use lib "$FindBin::Bin/../lib";
use aliased 'CavePainting::Model::Post';

Post->create({
    title => 'Test title',
    slug  => 'Test slug',
    body  => 'Test body'
});

my $t = Test::Mojo->new('CavePainting');
$t->ua->max_redirects(1);

$t->get_ok('/', 'Visiting homepage')
  ->content_like(qr/Test title/, 'article title displayed');

$t->get_ok('/Test slug', 'visiting test post')
  ->content_like(qr/Test body/, 'article body displayed');

$t->get_ok('/new', 'new post page');

done_testing();
