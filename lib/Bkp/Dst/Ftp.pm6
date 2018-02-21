use Bkp;
use Bkp::Dst;

unit class Bkp::Dst::Ftp is Bkp::Dst;

has Str $.hostname is required;
has Str $.path     = "/{ qx{hostname -s}.trim }";
has Str $.username = 'anonymous';
has Str $.password = 'test@test.com';

method !run-ncftp ( *%opt ) {
    my $url = "ftp://$!hostname$!path/";
    my $null = %*ENV<BKP_LOG> ?? $*OUT !! open '/dev/null', :w;
    return run «ncftp -u $!username -p $!password $url», :err($null), |%opt;
}

method mk_path () {
    return if $!path eq '/'|'.';
    my $path = $!path;
    $!path   = '/';
    my $null = %*ENV<BKP_LOG> ?? $*OUT !! open '/dev/null', :w;
    my $proc = self!run-ncftp: :in, :out($null);
    for $path.split('/') -> $dir {
        next if !$dir.chars;
        next if $dir eq '.';
        $proc.in.put: "mkdir $dir";
        $proc.in.put: "cd $dir";
    }
    $proc.in.close;
    $null.close unless %*ENV<BKP_LOG>;
    $!path = $path;
}

method enumerate () {
    self.mk_path;
    my $proc = self!run-ncftp: :in, :out;
    $proc.in.put: 'ls -la';
    $proc.in.close;
    my @files;
    for $proc.out.lines -> $line {
        my ( $size, $file ) = split( /\s+/, $line)[ 4, 8 ];
        next if !$file or !$size;
        push @files, {
          file => $file,
          size => $size,
        };
    }
    return @files;
}

method send ( Str $archive ) {
    my $filename = $!path.ends-with('/')
      ?? "$!path$archive" !! "$!path/$archive";
    $filename = ".$filename" if $filename.starts-with('/');
    run «ncftpput -c -u $!username -p $!password $!hostname $filename»,
      :in($.src.out);
}

method delete ( Str $archive ) {
    my $null = %*ENV<BKP_LOG> ?? $*OUT !! open '/dev/null', :w;
    my $proc = self!run-ncftp: :in, :out($null);
    $proc.in.put: "rm $archive";
    $proc.in.close;
    $null.close unless %*ENV<BKP_LOG>;
}

method build-receive-cmd ( Str $archive ) {
    my $url = "ftp://$!hostname/$!path/$archive";
    return «ncftpget -c -u $!username -p $!password $url»;
}
