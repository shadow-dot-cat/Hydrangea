package Hydrangea::Utils;

use Exporter 'import';
use Hydrangea::Package;
use Digest::SHA qw(sha1_hex);

our @EXPORT_OK = qw(match_pw hash_pw);

sub hash_pw ($pw) {
  my $salt = join '', map sprintf("%x", int rand 16), 1..16;
  my $hash = sha1_hex("${salt}:${pw}");
  return "sha1_hex:${salt}:${hash}";
}

sub match_pw ($hash, $pw) {
  my ($type, $salt, $real_hash) = split ':', $hash;
  die "Only sha1_hex type exists but got ${type}" unless $type eq 'sha1_hex';
  return $real_hash eq sha1_hex("${salt}:${pw}");
}

1;
