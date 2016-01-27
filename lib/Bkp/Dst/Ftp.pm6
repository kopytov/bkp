use Bkp;
use Bkp::Dst;

unit class Bkp::Dst::Ftp is Bkp::Dst;

has Str $.hostname is required;
has Str $.path     = '/';
has Str $.username = 'anonymous';
has Str $.password = 'test@test.com';

method !run-ncftp ( *%opt ) {
    my $url = "ftp://$!hostname$!path";
    return run «ncftp -u $!username -p $!password $url», |%opt;
}

method enumerate () {
    my $proc = self!run-ncftp: :in, :out;
    $proc.in.put: 'ls -1';
    $proc.in.close;
    return $proc.out.lines;
}

method send () {
    my $archive  = self.next-archive;
    my $filename = $!path.ends-with('/')
      ?? "$!path$archive" !! "$!path/$archive";
    $filename = ".$filename" if $filename.starts-with('/');
    my $proc = run «ncftpput -c -u $!username -p $!password
      $!hostname $filename», :in($.src.out);
}

method delete ( Str $archive ) {
    my $null = open '/dev/null', :w;
    my $proc = self!run-ncftp: :in, :out($null);
    $proc.in.put: "rm $archive";
    $proc.in.close;
    $null.close;
}
