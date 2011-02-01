package Teng::Plugin::SearchBySQLWithPager::MySQLFoundRows;
use 5.008_001;
use strict;
use warnings;
our $VERSION = '0.00_01';
use Carp ();
use Data::Page;

our @EXPORT = qw/search_by_sql_with_pager/;

sub search_by_sql_with_pager {
    my ($self, $sql) = splice @_, 0, 2;
    my $opt = pop;

    my ($page, $rows) = map {
        Carp::croak("missing mandatory parameter: $_") unless exists $opt->{$_};
        $opt->{$_};
    } qw/page rows/;

    # $sql =~ s{ (?<= \b SELECT ) (?= \s ) }{ SQL_CALC_FOUND_ROWS}ixms;
    Carp::croak "You must explicitly specify a SQL_CALC_FOUND_ROWS option in the statement (at least for now)"
        unless $sql =~ / \b SELECT \b .* \b SQL_CALC_FOUND_ROWS \b /ixms;

    $sql =~ s/ ; \s* \z //xms;
    $sql .= sprintf ' LIMIT %d OFFSET %d', $rows, $rows*($page-1);
    my $itr = $self->search_by_sql($sql, @_);

    my $total_entries = $self->dbh->selectrow_array(q{SELECT FOUND_ROWS()});

    my $pager = Data::Page->new();
    $pager->entries_per_page($rows);
    $pager->current_page($page);
    $pager->total_entries($total_entries);

    return ([$itr->all], $pager);
}

1;
__END__
