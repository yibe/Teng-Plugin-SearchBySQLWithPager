package Teng::Plugin::SearchBySQLWithPager;
use 5.008_001;
use strict;
use warnings;
our $VERSION = '0.00_01';
use Carp ();

our @EXPORT = qw/search_by_sql_with_pager/;

sub search_by_sql_with_pager {
    my ($self, $sql) = splice @_, 0, 2;
    my $opt = pop;

    my ($page, $rows) = map {
        Carp::croak("missing mandatory parameter: $_") unless exists $opt->{$_};
        $opt->{$_};
    } qw/page rows/;

    $sql =~ s/ ; \s* \z//xms;
    $sql .= sprintf ' LIMIT %d OFFSET %d', $rows + 1, $rows*($page-1);
    my $ret = [ $self->search_by_sql($sql, @_) ];

    my $has_next = ( $rows + 1 == scalar(@$ret) ) ? 1 : 0;
    if ($has_next) { pop @$ret }

    my $pager = Teng::Plugin::SearchBySQLWithPager::Page->new(
        entries_per_page     => $rows,
        current_page         => $page,
        has_next             => $has_next,
        entries_on_this_page => scalar(@$ret),
    );

    return ($ret, $pager);
}

package Teng::Plugin::SearchBySQLWithPager::Page;
# copied from Teng::Plugin::Pager
use Class::Accessor::Lite (
    ro => [qw/entries_per_page current_page has_next entries_on_this_page/],
);

sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;
    bless {%args}, $class;
}

sub next_page {
    my $self = shift;
    $self->has_next ? $self->current_page + 1 : undef;
}

sub previous_page { shift->prev_page(@_) }
sub prev_page {
    my $self = shift;
    $self->current_page > 1 ? $self->current_page - 1 : undef;
}

1;
__END__

=head1 NAME

Teng::Plugin::SearchBySQLWithPager - Teng plugin to add 'search_by_sql_with_pager' method

=head1 SYNOPSIS

  package MyApp::DB;
  use parent 'Teng';
  __PACKAGE__->load_plugin('SearchBySQLWithPager');
  
  package main;
  my $db = MyApp::DB->new(...);
  my $page = $c->req->param('page') || 1;
  my ($rows, $pager) = $db->search_by_sql_with_pager(
      'SELECT id, name, type FROM user WHERE type = ?',
      [ 3 ],
      'user',
      { page => $page, rows => 5 },
  );

=head1 DESCRIPTION

Teng::Plugin::SearchBySQLWithPager is

=head1 AUTHOR

Yuki Ibe E<lt>yibe at yibe dot orgE<gt>

=head1 SEE ALSO

L<Teng>, L<Teng::Plugin::Pager>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
