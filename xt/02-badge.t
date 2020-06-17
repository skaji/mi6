use v6.c;
use Test;

use App::Mi6::Badge;

my $user = "user";
my $repo = "repo";
my $name = "test";

my $m1 = App::Mi6::Badge.new(provider => "travis-ci.org", :$user, :$repo, :$name).markdown();
is $m1, '[![Build Status](https://travis-ci.org/user/repo.svg?branch=master)](https://travis-ci.org/user/repo)';
my $m2 = App::Mi6::Badge.new(provider => "travis-ci.com", :$user, :$repo, :$name).markdown();
is $m2, '[![Build Status](https://travis-ci.com/user/repo.svg?branch=master)](https://travis-ci.com/user/repo)';
my $m3 = App::Mi6::Badge.new(provider => "appveyor", :$user, :$repo, :$name).markdown();
is $m3, '[![Windows Status](https://ci.appveyor.com/api/projects/status/github/user/repo?branch=master&passingText=Windows%20-%20OK&failingText=Windows%20-%20FAIL&pendingText=Windows%20-%20pending&svg=true)](https://ci.appveyor.com/project/user/repo/branch/master)';
my $m4 = App::Mi6::Badge.new(provider => "github-actions", :$user, :$repo, :$name).markdown();
is $m4, '[![Actions Status](https://github.com/user/repo/workflows/test/badge.svg)](https://github.com/user/repo/actions)';

done-testing;
