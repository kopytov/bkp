use Bkp;
use Bkp::Dst;

unit class Bkp::Dst::Local is Bkp::Dst;

has DirPath $.dir is required;

method enumerate () {
    $!dir.IO.dir.map: { .basename };
}

method send () {
    my $filename = "$!dir/{self.next-archive}";
    my $fh       = open $filename, :bin, :w;
    run 'cat', :in($.src.out), :out($fh);
    $fh.close;
}

method delete ( Str $archive ) {
    my $filename = "$!dir/$archive";
    $filename.IO.unlink;
}

