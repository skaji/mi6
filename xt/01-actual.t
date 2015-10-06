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
{
    temp $*CWD = $tempdir.IO;
    $r = mi6 "new", "Hello";
    chdir "Hello";
    my $meta = from-json( "META6.json".IO.slurp );
    is $meta<description>, "blah blah blah";
    "lib/Hello.pm6".IO.spurt: q:to/EOF/;
    use v6;
    unit module Hello;

    =begin pod

    =head1 NAME

    Hello - This is hello module.

    =head1 DESC

    =end pod
    EOF
    $r = mi6 "build";
    $meta = from-json( "META6.json".IO.slurp );
    is $meta<description>, "This is hello module.";
}

done-testing;
