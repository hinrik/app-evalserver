use strict;
use warnings FATAL => 'all';
use Test::More tests => 4;

use_ok('App::EvalServer');
use_ok('App::EvalServer::Child');
use_ok('App::EvalServer::Language::Perl');
use_ok('App::EvalServer::Language::Deparse');
