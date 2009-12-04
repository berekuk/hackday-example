#!/usr/bin/perl
# Copyright (c) 2009 Yandex.ru

use strict;
use warnings;

use LWP::Simple;
use XML::Simple;
use Storable qw(store);

my %xml;

$xml{hackday} = XMLin(get('http://blogs.yandex.ru/search.rss?text=hackday'));
$xml{hackday_popular} = XMLin(get('http://blogs.yandex.ru/search.rss?text=hackday&how=relev'));

store(\%xml => '/var/www/hackday/data/xml');

