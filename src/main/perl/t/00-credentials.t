use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
  use_ok('Amazon::Credentials')
    or BAIL_OUT();
}

1;
