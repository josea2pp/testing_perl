#!/usr/bin/perl -w

use REST::Client;
use 5.014;
#use Cpanel::JSON::XS qw(encode_json decode_json);
use Data::Dumper;
use DateTime;
use Crypt::Random qw( makerandom ); 
use Digest::SHA qw(hmac_sha1_hex hmac_sha256_hex hmac_sha256_base64);
use Cpanel::JSON::XS qw(encode_json decode_json);
use MIME::Base64;

use lib '/home/rene/git/chasquimobile_webservices/library/lib';
use Merchant::Payeezy;
 

my $pay= Payeezy->new(apikey=>'tndJGAOHNnRAgmiRutMXAvJPemBWxeve',
					  apisecret=>'6f7c2ffebd329496056640c96fec7ca9a13e34a05acffeb343a77ac4e93d9d00',
					  token=>'fdoa-51c7cb34581916f8372a98da9210207f51c7cb34581916f8');

my %request = (
       			'amount'=>"1299",
       			'card_number'=>"4788250000028291",
       			'card_type'=>"visa",
       			"card_holder_name" => "John Smith",
		        "card_cvv" => "123",
		        "card_expiry" => "1020",
		        "merchant_ref" => "Astonishing-Sale",
		        "currency_code" => "usd",
);

my $res =$pay->purchase(%request);

#print $res->{Error}->{messages}[0]->{description}."\n";
print Dumper($res);
