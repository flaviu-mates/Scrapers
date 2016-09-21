use common::sense;
use Web::Scraper;
use Encode;
use URI;
use Data::Dumper;
use Image::Grab;
use Spreadsheet::WriteExcel;

open(my $fh, '<', 'product_links.txt') or die "Cannot open 'product_links.txt' $!";

my $workbook = Spreadsheet::WriteExcel->new('pepperl_fuchs.xls');
my $worksheet  =$workbook->add_worksheet();

my $row = 0;

my $details = scraper{
    process 'div[class="container_breadcrump"]>ul[class="list"]>li>a', "breadcrumbs[]" => 'text';
    process 'div[class="productdetail_text_container"]>h1', title => 'text';
    process 'div[id="overview"] tr', "specifications[]" => scraper{
        process 'th', category => 'text';
        process 'td', "specs[]" => 'text';
    };
};

foreach my $link (<$fh>){

    chomp $link;
    # last if($row>10);
    my $column = 0;

    eval{
        my $res = $details->scrape( URI->new($link) );
        my $breadcrumbs='';
        foreach my $breadcrumb (@{$res->{breadcrumbs}}){
            $breadcrumbs = $breadcrumbs.$breadcrumb.' -> ';
        }
        $breadcrumbs = $breadcrumbs.$res->{title};
        warn Dumper $breadcrumbs;
        $worksheet->write($row, $column, $breadcrumbs);
        $column = $column+1;

        $worksheet->write($row, $column, $res->{title});
        $column = $column+1;

        # warn Dumper $res->{specifications};
        my $specification = '';
        foreach my $spec (@{$res->{specifications}}){
            if($spec->{category}){
                warn Dumper $specification if ($specification);
                $worksheet->write($row, $column, $specification);
                $column = $column+1;
                $specification = '';
                $specification = $specification.$spec->{category}."\n";
                warn Dumper $spec->{category};
            }

            if($spec->{specs}){
                foreach my $spec2 (@{$spec->{specs}}){
                    $specification = $specification.$spec2.": ";
                }
                chop $specification;
                chop $specification;
                $specification = $specification."\n";
                warn Dumper $spec->{specs};
            }

        }
        warn Dumper $specification;
        $worksheet->write($row, $column, $specification);
        $column = $column+1;

        $row = $row+1;
    };
    warn $@ if $@;
}