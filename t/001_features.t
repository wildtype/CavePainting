use Test::More;
use Test::Mojo;
use FindBin;
require "$FindBin::Bin/../app.pl";

my $t = Test::Mojo->new;

$t->get_ok('/new', 'Visiting new post page')
  ->status_is(200, 'it gives http status 200 ok')
  ->text_is('h1' => 'Create a New Post', 'title is "Create a New Post"')
  ->element_exists('input.newpost__title', 'post title input exists')
  ->element_exists('textarea.newpost__body', 'post body input exists');

$t->get_ok('/archive', 'Visiting archive page')
  ->status_is(200, 'it gives 200 ok');

done_testing();
