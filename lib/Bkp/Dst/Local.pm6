use Bkp::Dst;
use Bkp::Types;

unit class Bkp::Dst::Local is Bkp::Dst;

has DirPath $.dir is required;

method enumerate () {
    $!dir.IO.dir.map: { .basename };
}

method send () {
    my $filename = "$!dir/{self.next-archive}";
    my $fh       = open $filename, :bin, :w;
    while ( my $buf = $.src.out.read(262_144) ) {
        $fh.write($buf);
    }
    $fh.close;
}

method delete ( Str $archive ) {
    my $filename = "$!dir/$archive";
    $filename.IO.unlink;
}

