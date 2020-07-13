unit class App::Mi6::Release::RegenerateFiles;

method run(*%opt) {
    %opt<app>.cmd("build");
}
