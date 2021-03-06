use strict;
use warnings;
use DBI;
use Teng::Schema::Loader;
use Test::More;
use Test::mysqld;

my $mysqld = Test::mysqld->new(
    my_cnf => {
        'skip-networking' => '',
    },
) or plan skip_all => $Test::mysqld::errstr;
my $dbh = DBI->connect(
    $mysqld->dsn(dbname => 'test'), '', '',
    { RaiseError => 1, PrintError => 0, AutoCommit => 1 },
);
my $table_name = 'teng_plugin_searchbysqlwithpager_mysqlfoundrows';
$dbh->do(qq{
    CREATE TABLE $table_name (
        id   INTEGER,
        name VARCHAR(8),
        PRIMARY KEY (id)
    ) ENGINE=MEMORY
});

{
    package Mock::Basic;
    use parent 'Teng';
    __PACKAGE__->load_plugin('SearchBySQLWithPager');
}
my $db = Teng::Schema::Loader->load( dbh => $dbh, namespace => 'Mock::Basic' );

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
    is $pager->first, 1, 'first';
    is $pager->last, 3, 'last';
};

subtest 'last' => sub {
    my ($rows, $pager) = $db->search_by_sql_with_pager(
        "SELECT id, name FROM $table_name WHERE id >= ?",
        [ 4 ],
        $table_name,
        { rows => 3, page => 10 },
    );
    is join(',', map { $_->id } @$rows), '31,32';
    is $pager->entries_per_page(), 3, 'entries_per_page';
    is $pager->entries_on_this_page(), 2, 'entries_on_this_page';
    is $pager->current_page(), 10, 'current_page';
    is $pager->next_page, undef, 'next_page';
    ok !$pager->has_next, 'has_next';
    is $pager->prev_page, 9, 'prev_page';
    is $pager->first, 28, 'first';
    is $pager->last, 29, 'last';
};

done_testing;
