use Bkp;
use Bkp::Dst;

unit class Bkp::Dst::Ftp is Bkp::Dst;

has Str $.hostname is required;
has Str $.path     = "{ qx{hostname -s}.trim }";
has Str $.username = 'anonymous';
has Str $.password = 'test@test.com';
has Int $.port     = 21;
has Str $.encoding = 'UTF-8';

method !run-ncftp ( *%opt ) {
    my $url  = $!path eq '/'|'.'       ?? "ftp://$!hostname/"
            !! $!path.starts-with('/') ?? "ftp://$!hostname$!path"
            !!                            "ftp://$!hostname/$!path"
            ;
    my $null = %*ENV<BKP_LOG> ?? $*OUT !! open '/dev/null', :w;
    return run «ncftp -u $!username -p $!password -P $!port $url»,
      :err($null),
      :enc($!encoding),
      |%opt;
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
        next if $line ~~ rx{ 'http://www.NcFTP.com/contact/' };
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
    return run «ncftpput -c -u $!username -p $!password -P $!port $!hostname $filename»,
      :in($.src.out),
      :enc($!encoding);
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
    return «ncftpget -c -u $!username -p $!password -P $!port $url»;
}
