use common::sense;
use Web::Scraper;
use Encode;
use URI;
use Data::Dumper;
use Image::Grab;
use Spreadsheet::WriteExcel;

open(my $fh, '<', 'product_links.txt') or die "Cannot open 'product_links.txt' $!";

my $workbook = Spreadsheet::WriteExcel->new('turck.xls');
my $worksheet  =$workbook->add_worksheet();

my $row = 0;

my $details = scraper{
    process "div[class=\"breadcrumb clearfix\"]>ul>li>a", "breadcrumbs[]" => 'text';
    process "div[class=\"prodDetail clearfix\"]>h1", title => 'text';
    process 'div[class="col col2"]', first => scraper{
        process 'p', "ps[]"=>'text';
        process 'strong', strong => 'text';
        process "ul[class=\"prodUl\"]>li", "det[]"=>'text';
    };
    process 'div[class="col col2"]', div=>'text';
    process "div[id=\"infotable1\"]>table[class=\"tableProd\"]>tbody>tr>td", "tds[]" => 'text';
    process "div[class=\"col col1\"]>a>img", image=>'@src';
};

foreach my $link (<$fh>){

    chomp $link;
    # last if($row>10);
    my $column = 0;
    eval{
        my $res = $details->scrape( URI->new($link) );

        my $breadcrumbs = '';

        foreach my $bread (@{$res->{breadcrumbs}}){

            $breadcrumbs = $breadcrumbs.$bread.' -> ' if($bread);

        }

        my $folder1 = @{$res->{breadcrumbs}}[1];
        my $folder2 = @{$res->{breadcrumbs}}[2];

        $breadcrumbs = $breadcrumbs.$res->{title};
        $worksheet->write($row, $column, $breadcrumbs);
        warn Dumper Encode::encode('utf8',$breadcrumbs);
        $column = $column+1;
        $worksheet->write($row, $column, $res->{title});
        warn Dumper Encode::encode('utf8',$res->{title});
        $column = $column+1;

        my $first_table ='';
        foreach my $ps (@{$res->{first}->{ps}}){
            $first_table = $first_table.Encode::encode('utf8',$ps)."\n";
        }

        my $number = Encode::encode('utf8',$res->{div});
        # warn Dumper $number;
        $number =~ /\s(\d+)/; 
        $number = $1;
        # warn Dumper $number;
        $first_table = $first_table.Encode::encode('utf8',$res->{first}->{strong}." $number")."\n";

        my $details='';
        foreach my $detail (@{$res->{first}->{det}}){
            $details = $details.'- '.$detail."\n";
        }
        $first_table = $first_table.$details;

        warn Dumper Encode::encode('utf8',$first_table);
        $worksheet->write($row, $column, Encode::encode('utf8',$first_table));
        $column = $column+1;

        my $table='';
        my @tokens = @{$res->{tds}};
        # warn Dumper @tokens;
        for(my $c=0; $c<=$#tokens; $c=$c+2){
            # warn Dumper $c;
            if (@tokens[$c+1] eq '✓'){
                @tokens[$c+1] = 'ja';
            }
            $table = $table.@tokens[$c].'   '.@tokens[$c+1]."\n";
        }
        warn Dumper Encode::encode('utf8',$table);
        $worksheet->write($row, $column, Encode::encode('utf8',$table));
        $column = $column+1;

        warn Dumper $res->{image};
        my $pic = new Image::Grab;
        $pic->url($res->{image});
        $pic->grab;
        if(!(-e "Images/$folder1" and -d "Images/$folder1")){
            mkdir "Images/$folder1";
        }
        if(!(-e "Images/$folder1/$folder2" and -d "Images/$folder1/$folder2")){
            mkdir "Images/$folder1/$folder2";
        }
        $res->{title} =~ s/\// /;
        warn Dumper $res->{title};
        open(IMAGE, ">Images/$folder1/$folder2/$res->{title}.png") || die"$res->{title}.png: $!";
        binmode IMAGE;
        print IMAGE $pic->image;
        close IMAGE;

        $row = $row+1;
    };
    warn $@ if $@;
}