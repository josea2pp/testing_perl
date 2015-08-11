package Payeezy;
use Moose;
use REST::Client;
use 5.014;
use Data::Dumper;
use DateTime;
use Crypt::Random qw( makerandom );
use Digest::SHA qw(hmac_sha1_hex hmac_sha256_hex hmac_sha256_base64);
use Cpanel::JSON::XS qw(encode_json decode_json);
use MIME::Base64;

use constant URL => "https://api-cert.payeezy.com";
use constant URL_PATH => "/v1/transactions";

my $time= DateTime->now;


# Parameters
has 'apikey' =>(isa=>'Str',is=>'rw');
has 'apisecret' =>(isa=>'Str',is=>'rw');
has 'token' =>(isa=>'Str',is=>'rw');
has 'text' =>(isa=>'Str',is=>'rw');
has 'sender' =>(isa=>'Str',is=>'rw');
has 'nonce' =>(isa=>'Int',is=>'rw');
has 'timestamp' =>(isa=>'Int',is=>'rw');
has 'path' =>(isa=>'Str',is=>'rw');


=pod

=head1 payload

generate the payload data to json format

=head2 Parameters

 $type => 'authorize' or 'purchase' or 'capture' or 'void' or 'refund' or recurring or 'split'  

 %args => (
       			'amount'=>"",
       			'card_number'=>"",
       			'card_type'=>"",
       			"card_holder_name" => "",
		        "card_cvv" => "",
		        "card_expiry" => "",
		        "merchant_ref" => "",
		        "currency_code" => "",
		        "transaction_tag" => "",
		        "split_shipment" => "",
		        "transaction_id" => ""
);
=cut

sub payload {
	my ($self,$type,%args) = @_;
	my ($payload,$data);
	
	if($type eq 'authorize' || $type eq 'purchase') {
	
			$data=  {
       			merchant_ref=>$args{merchant_ref},
       			transaction_type=>$type,
       			method=>'credit_card',
       			amount=>$args{amount},
       			currency_code=>uc($args{currency_code}),
       			credit_card => 
                { 
                	type => $args{card_type},
                	cardholder_name => $args{card_holder_name},
                	card_number=>$args{card_number},
                	exp_date=>$args{card_expiry},
                	cvv=>$args{card_cvv}               	
                	
                },
               
			};
			
			$self->{path}=URL_PATH;
	}
	elsif($type eq 'split') {
		
		$data=  {
       			merchant_ref=>$args{merchant_ref},
       			transaction_type=>$type,
       			method=>'credit_card',
       			amount=>$args{amount},
       			currency_code=>uc($args{currency_code}),
       			transaction_tag=>$args{transaction_tag},
       			split_shipment=>$args{split_shipment},
               
			};
				$self->{path}=URL_PATH."/$args{transaction_id}";
			
		
	}
	elsif($type eq 'recurring'){
		
		$data=  {
       			merchant_ref=>$args{merchant_ref},
       			transaction_tag=>$args{transaction_tag},
       			transaction_type=>$type,
       			amount=>$args{amount},
       			currency_code=>uc($args{currency_code}),
               
			};
				$self->{path}=URL_PATH."/$args{transaction_id}";
		
	}
	elsif ($type eq 'capture' || $type eq 'refund' || $type eq 'void') {
		$data= {
				merchant_ref=>$args{merchant_ref},
				transaction_tag=>$args{transaction_tag},
				transaction_type=>$type,
				method=>'credit_card',
				amount=>$args{amount},
				currency_code=> uc($args{currency_code}),
				
			};
				$self->{path}=URL_PATH."/$args{transaction_id}";
		
	}
	
	
		 	$payload= encode_json($data);
		print Dumper($payload);
			return $payload;	
}

=pod

=head1 PayPal payload

generate the payload data to json format for paypal merchant

=head2 Parameters
 
 $type = "authorize" or "order" or "purchase"
 
 %args => (
       			'amount'=>"",
       			'merchant_ref'=>"",
       			"currency_code" => "",
		        "timestamp" => "",
		        "authorization" => "",
		        "success" => "",
		        "message" => "",
		        "correlation_id" => "",
		        "payer_id" => "",
		        "gross_amount_currency_id"=>"",
		        "cardholder_name" =>""
		        
);
=cut


sub payloadPaypal {
	my($self,$type,%args)=@_;
	my ($payload,$data);
	
	$data=  {
       			amount=> $args{amount},
       			transaction_type=> $type,
       			merchant_ref=> $args{merchant_ref},
       			method => "paypal",
		        currency_code => $args{currency_code} ,
		        timestamp => $args{timestamp},
		        authorization => $args{authorization} ,
		        success => $args{success},
		        message => $args{message},
		        correlation_id => $args{correlation_id} ,
		        payer_id => $args{payer_id} ,
		        gross_amount_currency_id=> $args{gross_amount_currency_id},
		        cardholder_name => $args{cardholder_name}               
			};
				$self->{path}=URL_PATH;
	
			$payload= encode_json($data);
		
			return $payload;	
}

sub hmacAuthToken {
	my ($self,$payload)=@_;
	my $nonce=makerandom(Size => 64, Strength => 1);
	my $time= DateTime->now;
#	set it for 5 minutes in the future.
	my $expires_at = ($time->epoch() + (5*60));
	my $hmacdata ="";
	$hmacdata .=$self->{apikey};
	$hmacdata .="$nonce";
	$hmacdata .="$expires_at";
	$hmacdata .=$self->{token};	
	$hmacdata .="$payload";
	
	
	## Fix padding of Base64 digests
	my $sha256hex = hmac_sha256_hex($hmacdata,$self->apisecret);
	while (length($sha256hex) % 4) {
	    $sha256hex .= '=';
	}  

	my $authtoken =encode_base64($sha256hex);
	$authtoken =~ y/\n//d;
	
	my $res={'authtoken'=>"$authtoken",'nonce' =>"$nonce","timestamp"=>"$expires_at"};
		print Dumper($res);
	return $res;
}

sub transactionPOST {
	my ($self,$payload,$authtoken)=@_;
	my $ws= REST::Client->new();
	my $host=URL;
	my $path=$self->path;
	$ws->setHost($host);
	
	my $headers = {Content_Type => 'application/json',apikey => $self->{apikey},token=>$self->{token}, Authorization=> $authtoken->{authtoken},nonce=>"$authtoken->{nonce}",timestamp=>$authtoken->{timestamp}};
	
	print Dumper($headers);	
	print Dumper($payload);
	$ws->POST("$path",($payload,$headers));
	
	my $res= decode_json($ws->responseContent());
	return $res;
}

=pod

=head1 authorize

generate the authorize request

=head2 Parameters

 %args => (
       			'amount'=>"",
       			'card_number'=>"",
       			'card_type'=>"",
       			"card_holder_name" => "",
		        "card_cvv" => "",
		        "card_expiry" => "",
		        "merchant_ref" => "",
		        "currency_code" => "",
		       
);
=cut



sub authorize {
	my ($self,%args) = @_;
	
	my $payload=$self->payload('authorize',%args);
	my $authtoken= $self->hmacAuthToken($payload);
			
	return $self->transactionPOST($payload,$authtoken);
	
	
}

=pod

=head1 purchase

generate the purchase request

=head2 Parameters

 %args => (
       			'amount'=>"",
       			'card_number'=>"",
       			'card_type'=>"",
       			"card_holder_name" => "",
		        "card_cvv" => "",
		        "card_expiry" => "",
		        "merchant_ref" => "",
		        "currency_code" => "",
		       
);
=cut

sub purchase {
	my ($self,%args) = @_;
	
	my $payload=$self->payload('purchase',%args);
	my $authtoken= $self->hmacAuthToken($payload);
	
	
	return $self->transactionPOST($payload,$authtoken);
	
	
}

=pod

=head1 capture

generate the capture request

=head2 Parameters

 %args => (
       			'amount'=>"",
       			"merchant_ref" => "",
		        "currency_code" => "",
		        "transaction_tag" => "",
		        "transaction_id" => ""
);
=cut

sub capture {
	my ($self,%args) = @_;
	
	my $payload=$self->payload('capture',%args);
	my $authtoken= $self->hmacAuthToken($payload);
	
	
	return $self->transactionPOST($payload,$authtoken);
	
	
}

=pod

=head1 refund

generate the refund request

=head2 Parameters

 %args => (
       			'amount'=>"",
       			"merchant_ref" => "",
		        "currency_code" => "",
		        "transaction_tag" => "",
		        "transaction_id" => ""
);
=cut

sub refund {
	my ($self,%args) = @_;
	
	my $payload=$self->payload('refund',%args);
	my $authtoken= $self->hmacAuthToken($payload);
	
	
	return $self->transactionPOST($payload,$authtoken);
	
	
}

=pod

=head1 void

generate the void request

=head2 Parameters

 %args => (
       			'amount'=>"",
       			"merchant_ref" => "",
		        "currency_code" => "",
		        "transaction_tag" => "",
		        "transaction_id" => ""
);
=cut

sub void {
	my ($self,%args) = @_;
	
	my $payload=$self->payload('void',%args);
	my $authtoken= $self->hmacAuthToken($payload);
	
	
	return $self->transactionPOST($payload,$authtoken);
	
	
}

=pod

=head1 recurring

generate the recurring request

=head2 Parameters

 %args => (
       			'amount'=>"",
       			"merchant_ref" => "",
		        "currency_code" => "",
		        "transaction_tag" => "",
		        "transaction_id" => ""
);
=cut

sub recurring {
	my ($self,%args) = @_;
	
	my $payload=$self->payload('recurring',%args);
	my $authtoken= $self->hmacAuthToken($payload);
	
	
	return $self->transactionPOST($payload,$authtoken);
	
	
}

=pod

=head1 split

generate the split request

=head2 Parameters

 %args => (
       			'amount'=>"",
       			"merchant_ref" => "",
		        "currency_code" => "",
		        "transaction_tag" => "",
		        "split_shipment" => "",
		        "transaction_id" => ""
);
=cut

sub split {
	my ($self,%args) = @_;
	
	my $payload=$self->payload('split',%args);
	my $authtoken= $self->hmacAuthToken($payload);
	
	
	return $self->transactionPOST($payload,$authtoken);
	
	
}


=pod

=head1 Paypal authorize

generate the purchase request for paypal merchant

=head2 Parameters

  %args => (
       			"amount"=>"",
       			"merchant_ref"=>"",
       			"currency_code" => "",
		        "timestamp" => "",
		        "authorization" => "",
		        "success" => "",
		        "message" => "",
		        "correlation_id" => "",
		        "payer_id" => "",
		        "gross_amount_currency_id"=>"",
		        "cardholder_name" =>""
		        
);

=cut

sub authorizePaypal {
	my ($self,%args) = @_;
	
	my $payload=$self->payloadPaypal('authorize',%args);
	my $authtoken= $self->hmacAuthToken($payload);
	
	
	return $self->transactionPOST($payload,$authtoken);
	
	
}




=pod

=head1 Paypal purchase

generate the purchase request for paypal merchant

=head2 Parameters

 %args => (
       			"amount"=>"",
       			"merchant_ref"=>"",
       			"currency_code" => "",
		        "timestamp" => "",
		        "authorization" => "",
		        "success" => "",
		        "message" => "",
		        "correlation_id" => "",
		        "payer_id" => "",
		        "gross_amount_currency_id"=>"",
		        "cardholder_name" =>""
		        
);
=cut

sub purchasePaypal {
	my ($self,%args) = @_;
	
	my $payload=$self->payloadPaypal('purchase',%args);
	my $authtoken= $self->hmacAuthToken($payload);
	
	
	return $self->transactionPOST($payload,$authtoken);
	
	
}

=pod

=head1 Paypal order

generate the order request for paypal merchant

=head2 Parameters

 %args => (
       			"amount"=>"",
       			"merchant_ref"=>"",
       			"currency_code" => "",
		        "timestamp" => "",
		        "authorization" => "",
		        "success" => "",
		        "message" => "",
		        "correlation_id" => "",
		        "payer_id" => "",
		        "gross_amount_currency_id"=>"",
		        "cardholder_name" =>""
		        
);
=cut

sub orderPaypal {
	my ($self,%args) = @_;
	
	my $payload=$self->payloadPaypal('order',%args);
	my $authtoken= $self->hmacAuthToken($payload);
	
	
	return $self->transactionPOST($payload,$authtoken);
	
	
}

    no Moose;
1;



