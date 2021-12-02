[![Actions Status](https://github.com/skaji/mi6/workflows/test/badge.svg)](https://github.com/skaji/mi6/actions)

NAME
====

App::Mi6 - minimal authoring tool for Raku

SYNOPSIS
========

```console
$ mi6 new Foo::Bar        # create Foo-Bar distribution for CPAN ecosystem
$ mi6 new --zef Foo::Bar  # create Foo-Bar distribution for Zef ecosystem

$ mi6 build    # build the distribution and re-generate README.md/META6.json
$ mi6 test     # run tests
$ mi6 release  # release your distribution to CPAN/Zef ecosystem (configured by dist.ini)
```

INSTALLATION
============

First make sure you have rakudo v2020.05 or later. If not, install rakudo from [https://rakudo.org/downloads](https://rakudo.org/downloads).

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

  * Release your distribution to [CPAN ecosystem](https://www.cpan.org/authors/id/) or [Zef ecosystem](https://deathbyperl6.com/faq-zef-ecosystem/)

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

[UploadToCPAN]   ; Upload your distribution to CPAN ecosystem
; [UploadToZef]  ; You can also use UploadToZef instead, to upload your distribution to Zef ecosystem

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

  * `README.md`

  * `Changes`

  * `META6.json`

  * modules in the lib directory

How is the version number specified?
------------------------------------

When you are ready to release a module and enter at the CLI mi6 release, you will get a response presenting a proposed version number which you can either accept or enter a new one (which must be greater than the one offered by default).

During the release, `mi6` updates the files mentioned above with the selected version number.

What is the required format of the `Changes` file before a release?
-------------------------------------------------------------------

Ensure your `Changes` file looks like something like this **before** you start a release operation

    {{$NEXT}}
        - Change entry line 1
        - Change entry line 2
        - Change entry line 3

Notes:

  * `mi6 release` will replace the `{{$NEXT}}` line with the new version number and its timestamp

  * You **must** have at least one change entry line

  * The first change entry line **must** start with a space or tab

What is the source of the author's email address?
-------------------------------------------------

The email is taken from the author's `.gitconfig` file. In general, that same email address should match any email address existing in a module's `META6.json` file.

How does one change an existing distribution created with `mi6` to use Zef ecosystem instead of CPAN ecosystem?
---------------------------------------------------------------------------------------------------------------

First, the author must have an active account with [fez](https://github.com/tony-o/raku-fez) which will create a `.fez-config.json` file in the author's home directory.

Then, starting with an existing module created with `mi6`, do the following:

  * Add the following line to your `dist.ini` file:

    `[UploadToZef]`

  * Change all instances of the `auth<cpan:CPAN-USERNAME>` to `auth<zef:zef-username>`. Check files `META6.json` and the module's leading or main module file in directory `./lib`.

  * Optional, but recommended: Add an entry in the module's `Changes` file mentioning the change.

  * Run `mi6 build; mi6 test`.

  * Commit all changes.

  * Run `mi6 release` and accept (or increase) the version number offered by `mi6`.

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

