package PPM::SOAPClient;

###############################################################################
# Required inclusions.
###############################################################################
use strict;                         # Activate compile-time syntax checking
use SOAP::EnvelopeMaker;            # Needed for connecting to SOAP server
use SOAP::Transport::HTTP::Client;  # Needed for connecting to SOAP server
use SOAP::Parser;                   # Needed for parsing results from SOAP srvr

###############################################################################
# Get our version number out of the CVS revision number.
###############################################################################
use vars qw( $VERSION );
$VERSION = do { my @r = q$Revision: 1.1 $ =~ /\d+/g; sprintf '%d.'.'%02d'x$#r, @r };

###############################################################################
# Package-wide variables.
###############################################################################
    ###########################################################################
    # Specifies the URN to the information about the SOAP interface for PPM.
    ###########################################################################
# UNFINISHED -> We need a real URN for the SOAP interface for PPM.
my $SOAP_URN = 'urn:localhost';

###############################################################################
# Subroutine:   new ($server)
# Parameters:   $server     - URL to SOAP server
###############################################################################
# Instantiates a new SOAP client, specifying the server that will be used for
# all later connections.  '$server' should be provided as the URL to the SOAP
# server that we're going to connect to and make queries against.
#
# Note, that this method accepts both "http://" and "soap://" server URLs
# exactly the same way (we treat 'soap://' URLs as standard HTTP URLs).
###############################################################################
sub new
{
    my ($class, $server) = @_;
    my $self = {};
    bless $self, $class;
    $server =~ s/^soap:/http:/io;
    $self->{'_server'} = $server;
    $self->{'_urn'} = $SOAP_URN;
    return $self;
}

###############################################################################
# Subroutine:   version ()
###############################################################################
# Gets the version number of the SOAP server that we're connected to.  If we're
# unable to contact the server or its offline, this method returns 'undef'.
###############################################################################
sub version ()
{
    my ($self) = @_;
    my @response = $self->_makeSOAPRequest( 'version' );
    return 0 if (scalar @response == 0);
    return $response[0];
}

###############################################################################
# Subroutine:   searchAbstract ($search)
# Parameters:   $search     - Term to search for
# Returns:      $results    - Hash of package information for matching pkgs
###############################################################################
# Searches within the 'ABSTRACT' field within all of the packages held in the
# repository on the server.  The value '$search' may be a regex that will be
# used to match against the abstracts.  If no value for '$search' is provided,
# the server treats the search to be for '.*' (everything).
###############################################################################
sub searchAbstract ($)
{
    my ($self, $search) = @_;
    my @matches = $self->_makeSOAPRequest( 'searchAbstract',
                                           'search', $search );
    my %pkgs;
    map { $pkgs{$_->{'NAME'}} = $_ } @matches;
    return %pkgs;
}

###############################################################################
# Subroutine:   searchAuthor ($search)
# Parameters:   $search     - Term to search for
# Returns:      $results    - Hash of package information for matching pkgs
###############################################################################
# Searches within the 'AUTHOR' field within all of the packages held in the
# repository on the server.  The value '$search' may be a regex that will be
# used to match against the authors.  If no value of '$search' is provided, the
# server treats the search to be for '.*' (everything).
###############################################################################
sub searchAuthor ($)
{
    my ($self, $search) = @_;
    my @matches = $self->_makeSOAPRequest( 'searchAuthor',
                                           'search', $search );
    my %pkgs;
    map { $pkgs{$_->{'NAME'}} = $_ } @matches;
    return %pkgs;
}

###############################################################################
# Subroutine:   searchTitle ($search)
# Parameters:   $search     - Term to search for
# Returns:      $results    - Hash of package information for matching pkgs
###############################################################################
# Searches within the 'title' field within all of the packages held in the
# repository on the server.  The value '$search' may be a regex that will be
# used to match against the titles.  If no value of '$search' is provided, the
# server treats the search to be for '.*' (everything).
###############################################################################
sub searchTitle ($)
{
    my ($self, $search) = @_;
    my @matches = $self->_makeSOAPRequest( 'searchTitle',
                                           'search', $search );
    my %pkgs;
    map { $pkgs{$_->{'NAME'}} = $_ } @matches;
    return %pkgs;
}

###############################################################################
# Subroutine:   search ($search)
# Parameters:   $search     - Term to search for
# Returns:      $results    - Hash of package information for matching pkgs
###############################################################################
# Searches through all of the fields within all of the packages held in the
# repository on the server.  The value '$search' may be a regex that will be
# used to match against the field values.  If no value of '$search' is
# provided, the server treats the search to be for '.*' (everything).
###############################################################################
sub search ($)
{
    my ($self, $search) = @_;
    my @matches = $self->_makeSOAPRequest( 'search', 'search', $search );
    my %pkgs;
    map { $pkgs{$_->{'NAME'}} = $_ } @matches;
    return %pkgs;
}

###############################################################################
# Subroutine:   packages ()
# Returns:      @packages   - List of packages available in the repository
###############################################################################
# Generates a list of all of the packages currently available in the
# repository.  The value returned to the caller is a list containing the names
# of all of the packages in the repository.
###############################################################################
sub packages ()
{
    my ($self) = @_;
    my @stuff  = $self->_makeSOAPRequest( 'packages' );
    my @return = map { $_->{'NAME'} } @stuff;
    return @return;
}

###############################################################################
# Subroutine:   fetch_ppd ($pkg)
# Parameters:   $pkg        - Package to get PPD file for
# Returns:      $ppd        - Full contents of PPD in XML as a scalar
###############################################################################
# Fetches the PPD associated with a given package.  The full contents of the
# PPD are returned to the caller in XML format as a scalar value.
###############################################################################
sub fetch_ppd ($)
{
    my ($self, $pkg) = @_;
    $pkg =~ s/\.ppd$//gio;      # Strip any leftover '.ppd' extension.
    my @ppd = $self->_makeSOAPRequest( 'fetch_ppd', 'package', $pkg );
    return undef if (scalar @ppd == 0);
    return $ppd[0];
}

###############################################################################
# Subroutine:   fetch_summary ()
# Returns:      $summary    - Full summary of repository in XML as a scalar
###############################################################################
# Fetches the full summary of all of the packages held in the repository.  The
# full contents of the summary are returned to the caller in XML format as a
# scalar value.
###############################################################################
sub fetch_summary ()
{
    my ($self) = @_;
    my @response = $self->_makeSOAPRequest( 'fetch_summary' );
    return undef if (scalar @response == 0);
    return $response[0];
}

###############################################################################
# Subroutine:   _makeSOAPRequest ($method, $search)
# Returns:      @results    - List of package information
###############################################################################
# INTERNAL METHOD.  Makes the SOAP request to the server, doing the bulk of the
# actual work for us.
###############################################################################
sub _makeSOAPRequest
{
    my ($self, $method, @params) = @_;

    ###########################################################################
    # Build up the SOAP envelope that we're going to use.
    ###########################################################################
    my $soap_request = '';
    my $envelope = new SOAP::EnvelopeMaker( sub { $soap_request .= shift } );

    ###########################################################################
    # Set the parameters that we're going to send along in the SOAP call, and
    # put them into the envelope.
    ###########################################################################
# UNFINISHED -> Right now we've got a placeholder in here as the
#               PPM::SOAPServer module needs one to be able to parse the
#               request at its end.  This will need to be fixed before final
#               release.
    my $fcnparms = { 'placeholder' => undef, @params };
    $envelope->set_body( $self->{'_urn'}, $method, 0, $fcnparms );

    ###########################################################################
    # Create a SOAP client and do the call to the SOAP server.
    ###########################################################################
    my $soap   = new SOAP::Transport::HTTP::Client();
    my $result = $soap->send_receive(
                    $self->{'_server'},
                    $self->{'_urn'},
                    $method,
                    $soap_request );

    ###########################################################################
    # Create a parser to parse the response, and yank the response apart.
    ###########################################################################
    my $parser = new SOAP::Parser();
    my $rc     = $parser->parsestring( $result );
    my $body   = $parser->get_body();

    ###########################################################################
    # Take the response body that we just got back, and put it into a _list_
    # instead of the hash structure that we got back.  NOTE, that this is done
    # solely because SOAP/Perl does not yet support the transport of list
    # values; when it does this should be changed to use the list serialization
    # instead.
    ###########################################################################
    my $return_val  = $body->{'return'};
    my $num_results = $return_val->{'num_results'};
    my @results;
    foreach my $idx (1 .. $num_results)
    {
        #######################################################################
        # Get the contents of this result item.
        #######################################################################
        my $key = "result_$idx";
        my $val = $return_val->{$key};

        #######################################################################
        # Remove any SOAP fields that were used during transport.
        #######################################################################
        if ((ref($val) eq 'HASH') && (exists $val->{'soap_typename'}))
        {
            delete $val->{'soap_typename'};
        }

        #######################################################################
        # Add this item to our return value.
        #######################################################################
        push( @results, $val );
    }

    ###########################################################################
    # All done, return the result set to the caller.
    ###########################################################################
    return @results;
}

1;
__END__;

###############################################################################
# POD Documentation
###############################################################################

=head1 NAME

PPM::SOAPClient - SOAP client for PPM repository

=head1 SYNOPSIS

  use PPM::SOAPClient;
  ...
  my $client = new PPM::SOAPClient;
  my @results = $client->search( 'sarathy' );

=head1 DESCRIPTION

C<PPM::SOAPClient> implements a SOAP client to be used to access a PPM
repository through a SOAP interface.  All of the functionality for making
and parsing the SOAP request is handled internally; simply access the
provided methods and you'll be returned a data structure containing the
actual response.

=head1 METHODS

=over 4

=item new ($server)

Instantiates a new SOAP client, specifying the server that will be used for
all later connections. 'C<$server>' should be provided as the URL to the
SOAP server that we're going to connect to and make queries against. 

Note, that this method accepts both "http://" and "soap://" server URLs
exactly the same way (we treat 'C<soap://>' URLs as standard HTTP URLs). 

=item version ()

Gets the version number of the SOAP server that we're connected to. If
we're unable to contact the server or its offline, this method returns
'C<undef>'. 

=item searchAbstract ($search)

Searches within the 'C<ABSTRACT>' field within all of the packages held in
the repository on the server. The value 'C<$search>' may be a regex that
will be used to match against the abstracts. If no value for 'C<$search>'
is provided, the server treats the search to be for 'C<.*>' (everything). 

=item searchAuthor ($search)

Searches within the 'C<AUTHOR>' field within all of the packages held in
the repository on the server. The value 'C<$search>' may be a regex that
will be used to match against the authors. If no value of 'C<$search>' is
provided, the server treats the search to be for 'C<.*>' (everything). 

=item searchTitle ($search)

Searches within the 'C<title>' field within all of the packages held in the
repository on the server. The value 'C<$search>' may be a regex that will
be used to match against the titles. If no value of 'C<$search>' is
provided, the server treats the search to be for 'C<.*>' (everything). 

=item search ($search)

Searches through all of the fields within all of the packages held in the
repository on the server. The value 'C<$search>' may be a regex that will
be used to match against the field values. If no value of 'C<$search>' is
provided, the server treats the search to be for 'C<.*>' (everything). 

=item packages ()

Generates a list of all of the packages currently available in the
repository. The value returned to the caller is a list containing the names
of all of the packages in the repository. 

=item fetch_ppd ($pkg)

Fetches the PPD associated with a given package. The full contents of the
PPD are returned to the caller in XML format as a scalar value. 

=item fetch_summary ()

Fetches the full summary of all of the packages held in the repository. The
full contents of the summary are returned to the caller in XML format as a
scalar value. 

=item _makeSOAPRequest ($method, $search)

B<INTERNAL METHOD.> Makes the SOAP request to the server, doing the bulk of
the actual work for us. 

=back

=head1 AUTHOR

Graham TerMarsch (gtermars@home.com)

=head1 SEE ALSO

L<PPM::SOAPServer>,
L<SOAP>.

=cut
