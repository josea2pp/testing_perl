#!/usr/bin/perl -w

use REST::Client;

use Data::Dumper;
use DateTime;
use Crypt::Random qw( makerandom ); 
use Digest::SHA qw(hmac_sha1_hex hmac_sha256_hex hmac_sha256_base64);
use Cpanel::JSON::XS qw(encode_json decode_json);
use MIME::Base64;

 

my $time= DateTime->now;
#
my $ws= REST::Client->new();
	my $host='https://api.payeezy.com';
	my$path="/v1/transactions";
	$ws->setHost($host);
#
my $random= makerandom ( Size => 64, Strength => 1 ); 
my $nonce=$random;
#
my $apikey="api here";
my $apisecret="api secret here";
my $token="token here";

my $request = {
       			merchant_ref=>"Astonishing-Sale",
       			transaction_type=>"purchase",
       			method=>"credit_card",
       			amount=>"1299",
       			partial_redemption => "false",       			
       			currency_code=>"USD",
       			credit_card => 
                { 
                	type => "visa",
                	cardholder_name => "John Smith",
                	card_number=>"4788250000028291",
                	exp_date=>"1020",
                	cvv=>"123"               	
                	
                },
               
};
    
#my $jsonobj=encode_json($request);
my $jsonobj='{
  "merchant_ref": "Astonishing-Sale",
  "transaction_type": "purchase",
  "method": "credit_card",
  "amount": "1299",
  "partial_redemption": "false",
  "currency_code": "USD",
  "credit_card": {
    "type": "visa",
    "cardholder_name": "John Smith",
    "card_number": "4788250000028291",
    "exp_date": "1020",
    "cvv": "123"
  }
}';


#print $jsonobj;
## Get an expires at time, and set it for 5 minutes in the future.
	my $expires_at = ($time->epoch() + (5*60));
#		
#		
	my $hmacdata ="";
	$hmacdata .="$apikey";
	$hmacdata .="$nonce";
	$hmacdata .="$expires_at";
	$hmacdata .="$token";	
	$hmacdata .="$jsonobj";
 
print $hmacdata."\n";
## Fix padding of Base64 digests
	my $sha256hex = hmac_sha256_hex($hmacdata,$apisecret);
	while (length($sha256hex) % 4) {
	    $sha256hex .= '=';
	}  

	my $auth =encode_base64($sha256hex);
	$auth =~ y/\n//d;
	
my $headers = {Content_Type => 'application/json',apikey => $apikey,token=>$token, Authorization=> $auth,nonce=>"$nonce",timestamp=>"$expires_at"};

print Dumper($headers)."\n";	

	$ws->POST("$path",($jsonobj,$headers));
	
	my $res= decode_json($ws->responseContent());
	
	print Dumper($res);	
