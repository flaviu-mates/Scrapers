use strict;
use warnings;
use Web::Scraper;
use Encode;
use URI;
use Data::Dumper;
use Image::Grab;
use Spreadsheet::WriteExcel;

my $url = 'http://www.donne.nl/catalogus';

my @product_links=[];

my $workbook = Spreadsheet::WriteExcel->new('donne.xls');
my $worksheet  =$workbook->add_worksheet();

my $category_links = scraper{
    process 'a[itemprop="name"]', "categ_link[]" => '@href'
};

my $products = scraper{
    process 'a[itemprop="name"]', "product_link[]" => '@href',
    process 'div[class="pages"] li', "pages[]" => scraper{
        process "li", page => 'TEXT';
    };
};

eval{
    my $res = $category_links->scrape( URI->new($url) );

    foreach my $subcat (@{$res->{categ_link}}){
        # warn Dumper $subcat;
        
        eval{
            my $res2 = $category_links->scrape( URI-> new($subcat) );
            # warn Dumper $res2;
            foreach my $subcat2 (@{$res2->{categ_link}}){
                # warn Dumper $subcat2;
                eval{
                    my $res3 = $products->scrape( URI-> new($subcat2) );
                    # warn Dumper $res3->{product_link};
                    push @product_links, @{$res3->{product_link}} if ($res3->{product_link});
                    # warn Dumper @product_links;
                    if($res3->{pages}[-2]){
                        warn Dumper $res3->{pages}[-2]{page};
                        # my $res4 = $category_links->scrape
                        my $c=2;
                        while($c<=$res3->{pages}[-2]{page}){
                            my $link = $subcat2."/$c";
                            $c = $c+1;
                            warn Dumper $link;
                            eval{
                                my $res4 = $products->scrape( URI-> new($link) );
                                # warn Dumper $res3->{product_link};
                                push @product_links, @{$res4->{product_link}};
                            };
                            warn $@ if $@;
                        }
                    }
                };
                warn $@ if $@;
            }
        };
        warn $@ if $@;


    }
};
warn  $@ if $@;

my $specifications = scraper{
    process 'div[style="padding: 13px; border-bottom: 1px solid #002b56; width: 361px;"]', "breadcrumbs" => scraper{
        process 'a', "as[]" => 'TEXT';
        process 'span', "spans[]" => 'TEXT';
    };
    process 'div[class="body rightalign"] img', "image" => scraper{
        process 'img', picture => '@src';
    };
    process 'div[class="textblock"]', "specifications[]" => scraper{
        process 'div[class="header"]', category => 'TEXT';
        process 'div[class="body"]', "specifs[]" => scraper{
            process 'div[class="clearfloat leftblock"]', "lefts[]" => 'TEXT';
            process 'div[class="leftblock"]', "rights[]" => 'TEXT';
        };
    };
};

my $row = 0;

foreach my $link (@product_links){


    if($link){
        eval{
            warn Dumper $link;
            my $result = $specifications->scrape( URI->new($link) );
            my $breadcrumb = '';
            my $folder = '';
            my $column = 0;
            foreach my $a (@{$result->{breadcrumbs}{as}}){
                $breadcrumb = $breadcrumb.$a.'->';
                $folder = $folder.$a.',';
            }
            $breadcrumb = $breadcrumb." @{$result->{breadcrumbs}{spans}}[-1]";
            warn Dumper $breadcrumb;
            $worksheet->write($row, $column, Encode::encode('utf8', $breadcrumb));
            $column = $column+1;
            my $name = @{$result->{breadcrumbs}{spans}}[-1];
            $worksheet->write($row, $column, Encode::encode('utf8', $name));
            $column = $column+1;
            warn Dumper $name;
            chop $folder;
            my $url = Encode::encode('utf8', $result->{image}{picture});
            # warn Dumper $url;
            # chomp $url;
            # my $pic = Image::Grab->new;
            # $pic->url( "http://www.donne.nl/SiteContent/images/products/vd%2010%20mm2%20bl%20donne.JPG" );
            # $pic->grab;
            # open IMAGE, " > @{$result->{breadcrumbs}{spans}}[-1].jpg" || die"@{$result->{breadcrumbs}{spans}}[-1].jpg: $!";
            # binmode IMAGE;
            # print IMAGE $pic->image;
            # close IMAGE;

            # warn Dumper $result->{specifications};

            foreach my $specifications ($result->{specifications}){
                # warn Dumper $specifications;
                foreach my $specifs (@{$specifications}){
                    foreach my $specif (@{$specifs->{specifs}}){
                        # warn Dumper $specif;
                        my $specs = '';
                        my $c = 0;
                        foreach my $left (@{$specif->{lefts}}){
                            $specs = $specs.Encode::encode('utf8', $left).': '.Encode::encode('utf8',@{$specif->{rights}}[$c])."\n";
                            $c = $c+1;
                        }
                        warn Dumper $specs;
                        $worksheet->write($row, $column, Encode::encode('utf8', $specs));
                        $column = $column+1;
                    }
                }
            }

            $row = $row+1;

        };
        warn $@ if $@;
    }

}