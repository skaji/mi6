use v6.c;
unit class App::Mi6::Release::CheckOrigin;

method run(*%opt) {
    my @line = run(<git remote>, :out).out.lines(:close);
    die "You shoud set git remote first.\n" if +@line == 0;
    return;
}
