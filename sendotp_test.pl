#!/usr/bin/perl -w

use REST::Client;

#use Cpanel::JSON::XS qw(encode_json decode_json);
use Data::Dumper;
use DateTime;
use Crypt::Random qw( makerandom ); 
use Digest::SHA qw(hmac_sha1_hex hmac_sha256_hex hmac_sha256_base64);
use Cpanel::JSON::XS qw(encode_json decode_json);
use MIME::Base64;

#use lib '/home/rene/git/chasquimobile_webservices/library/Merchant';
use Xioncomm::API;
 
my $otp= API->new(apikey=>'56a5e7e1a327be4be6');

my $res=$otp->sendOTP('sms','584126220038','xfy23','es');

#
#print $res->{Error}->{messages}[0]->{description}."\n";
print Dumper($res);

