package Net::OSLC::CM::ServiceProvider;

use Any::Moose;
use LWP::UserAgent 6;

=head1 NAME

Net::OSLC::CM::ServiceProvider - OSLC-CM Service Provider class

=head1 VERSION

This document describes Net::OSLC::CM::ServiceProvider version 0.01

=head1 DESCRIPTION

(from open-services.net)
Service Provider: an implementation of the OSLC Change Management specifications as a server. OSLC CM clients consume these services.

=cut

has cm => (
  isa => 'Net::OSLC::CM',
  is => 'rw',
);

has url => (
  isa => 'Str',
  is => 'rw',
);  

has services => (
  isa => 'ArrayRef',
  is => 'rw',
  default => sub { [] },
);

has services_url => (
  isa => 'ArrayRef',
  is => 'rw',
  default => sub { [] },
);


=head1 METHODS

=over

=item C<< get_service_provider ( $connection, $url ) >>

Performs a GET HTTP request to get XML data for a given Service Provider.
Returns the body of the HTTP response as a string.

It takes a Net::OSLC::CM::Connection object $connection and the URL of the targeted Service Provider as arguments.

=cut

sub get_service_provider {
  my $self = shift;
  my $connection = shift;
  my $url = shift;

  my $ua = LWP::UserAgent->new();
  # Uncomment the following line if you have SSL cert verification issues (like "500 Can't connect to example.com:443 (certificate verify failed)")
  #$ua->ssl_opts( verify_hostname => 0 );

  my $request = HTTP::Request->new(GET => $url);
  
  $request->header('Accept' => 'application/rdf+xml');
  $request->authorization_basic($connection->username, $connection->password);
  
  my $http_response = $ua->request( $request );

  if ($http_response->is_success) {
    my $body = $connection->get_http_body($http_response);
    return $body; 
   }
   else {
     print $http_response->status_line . "\n";
     return;
   }
}

=item C<< parse_service_provider ( $parser, $rdf_data) >>

Parses RDF/XML data that we got from the HTTP request for a given Service Provider and returns the RDF model.

=cut

sub parse_service_provider {
  my $self = shift;
  my ($parser, $body) = @_;
  
  my $model = $parser->parse_xml_ressources($self->url, $body);
  return $model; 
}

sub query_services {
  my $self = shift;
  my $parser = shift;
  my $model = shift;
  my $arrayref = [];

  my $rdf_query = "SELECT DISTINCT ?url WHERE  { ?url rdf:type <http://open-services.net/ns/core#Service> }";
  $parser->query_rdf($model, $rdf_query, $arrayref);

  my $i = 0;
  for ( $i=0; $i < @{$arrayref}; $i++){
      my $service = ${$arrayref}[$i]->{ 'url' }->uri_value;
      if ($service =~ m/https?:\/\/(.*)/ and $service !~ m/$self->url/){
        push($self->services_url, $service);
      }

  }

}

=item C<< query_resource >>

Performs a query in an OSLC service to find properties such as
queryCapability or resourceShape. 

=cut 

# sub query_resource {
#   my $self = shift;
#   my ($parser, $model, $resource, $property, $result) = @_;

#   my $rdf_query = "SELECT ?y WHERE
#                     {
#                     ?z oslc:" . $resource . " ?x .
#                     ?x oslc:" . $property . " ?y .
#                     }";
                  
#   print "$rdf_query \n";

#   $parser->query_rdf($model, $rdf_query, $result);

#   print Dumper($result);
#   my $i = 0;
#   for ( $i=0; $i < @{$result}; $i++){
#     if ( ${$result}[$i] =~ m/{ y=<(.*)> }/){
#       ${$result}[$i] = $1;
#       print ${$result}[$i] . "\n";
#     }
#   }
# }

1;

=back
