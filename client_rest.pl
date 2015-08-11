#!/usr/bin/perl -w

use REST::Client;
use Cpanel::JSON::XS qw(encode_json decode_json);
use Data::Dumper;
use DateTime::Format::ISO8601;
use LWP::UserAgent;
use POSIX::strftime::GNU;
use Digest::SHA qw(sha1_hex hmac_sha1_base64);

my $ws= REST::Client->new();
my $host= "https://api.demo.globalgatewaye4.firstdata.com";
my $path="/transaction/v19";
$ws->setHost($host);

# HMAC KEY and ID
my $KEYID = "270305"; #Key ID from Terminal Settings
my $HMACKey = "cbeuqxWAi7P4~3qyzfsmMqTpnc6Z~BjX"; #HMAC Key from Terminal Settings

# Determine "next year" for the expiry date
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime time;
my $nextyear = $year - 99;

# Header values
my $contenttype = "application/json";
my $now = time();
my $iso8601 = POSIX::strftime('%Y-%m-%dT%H:%M:%SZ',gmtime($now));

my $requestmethod = "POST";
	
#data
my $data = {
			  ExactID => "AJ5312-05", #Gateway ID from Terminal Settings
			  Password => "14js1r90qr78ac9kf1757d6gomj5v6a0", #Gateway Password from Terminal Settings
			  Transaction_Type => "00",
			  DollarAmount => "150.00",
			  Card_Number => "4111111111111111",
			  Expiry_Date => "01$nextyear",
			  CardHoldersName => "Perl Webservice Test",
		};

my $payload= encode_json($data);
	print Dumper($payload);

 # Content Digest SHA1 Hexidecimal
    my $sha1_dig = sha1_hex($payload);
    my $sha1_digest = lc $sha1_dig;

    # HMAC Data string
    my $HMACdata = $requestmethod."\n".$contenttype."\n".$sha1_digest."\n".$iso8601."\n".$path;
    
    # HMAC Hash SHA256 Binary Base64
    my $HMACHash = hmac_sha1_base64($HMACdata, $HMACKey);
    
    # Pad B64 HMAC Hash
    while (length($HMACHash) % 4) {
        $HMACHash .= "=";
    }

my $auth= "GGE4_API ".$KEYID.":".$HMACHash;

my $headers = {Content_Type => $contenttype,Authorization =>$auth,'X-GGe4-Date'=>$iso8601,'X-GGe4-Content-SHA1'=>$sha1_digest,Accept=>$contenttype};

	
	$ws->POST("$path",($payload,$headers));
	print Dumper($ws->responseContent());
	my $res= decode_json($ws->responseContent());
	print Dumper($res);