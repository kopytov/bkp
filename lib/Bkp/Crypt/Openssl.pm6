use Bkp;
use Bkp::Middleware;

unit class Bkp::Crypt::Openssl is Bkp::Middleware;

has Str @.cmd = <openssl enc>;
has Str $.add-suffix = 'enc';
has Str $.key is required;
has Cipher $.cipher = 'aes-256-cbc';

method suffix () {
    "{$.src.suffix}.$!add-suffix";
}

method build-cmd () {
    my @cmd = @!cmd.clone;
    @cmd.push: "-$!cipher";
    @cmd.append: «-k $!key»;
    return @cmd;
}
