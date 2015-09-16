[![Build Status](https://travis-ci.org/shoichikaji/mi6.svg?branch=master)](https://travis-ci.org/shoichikaji/mi6)

NAME
====

App::Mi6 - minimal authoring tool for Perl6

SYNOPSIS
========

    > mi6 new Foo::Bar

    > find Foo-Bar -type f -not -iwholename '*.git*'
    Foo-Bar/.travis.yml
    Foo-Bar/lib/Foo/Bar.pm6
    Foo-Bar/LICENSE
    Foo-Bar/META.info
    Foo-Bar/README.md
    Foo-Bar/t/01-basic.t

    > cd Foo-Bar
    > mi6 build  # regenerate README.md
    > mi6 test   # run tests

INSTALLATION
============

    > panda install App::Mi6

DESCRIPTION
===========

App::Mi6 is a minimal authoring tool for Perl6. Features are:

  * Create minimal distribution skelton for Perl6

  * Auto generate README.md from lib/Main/Module.pm6's pod

  * Run tests by `mi6 test`

FAQ
===

  * How can I manage depends, description, ...?

    Write them to META.info directly :)

  * Where is Changes file?

    TODO

  * Where is the spec of META.info or META6.json?

    Maybe https://github.com/perl6/ecosystem/blob/master/spec.pod

  * How do I remove travis badge?

    Remove .travis.yml

SEE ALSO
========

[https://github.com/tokuhirom/Minilla](https://github.com/tokuhirom/Minilla)

[https://github.com/rjbs/Dist-Zilla](https://github.com/rjbs/Dist-Zilla)

COPYRIGHT AND LICENSE
=====================

Copyright 2015 Shoichi Kaji <skaji@cpan.org>

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.
