unit class App::Mi6::INI;

# Copy from https://github.com/tadzik/perl6-Config-INI
# Author: Tadeusz “tadzik” Sośnierz, Nobuo Danjou
# License: MIT
my grammar INI {
    token TOP      {
                        ^
                        <.eol>*
                        <toplevel>?
                        <sections>*
                        <.eol>*
                        $
                   }
    token toplevel { <keyval>* }
    token sections { <header> <keyval>* }
    token header   { ^^ \h* '[' ~ ']' $<text>=<-[ \] \n ]>+ \h* <.eol>+ }
    token keyval   { ^^ \h* <key> \h* '=' \h* <value>? \h* <.eol>+ }
    regex key      { <![#\[]> <-[;=]>+ }
    regex value    { [ <![#;]> \N ]+ }
    # TODO: This should be just overriden \n once Rakudo implements it
    token eol      { [ <[#;]> \N* ]? \n }
}

my class INI::Actions {
    method TOP ($/) {
        my %hash = $<sections>».ast.hash;
        %hash<_> = $<toplevel>.ast if $<toplevel>.?ast;
        make %hash;
    }
    method toplevel ($/) { make $<keyval>».ast }
    method sections ($/) { make $<header><text>.Str => $<keyval>».ast }
    # TODO: The .trim is useless, <!after \h> should be added to key regex,
    # once Rakudo implements it
    method keyval ($/) { make $<key>.Str.trim => $<value>.defined ?? $<value>.Str.trim !! '' }
}

our sub parsefile($file) {
    INI.parsefile($file, :actions(INI::Actions.new)).ast;
}
