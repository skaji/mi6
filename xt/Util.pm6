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
    my $p = run $*EXECUTABLE, "-I$base/lib", "$base/bin/mi6", |@arg, :out, :err;
    my $out = $p.out.slurp(:close);
    my $err = $p.err.slurp(:close);
    Result.new(:out($out), :err($err), :exit($p.exitcode));
}
