use common::sense;
use Web::Scraper;
use Encode;
use URI;
use Data::Dumper;
use Image::Grab;
use Spreadsheet::WriteExcel;
use WWW::Mechanize::Firefox;
use WWW::Mechanize;
use Mojo::DOM;

open(my $fh, '>', 'product_links.txt') or die "Cannot open 'product_links.txt' $!";

my $url = 'http://www.turck.nl/nl/';

# my $mech = WWW::Mechanize->new();
# warn Dumper $mech->get("$url");

my $category_links = scraper{
    process 'ul[class="navLevel3p"] li', "categ_link[]" => scraper{
        process 'a', category => '@href',
        process 'a', title => '@title'
    };
};

my $det = scraper{
    process 'a[class="pw-detlink"]', "details[]" => '@href',
    process 'div[class="paging-results fl"]', pages => 'text'
};

my $res = $category_links->scrape( URI->new($url) );

foreach my $category (@{$res->{categ_link}}){
    print Dumper $category->{category}, $category->{title} if ($category->{title});

    if ($category->{title}){
        my $mech = WWW::Mechanize::Firefox->new();
        $mech->get("$category->{category}");
        # foreach my $link ($mech->links()){
        #     warn Dumper @{$link}[1];
        # }

        my $html_content = $mech->content(format => 'html');

        # my $dom = Mojo::DOM->new( $mech->content(format => 'html') );
        
        # warn Dumper $dom->find('a[class="pw-detlink"]');
        my $res2 = $det->scrape($html_content);
        warn Dumper $res2;
        my $page = $res2->{pages};
        foreach my $detail (@{$res2->{details}}){
            warn Dumper $detail;
            print $fh 'http://pdb2.turck.de/'.$detail."\n";

        }
        $page =~ /.*\s\d+/;
        warn Dumper $page;

        my $c = 2;

        while ($c < $page){
            my $page_no = $c-1;
            warn Dumper $c;
            my $html_page = ($mech->click({selector => "//span[\@data-param=\"iwp[]=pwsPager-G-$page_no\"]"}))->as_string;
            my $res3 = $det->scrape($html_page);
            foreach my $detail (@{$res3->{details}}){
                warn Dumper $detail;
                print $fh 'http://pdb2.turck.de/'.$detail."\n";
            }
            $c = $c+1;
        }
    }
# warn Dumper $res;
}

close $fh;
