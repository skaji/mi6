use v6;
use Test;
use lib "xt";
use Util;
use File::Temp;

my $r;
$r = mi6 "new";
ok !$r.success;

$r = mi6 "unknown";
ok !$r.success;

my $tempdir = tempdir;
{
    temp $*CWD = $tempdir.IO;
    $r = mi6 "new", "Foo::Bar";
    ok $r.success;
    ok "Foo-Bar".IO.d;
    chdir "Foo-Bar";
    ok $_.IO.e for <.git  .gitignore  .travis.yml  LICENSE  META6.json  README.md  bin  lib  t>;
    ok !"xt".IO.d;
    ok "lib/Foo/Bar.pm6".IO.e;
    $r = mi6 "test";
    ok $r.success;
    like $r.out, rx/All \s+ tests \s+ successful/;

    mkdir "xt";
    "xt/01-fail.t".IO.spurt: q:to/EOF/;
    use Test;
    plan 1;
    ok False;
    EOF
    $r = mi6 "test";
    ok !$r.success;
    like $r.out, rx/Failed/;
}

done-testing;
