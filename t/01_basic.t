use strict;
use warnings;
use DBI;
use Teng::Schema::Loader;
use Test::More;

my $dbh = DBI->connect(
    'dbi:SQLite::memory:', '', '',
    { RaiseError => 1, PrintError => 0, AutoCommit => 1 },
);
my $table_name = 'teng_plugin_searchbysqlwithpager';
$dbh->do(qq{
    CREATE TABLE $table_name (
        id   INTEGER,
        name TEXT,
        PRIMARY KEY (id)
    )
});

{
    package Mock::Basic;
    use parent 'Teng';
    __PACKAGE__->load_plugin('SearchBySQLWithPager');
}
my $schema = Teng::Schema::Loader->load( dbh => $dbh, namespace => 'Mock::Basic' );
my $db = Mock::Basic->new( schema => $schema, dbh => $dbh );

for my $i (1..32) {
    $db->insert($table_name => { id => $i, name => "name_$i" });
}

subtest 'simple' => sub {
    my ($rows, $pager) = $db->search_by_sql_with_pager(
        "SELECT id, name FROM $table_name",
        [ ],
        $table_name,
        { rows => 3, page => 1 },
    );
    is join(',', map { $_->id } @$rows), '1,2,3';
    is $pager->entries_per_page(), 3, 'entries_per_page';
    is $pager->entries_on_this_page(), 3, 'entries_on_this_page';
    is $pager->current_page(), 1, 'current_page';
    is $pager->next_page, 2, 'next_page';
    ok $pager->has_next, 'has_next';
    is $pager->prev_page, undef, 'prev_page';
};

subtest 'last' => sub {
    my ($rows, $pager) = $db->search_by_sql_with_pager(
        "SELECT id, name FROM $table_name WHERE id > ?",
        [ 0 ],
        $table_name,
        { rows => 3, page => 11 },
    );
    is join(',', map { $_->id } @$rows), '31,32';
    is $pager->entries_per_page(), 3, 'entries_per_page';
    is $pager->entries_on_this_page(), 2, 'entries_on_this_page';
    is $pager->current_page(), 11, 'current_page';
    is $pager->next_page, undef, 'next_page';
    ok !$pager->has_next, 'has_next';
    is $pager->prev_page, 10, 'prev_page';
};

done_testing;
