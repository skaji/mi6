use v6.c;
unit class App::Mi6::Release::CheckDirty;

method run(*%opt) {
    my @line = run(<git status -s>, :out).out.lines(:close);
    @line .= grep(-> $_ { $_ !~~ /^ \s* M \s* Changes $/ });
    return if +@line == 0;
    note "You need to commit the following files:";
    note $_ for @line;
    die;
}
