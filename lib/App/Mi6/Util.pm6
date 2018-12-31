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

# Thanks to ugexe and Zef
my @mi6run-invoke = BEGIN $*DISTRO.is-win ?? <cmd.exe /x/d/c>.Slip !! '';
sub mi6run(*@_, *%_) is export { run (|@mi6run-invoke, |@_).grep(*.?chars), |%_ }
