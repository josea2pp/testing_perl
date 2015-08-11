#!/usr/bin/perl -w
# Perl sample code to use against the First Data Payeezy Gateway Webservice API: https://api.globalgatewaye4.firstdata.com
# Code consumes Version 19 of the Payeezy Gateway WSDL
# AUTHOR: Eric M. Payne
# Copyright © 2015 First Data Corporation. All rights reserved.
# Last Updated: 23 April 2015
#
# Requirements:
# Perl v5.8.8
# SOAP::Lite http://soaplite.com
# Crypt::SSLeay for https support
# DateTime::Format::ISO8601 https://metacpan.org/release/DateTime-Format-ISO8601
# OPTIONAL: Data::Dumper http://search.cpan.org/~smueller/Data-Dumper-2.125/
# POSIX::strftime::GNU http://search.cpan.org/~dexter/POSIX-strftime-GNU-0.0305/lib/POSIX/strftime/GNU.pm
# LWP::UserAgent http://search.cpan.org/dist/libwww-perl/lib/LWP/UserAgent.pm
# HTTP::Request http://search.cpan.org/~gaas/HTTP-Message-6.06/lib/HTTP/Request.pm
# 

use SOAP::Lite + trace => 'debug';
use HTTP::Request;
use Data::Dumper;
use DateTime::Format::ISO8601;
use LWP::UserAgent;
use POSIX::strftime::GNU;

# To enable Production URL: Comment Line 28, then Uncomment Line 31
# Demo URL to APIto API
my $proxy = "https://api.demo.globalgatewaye4.firstdata.com/transaction/v19";

# Prod URL to API
#my $proxy = "https://api.globalgatewaye4.firstdata.com/transaction/v19";

# Submission URL
my $url = "http://secure2.e-xact.com/vplug-in/transaction/rpc-enc/SendAndCommit";

# Initialize SOAP Client
my $client = SOAP::Lite    ->proxy($proxy)
    ->ns('http://secure2.e-xact.com/vplug-in/transaction/rpc-enc/Request','ns1')
    ->uri($url)    
    ;
# Add Handler to SOAP Client to intercept SOAP Package and create HMAC Hash and HTTP Headers
$client->transport->add_handler("request_prepare", \&modify_header );
$client->on_action(sub { qq("$_[0]") });


# HMAC KEY and ID
my $KEYID = "270305"; #Key ID from Terminal Settings
my $HMACKey = "yWwPOlIvyl8owkukRY4Il9jUg3UeNQkt"; #HMAC Key from Terminal Settings

# Determine "next year" for the expiry date
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime time;
my $nextyear = $year - 99;

# Transaction properties
my %trxnProperties = (
  "ExactID" => "AJ5312-05", #Gateway ID from Terminal Settings
  "Password" => "hyb4m05w6sb826sijtzieyv6cxr1hh5c", #Gateway Password from Terminal Settings
  "Transaction_Type" => "00",
  "DollarAmount" => "150.00",
  "Card_Number" => "4111111111111111",
  "Expiry_Date" => "01$nextyear",
  "CardHoldersName" => "Perl Webservice Test",
);

my %trxn = ("Transaction" => \%trxnProperties);

# Header values
my $contenttype = "text/xml";
my $now = time();
my $iso8601 = POSIX::strftime('%Y-%m-%dT%H:%M:%SZ', gmtime($now));
my $requestmethod = "POST";
my $request_uri = "/transaction/v19";

sub modify_header {
    # Capture SOAP Request
    my ($client, $ua, $h) = @_;
    $SOAP_Request = $client->content;
    
    # Content Digest SHA1 Hexidecimal
    use Digest::SHA qw(sha1_hex);
    my $sha1_dig = sha1_hex($SOAP_Request);
    my $sha1_digest = lc $sha1_dig;

    # HMAC Data string
    my $HMACdata = $requestmethod."\n".$contenttype."\n".$sha1_digest."\n".$iso8601."\n".$request_uri;
    
    # HMAC Hash SHA256 Binary Base64
    use Digest::SHA qw(hmac_sha1_base64);
    my $HMACHash = hmac_sha1_base64($HMACdata, $HMACKey);
    
    # Pad B64 HMAC Hash
    while (length($HMACHash) % 4) {
        $HMACHash .= "=";
    }
    
    # Add HTTP Headers
    $client->header("Content-Type" => $contenttype);
    $client->header("Accept" => $contenttype);
    $client->header("Authorization" => "GGE4_API".$KEYID.":".$HMACHash);
    $client->header("X-gge4-date" => $iso8601);
    $client->header("X-gge4-content-sha1" => $sha1_digest);
}

# Process the payment
my $result = $client-> Process(\%trxn);

print Dumper($result);