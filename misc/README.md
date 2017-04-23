Miscellaneous scripts
---------------------

### intersect_user

    intersect_user user1 [ user2 ]

Show the groups shared by two users.  The second user is you, by default.  This
can be useful for finding projects that are collaborations between users.

### perl_module_path

    perl_module_path Module::Submodule [ Module2::Submodule2 ... ]

Print the path from which each module would be loaded.

    $ perl_module_path Bio::DB::Taxonomy List::MoreUtils

    Bio::DB::Taxonomy => /opt/local/lib/perl5/vendor_perl/5.24/Bio/DB/Taxonomy.pm
    List::MoreUtils => /opt/local/lib/perl5/vendor_perl/5.24/darwin-thread-multi-2level/List/MoreUtils.pm

Slightly modified from <http://www.symkat.com/find-a-perl-modules-path>.
