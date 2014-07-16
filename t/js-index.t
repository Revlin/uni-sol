use Test::More;
use Test::Mojo;
require 'uni-sol.pl';

my $t = Test::Mojo->new;

# Test successful load of the index
#$t->get_ok('/');
#$t->status_is(200);
#
$t->get_ok('/')
  ->status_is(200)
  ->element_exists('#uni-sol')
  ->element_exists('#uni-sol #layer1');

done_testing();
