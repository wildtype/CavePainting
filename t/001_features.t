use Test::More;
use Test::Mojo;
use FindBin;
require "$FindBin::Bin/../app.pl";

my $t = Test::Mojo->new;

$t->get_ok('/new', 'Visiting new post page')
  ->status_is(200, 'it gives http status 200 ok')
  ->element_exists('body.new', 'body class for new post')
  ->element_exists('input.post__title[name="post[title]"]', 'post title input exists')
  ->element_exists('input.post__slug[name="post[slug]"]', 'post title input exists')
  ->element_exists('textarea.post__body[name="post[body]"]', 'post body input exists');

$t->get_ok('/archive', 'Visiting archive page')
  ->status_is(200, 'it gives 200 ok');

done_testing();
