use Bkp;
use Bkp::Dst;

unit class Bkp::Dst::Local is Bkp::Dst;

has Str $.dir is required;
has     %.mount;

method enumerate () {
    my @files;
    for $!dir.IO.dir.sort.map: { .basename, .s } -> $file {
        push @files, {
          file => $file[0],
          size => $file[1],
        };
    }
    return @files;
}

method send ( Str $archive ) {
    my $filename = "$!dir/$archive";
    my $fh       = open $filename, :bin, :w;
    my $proc     = run 'cat', :in($.src.out), :out($fh);
    $fh.close;
    return $proc;
}

method delete ( Str $archive ) {
    my $filename = "$!dir/$archive";
    $filename.IO.unlink;
}

method build-receive-cmd ( Str $archive ) {
    my $filename = "$!dir/$archive";
    return «cat $filename»;
}

method mount {
    return unless %!mount.elems;
    fail 'mount.point should be defined' unless %!mount<point>:exists;
    my Proc $proc;
    my DirPath $mountpoint = %!mount<point>;
    $proc = run <<mountpoint -q $mountpoint>>;
    return if $proc.exitcode == 0;

    my @mount = %!mount<cmd>:exists ?? |%!mount<cmd> !! <<mount $mountpoint>>;
    $proc = run |@mount;
    fail 'mount command returned non-zero code' if $proc.exitcode;

    $proc = run <<mountpoint -q $mountpoint>>;
    fail 'mountpoint actually not mounted after mount' if $proc.exitcode;

    my DirPath $endpoint = $!dir;
}

method umount {
    return unless %!mount<umount>;
    fail 'mount.point should be defined' unless %!mount<point>:exists;
    my Proc $proc;
    my DirPath $mountpoint = %!mount<point>;
    $proc = run <<mountpoint -q $mountpoint>>;
    return if $proc.exitcode;

    $proc = run <<umount $mountpoint>>;
    fail 'umount command returned non-zero code' if $proc.exitcode;
}
