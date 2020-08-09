[![Actions Status](https://github.com/tbrowder/mi6/workflows/test/badge.svg)](https://github.com/tbrowder/mi6/actions)

NAME
====

App::Mi6 - minimal authoring tool for Raku

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

First make sure you have rakudo v2019.11 or later. If not, install rakudo from [https://rakudo.org/downloads](https://rakudo.org/downloads).

Then:

```console
$ zef install App::Mi6
```

DESCRIPTION
===========

App::Mi6 is a minimal authoring tool for Raku. Features are:

  * Create minimal distribution skeleton for Raku

  * Generate README.md from lib/Main/Module.rakumod's pod

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
; you can use Raku regular expressions
; match = ^ 'xt/'

[MetaNoIndex]
; if you do not want to list some files in META6.json as "provides", then
; filename = lib/Should/Not/List/Provides.rakumod

[Badges]
; if you want to add badges to README.md, then
; provider = travis-ci.org
; provider = travis-ci.com
; provider = appveyor
; provider = github-actions/name
```

How can I manage depends, build-depends, test-depends?
------------------------------------------------------

Write them to META6.json directly :).

Where is the spec of META6.json?
--------------------------------

https://design.raku.org/S22.html

See also [The Meta spec, Distribution, and CompUnit::Repository explained-ish](https://perl6advent.wordpress.com/2016/12/16/day-16-the-meta-spec-distribution-and-compunitrepository-explained-ish/) by ugexe.

What is the format of the .pause file?
--------------------------------------

Mi6 uses the .pause file in your home directory to determine the username. This is a flat text file, designed to be compatible with the .pause file used by the Perl5 `cpan-upload` module ([https://metacpan.org/pod/cpan-upload](https://metacpan.org/pod/cpan-upload)). Note that this file only needs to contain the "user" and "password" directives. Unknown directives are ignored.

An example file could consist of only two lines:

    user your_pause_username
    password your_pause_password

Replace `your_pause_username` with your PAUSE username, and replace `your_pause_password` with your PAUSE password.

This file can also be encrypted with GPG if you do not want to leave your PAUSE credentials in plain text.

What existing files are modified by `mi6`?
------------------------------------------

After the initial `mi6` creation step, the following files are changed by `mi6` during each build or release operation:

  * `Changes`

  * `META6.json`

  * All modules in the lib directory

In each case, only the version number is changed. In addition, the `META6.json` file is reformatted to strict JSON format. For example, if you have an empty array like this in the existing file

    "depends" : [
    ],

it will get changed to

    "depends" : [],

How is the version number specified?
------------------------------------

When you are ready to release a module and enter at the CLI mi6 release, you will get a response presenting a proposed version number which you can either accept or enter a new one (which must be greater than the one offered by default).

During the release, `mi6` updates the files mentioned above with the selected version number.

What is the required format of the `Changes` file before a release?
-------------------------------------------------------------------

Ensure your `Changes` file looks like something like this **before** you start a release operation

    {{NEXT}}
        - Tightened the framistan
          - Changed to counterclockwise operation

Notes:

  * Text above the `{{NEXT}}` line is ignored

  * The first change text line **must** start with a space or tab

  * `mi6` does not change any text except to substitute the new version number and its time stamp plus adding a new `{{NEXT}}` token above the latest version entry

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

