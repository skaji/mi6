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

sub with-rakulib($dir, &code) is export {
    temp %*ENV;
    %*ENV<RAKULIB> = %*ENV<RAKULIB>:exists ?? "$dir," ~ %*ENV<RAKULIB> !! $dir;
    &code();
}

sub make-tarball($dir) is export {
    my @option = $*DISTRO eq "macos" ?? ("--no-xattrs") !! ();
    my %env = %*ENV;
    %env<COPY_EXTENDED_ATTRIBUTES_DISABLE> = "1";
    %env<COPYFILE_DISABLE> = "1";
    my $proc = mi6run "tar", |@option, "-czf", "$dir.tar.gz", $dir, :!out, :err, :%env;
    LEAVE $proc && $proc.err.close;
    if $proc.exitcode != 0 {
        my $exitcode = $proc.exitcode;
        my $err = $proc.err.slurp;
        die $err ?? $err !! "can't create tarball, exitcode = $exitcode";
    }
    "$dir.tar.gz";
}
