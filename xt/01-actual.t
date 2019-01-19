use v6;
use Test;
use lib "xt";
use Util;
use File::Temp;
use JSON::Pretty;

my $r;
$r = mi6 "new";
isnt $r.exit, 0;

$r = mi6 "unknown";
isnt $r.exit, 0;

my $tempdir = tempdir;
{
    temp $*CWD = $tempdir.IO;
    $r = mi6 "new", "Foo::Bar";
    is $r.exit, 0;
    ok "Foo-Bar".IO.d;
    chdir "Foo-Bar";
    ok $_.IO.e for <.git  .gitignore  .travis.yml  LICENSE  META6.json  README.md  bin  lib  t>;
    ok !"xt".IO.d;
    ok "lib/Foo/Bar.pm6".IO.e;
    $r = mi6 "test";
    is $r.exit, 0;
    like $r.out, rx/All \s+ tests \s+ successful/;

    mkdir "xt";
    "xt/01-fail.t".IO.spurt: q:to/EOF/;
    use Test;
    plan 1;
    ok False;
    EOF
    $r = mi6 "test";
    isnt $r.exit, 0;
    like $r.out, rx/Failed/;

    # Check .t6 extension
    "xt/01-fail.t".IO.rename("xt/01-fail.t6");
    $r = mi6 "test";
    isnt $r.exit, 0;
    like $r.out, rx/Failed/;
}
{
    temp $*CWD = $tempdir.IO;
    temp %*ENV<HOME> = $tempdir;
    $*HOME.add('.pause').spurt: q:to/EOF/;
    user SOMEBODY
    password this-is-secret
    EOF

    $r = mi6 "new", "Hello";
    chdir "Hello";
    my $meta = from-json( "META6.json".IO.slurp );
    is $meta<description>, "blah blah blah";
    is $meta<auth>, "cpan:SOMEBODY";
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
{
    temp $*CWD = $tempdir.IO;
    mi6 "new", "Hoge::Bar";
    chdir "Hoge-Bar";
    mi6 "dist";
    ok "Hoge-Bar-0.0.1.tar.gz".IO.f;
}
{
    temp $*CWD = $tempdir.IO;
    mi6 "new", "Hello::World";
    chdir "Hello-World";
    "lib/Hello/World2.pm6".IO.spurt("");
    "lib/Hello/World3.pm6".IO.spurt("");
    "lib/Hello/World4.pm6".IO.spurt("");
    "lib/Hello/World5.pm6".IO.spurt("");
    "dist.ini".IO.spurt: q:to/EOF/;
    name = Hello-World
    [PruneFiles]
    filename = lib/Hello/World5.pm6
    [MetaNoIndex]
    filename = lib/Hello/World3.pm6
    filename = lib/Hello/World4.pm6
    EOF
    run "git", "add", ".";

    mi6 "build";
    my $meta = from-json( "META6.json".IO.slurp );
    is $meta<provides>, {
        "Hello::World" => "lib/Hello/World.pm6",
        "Hello::World2" => "lib/Hello/World2.pm6",
    };
}

done-testing;
