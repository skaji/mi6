use App::Mi6::Util;
unit class App::Mi6::Release::CheckOrigin;

method run(*%opt) {
    my @line = mi6run(<git remote>, :out).out.lines(:close);
    die "You shoud set git remote first.\n" if +@line == 0;
    return;
}
