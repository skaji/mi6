use v6;
unit module Util;

my $base = $*SPEC.catdir($?FILE.IO.dirname, "..");

my class Result {
    has $.out;
    has $.err;
    has $.exit;
    method success() { $.exit == 0 }
}

sub mi6(*@arg) is export {
    my $p = Proc::Async.new($*EXECUTABLE, "-I$base/lib", "$base/bin/mi6", |@arg);
    my ($out, $err);
    $p.stdout.tap: -> $v { $out ~= $v };
    $p.stderr.tap: -> $v { $err ~= $v };
    my $promise = $p.start;

    # See https://docs.perl6.org/language/traps
    # https://rt.perl.org/Ticket/Display.html?id=128674
    try sink await $promise; # or $ = await $promise;
    Result.new(:out($out), :err($err), :exit($promise.result.exitcode));
}
