sub author_tests        { } # Module::Install::AuthorTests
sub auto_set_repository { } # Module::Install::Repository
sub readme_pod_from     { } # Module::Install::ReadmePodFromPod

use inc::Module::Install;
name 'Teng-Plugin-SearchBySQLWithPager';
all_from 'lib/Teng/Plugin/SearchBySQLWithPager.pm';
readme_pod_from 'lib/Teng/Plugin/SearchBySQLWithPager.pm';

requires 'Carp';
requires 'DBI';
requires 'Teng';
requires 'parent';
requires 'Data::Page::NoTotalEntries' => '0.02';

build_requires 'Test::More' => '0.96';
test_requires 'DBD::SQLite';
test_requires 'Test::mysqld' if $Module::Install::AUTHOR;

tests 't/*.t';
author_tests 'xt', 'xt/mysql';

auto_set_repository;
WriteAll;
