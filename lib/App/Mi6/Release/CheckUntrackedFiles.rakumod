use App::Mi6::Util;
unit class App::Mi6::Release::CheckUntrackedFiles;

method run(*%opt) {
    my @cmd = <git ls-files -z --others --exclude-standard>;
    my @line = mi6run(|@cmd, :out).out.slurp(:close).split("\0").grep(* ne "");
    return if +@line == 0;
    die "Untracked files are found:\n\n"
        ~ @line.map({ "* $_\n" }).join("")
        ~ "\nYou should git-add them or list them in .gitignore."
}
