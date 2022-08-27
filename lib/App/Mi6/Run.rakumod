unit class App::Mi6::Run;

has $.raw-cmd;

method cmd() {
    my $cmd = $.raw-cmd;
    $cmd .= subst('%x', $*EXECUTABLE);
    $cmd;
}

method run() {
    my $cmd = $.cmd();
    my $proc = shell $cmd;
    die "Failed to execute $cmd" if !?$proc;
}
