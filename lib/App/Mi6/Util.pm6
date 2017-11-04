use v6.c;
unit module App::Mi6::Util;

sub prompt($message, :$default) is export {
    $*OUT.print("$message ");
    $*OUT.flush;
    my $line = $*IN.get;
    $line .= chomp;
    return $default if $default and $line eq "";
    $line;
}
