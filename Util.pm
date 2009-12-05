package Util;

use strict;
use warnings;

use base qw(Exporter);

our @EXPORT = qw( rss expand );

use LWP::Simple;
use XML::LibXML::Simple;
use URI;
use Date::Manip;

sub rss {
    my $text = shift;
    my $cgi = shift || {};
    my $uri = URI->new("http://blogs.yandex.ru/search.rss");
    $uri->query_form(
        text => $text,
        %$cgi,
    );
    my $rss = XMLin(get($uri->as_string));
    expand($rss);
    return $rss;
}

sub expand {
    my $rss = shift;
    for my $item (@{ $rss->{channel}{item} }) {
        my $author = $item->{author};
        if ($item->{link}) {
            if ($item->{link} =~ m{(http://users\.livejournal\.com/[^/]+)}) {
                $author = $1;
            }
            elsif ($item->{link} =~ m{(http://[^.]+\.livejournal\.com)}) {
                $author = "$1/";
            }
        }
        next unless defined $author;
        my $url = URI->new("http://blogs.yandex.ru/search_profiles_atom.xml");
        $url->query_form({ text => qq{journal="$author"} });
        my $foaf = XMLin(get($url));
        my $entry = $foaf->{entry};
        if ($entry) {
            $entry = $entry->[0] if ref($entry) eq 'ARRAY';
            if (my $nick = $entry->{title}) {
                $item->{nick} = $nick;
            }
        }
        $item->{nick} ||= $author;

        my $date = ParseDate($item->{pubDate});
        $item->{date}{time} = UnixDate($date, '%i:%M');
        $item->{date}{day} = UnixDate($date, '%e');
        $item->{date}{month} = UnixDate($date, '%b');
    }
}

1;

