use v6;
unit module Util;
use File::Temp;

my $base = $*SPEC.catdir($?FILE.IO.dirname, "..");

my class Result {
    has $.out;
    has $.err;
    has $.exit;
    method success() { $.exit == 0 }
}

sub mi6(*@arg) is export {
    my ($o, $out) = tempfile;
    my ($e, $err) = tempfile;
    my $s = run $*EXECUTABLE, "-I$base/lib", "$base/bin/mi6", |@arg, :out($out), :err($err);
    .close for $out, $err;
    my $r = Result.new(:out($o.IO.slurp), :err($e.IO.slurp), :exit($s.exitcode));
    unlink($_) for $o, $e;
    $r;
}
