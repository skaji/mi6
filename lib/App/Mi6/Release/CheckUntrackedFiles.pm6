use v6.c;
unit class App::Mi6::Release::CheckUntrackedFiles;

method run(*%opt) {
    my @cmd = <git ls-files -z --others --exclude-standard>;
    my $proc = run |@cmd, :out;
    my @line = $proc.out.lines(:nl-in("\0"), :chomp, :close);
    return if +@line == 0;
    die "Untracked files are found:\n"
        ~ @line.map({ "* $_\n" }).join("")
        ~ "You should git-add them or list them in .gitignore.\n"
}
