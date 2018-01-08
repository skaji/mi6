[![Build Status](https://travis-ci.org/skaji/mi6.svg?branch=master)](https://travis-ci.org/skaji/mi6)

NAME
====

App::Mi6 - minimal authoring tool for Perl6

SYNOPSIS
========

    > mi6 new Foo::Bar # create Foo-Bar distribution
    > mi6 build        # build the distribution and re-generate README.md/META6.json
    > mi6 test         # run tests
    > mi6 release      # release your distribution to CPAN

INSTALLATION
============

    > zef install App::Mi6

DESCRIPTION
===========

App::Mi6 is a minimal authoring tool for Perl6. Features are:

  * Create minimal distribution skeleton for Perl6

  * Generate README.md from lib/Main/Module.pm6's pod

  * Run tests by `mi6 test`

  * Release your distribution tarball to CPAN

FAQ
===

Can I customize mi6 behavior?
-----------------------------

Use `dist.ini`:

    ; dist.ini
    name = Your-Module-Name

    [ReadmeFromPod]
    ; if you want to disable generating README.md from main module's pod, then:
    ; disable = true
    ;
    ; if you want to change a file that generates README.md, then:
    ; filename = lib/Your/Tutorial.pod

    [PruneFiles]
    ; if you want to prune files when packaging, then
    ; filename = utils/tool.pl
    ;
    ; you can use Perl6 regular expressions
    ; match = ^ 'xt/'

How can I manage depends, build-depends, test-depends?
------------------------------------------------------

Write them to META6.json directly :)

Where is the spec of META6.json?
--------------------------------

http://design.perl6.org/S22.html

TODO
====

documentation

SEE ALSO
========

[https://github.com/tokuhirom/Minilla](https://github.com/tokuhirom/Minilla)

[https://github.com/rjbs/Dist-Zilla](https://github.com/rjbs/Dist-Zilla)

AUTHOR
======

Shoichi Kaji <skaji@cpan.org>

COPYRIGHT AND LICENSE
=====================

Copyright 2015 Shoichi Kaji

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

