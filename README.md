NAME
====

App::Mi6 - minimal authoring tool for Perl6

SYNOPSIS
========

```console
$ mi6 new Foo::Bar # create Foo-Bar distribution
$ mi6 build        # build the distribution and re-generate README.md/META6.json
$ mi6 test         # run tests
$ mi6 release      # release your distribution to CPAN
```

INSTALLATION
============

```console
$ zef install App::Mi6
```

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

Yes. Use `dist.ini`:

```ini
; dist.ini
name = Your-Module-Name

[ReadmeFromPod]
; if you want to disable generating README.md from main module's pod, then:
; enable = false
;
; if you want to change a file that generates README.md, then:
; filename = lib/Your/Tutorial.pod

[PruneFiles]
; if you want to prune files when packaging, then
; filename = utils/tool.pl
;
; you can use Perl6 regular expressions
; match = ^ 'xt/'

[MetaNoIndex]
; if you do not want to list some files in META6.json as "provides", then
; filename = lib/Should/Not/List/Provides.pm6
```

How can I manage depends, build-depends, test-depends?
------------------------------------------------------

Write them to META6.json directly :)

Where is the spec of META6.json?
--------------------------------

http://design.perl6.org/S22.html

See also [The Meta spec, Distribution, and CompUnit::Repository explained-ish](https://perl6advent.wordpress.com/2016/12/16/day-16-the-meta-spec-distribution-and-compunitrepository-explained-ish/) by ugexe.

What is the format of the .pause file?
--------------------------------------

Mi6 uses the .pause file in your home directory to determine the username. This is a flat text file, designed to be compatible with the .pause file used by the Perl5 `cpan-upload` module ([https://metacpan.org/pod/cpan-upload](https://metacpan.org/pod/cpan-upload)). Note that this file only needs to contain the "user" and "password" directives. Unknown directives are ignored.

An example file could consist of only two lines:

    user your_pause_username
    password your_pause_password

Replace `your_pause_username` with your PAUSE username, and replace `your_pause_password` with your PAUSE password.

This file can also be encrypted with GPG if you do not want to leave your PAUSE credentials in plain text.

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

