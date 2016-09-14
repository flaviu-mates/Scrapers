use common::sense;
use Web::Scraper;
use Encode;
use URI;
use Data::Dumper;

open(my $fh, '>', 'product_links.txt') or die "Cannot open 'product_links.txt' $!";

my $url = 'http://www.pepperl-fuchs.nl/netherlands/nl/21.htm';

my $category_links = scraper{
    process "div[class=\"list\"]>ul>li>a", "links[]" => '@href'
};

my $res = $category_links->scrape( URI->new($url) );

warn Dumper $res;