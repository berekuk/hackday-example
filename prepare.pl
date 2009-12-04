#!/usr/bin/perl
# Copyright (c) 2009 Yandex.ru

use strict;
use warnings;

use LWP::Simple;
use XML::LibXML::Simple;
use Storable qw(store);
use List::Util qw(max);

my %xml;

$xml{hackday} = XMLin(get('http://blogs.yandex.ru/search.rss?text=hackday'));
$xml{hackday_popular} = XMLin(get('http://blogs.yandex.ru/search.rss?text=hackday&how=relev'));

my $p = 0;
my $rating_xml;
while () {
    print "preparing page $p\n";
    my $page_xml = XMLin(get("http://blogs.yandex.ru/entriesapi?p=$p"));
    unless ($page_xml->{channel}{item}) {
        last;
    }
    if ($rating_xml) {
        my $items = $page_xml->{channel}{item};
        my @items = ref($items) eq 'ARRAY' ? @$items : ($items);
        push @{ $rating_xml->{channel}{item} }, @items;
    }
    else {
        $rating_xml = $page_xml;
    }
    $p++;
}

sub rating {
    my $item = shift;
    my $c = $item->{'yablogs:commenters24'} || 1;
    my $l = $item->{'yablogs:links24'} || 1;
    my $v = $item->{'yablogs:visits24'} || 1;
    my $rating = 2 / ( 1 / max(5 * $l, $c) + ( 1 / $v)); # harmonic_mean(max(links,comments),visits)
    warn "rating: $rating\n";
    return $rating;
}

my @items = @{ $rating_xml->{channel}{item} };
@items = sort { rating($b) <=> rating($a) } @items;
$rating_xml->{channel}{item} = [ @items[0..9] ];
$xml{popular} = $rating_xml;

store(\%xml => '/var/www/hackday/data/xml');

