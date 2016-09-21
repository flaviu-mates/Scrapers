use common::sense;
use Web::Scraper;
use Encode;
use URI;
use Data::Dumper;

open(my $fh, '>', 'product_links.txt') or die "Cannot open 'product_links.txt' $!";

my $url = 'http://www.pepperl-fuchs.nl/netherlands/nl/21.htm';
my @links = [];

my $category_links = scraper{
    process "div[class=\"list\"]>ul>li>a", "links[]" => '@href'
};

my $category_links2 = scraper{
    process "span[class=\"text\"]>span>ul>li>a", "links[]" => '@href'
};

my $per_page = scraper{
    process 'span[class="content_info"]', page=>'text'
};

my $products = scraper{
    process "td[class=\"title\"]>ul>li>a", "links[]" => '@href'
};

my $res = $category_links->scrape( URI->new($url) );

foreach my $category (@{$res->{links}}){
    warn Dumper $category;
    my $res2 = $per_page->scrape($category);
    if($res2->{page}){
        warn Dumper $res2->{page};
        push @links, $category;
    }
    else{
        my $res3 = $category_links2->scrape($category);
        # if($res3->{links}){
            foreach my $link (@{$res3->{links}}){
                my $res4 = $per_page->scrape($link);
                if($res4->{page}){
                    warn Dumper $res4->{page};
                    push @links, $link;
                }
                else{
                    my $res5 = $category_links2->scrape($link);
                    push @links, @{$res5->{links}};
                }
            }
        # }
    }
}

warn Dumper @links;

foreach my $link (@links){
    my $res2 = $per_page->scrape($link);
    if($res2->{page}){
        warn Dumper $link;
        warn Dumper $res2->{page};
        my $page = $res2->{page};
        $page =~ /\/(\d+)/;
        warn Dumper $1;
        $page = $1;
        if($page<10){
            my $res2 = $products->scrape($link);
            foreach my $link2 (@{$res2->{links}}){
                if($link2=~/.*productdetails.*/){
                    warn Dumper $link2;
                    print $fh $link2."\n";
                }
            }
        }
        else{
            $link = $link."?view=&startat=1&sortorder=&sortby=&docpartno=&partnoname=&FormHandler_SelectBox_SearchField=&itemsperpage=$page#overview_prodlist";
            warn Dumper $link;
            my $res2 = $products->scrape( URI->new($link) );
            foreach my $link2 (@{$res2->{links}}){
                if($link2=~/.*productdetails.*/){
                    warn Dumper $link2;
                    print $fh $link2."\n";
                }
            }
        }

    }
}

close $fh;