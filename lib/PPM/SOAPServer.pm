package PPM::SOAPServer;

###############################################################################
# Required inclusions.
###############################################################################
use strict;                         # Activate compile-time syntax checking
use XML::Parser;                    # Needed for parsing XML documents
use XML::RepositorySummary;         # Needed for XML structure of repository

###############################################################################
# Get our version number out of the CVS revision number.
###############################################################################
use vars qw( $VERSION );
$VERSION = do { my @r = q$Revision: 1.1 $ =~ /\d+/g; sprintf '%d.'.'%02d'x$#r, @r };

###############################################################################
# Package-wide variables.
###############################################################################
    ###########################################################################
    # Specify the location of the XML file containing the listing of all of the
    # packages in the repository.
    ###########################################################################
#my $REPOSITORY_DATA = './package.lst';
my $REPOSITORY_DATA = 'r:/Inetpub/wwwroot/www.ActiveState.com/PPMPackages/5.6/package.lst';
    ###########################################################################
    # Pre-loaded copy of the repository information.
    ###########################################################################
my $REPOSITORY_INFO = undef;

###############################################################################
# Subroutine:   new ()
###############################################################################
# Instantiates a new PPM::SOAPServer object, returning a reference to the newly
# created object to the caller.  During instantiation, we also read in a full
# copy of the information held within the repository so that we can run queries
# against it later.
###############################################################################
sub new ()
{
    my $class = shift;
    my $self  = {};
    bless $self, $class;

    ###########################################################################
    # Load up the information about the contents of the repository.
    ###########################################################################
    _loadRepository();

    ###########################################################################
    # All done, return a reference to the newly create object to the caller.
    ###########################################################################
    return $self;
}

###############################################################################
# Subroutine:   handle_request ($hdrs, $body, $envelope)
# Parameters:   $hdrs       - Listref of provided headers
#               $body       - Hashref of body of response to send
#               $envelope   - Reference to envelope maker to use to package up
#                             the SOAP response
###############################################################################
# Handles the complete request provided through the SOAP interface.  This
# method determines which method is to be invoked and calls off to that method
# to generate the response which is to be returned to the caller.  Once the
# response has been generated, we stuff this back into the envelope so that it
# can be returned via the SOAP server.
###############################################################################
sub handle_request ($$$)
{
    my ($self, $hdrs, $body, $envelope) = @_;

    ###########################################################################
    # Figure out which method to invoke, and whether or not we can actually
    # invoke that type of method on ourselves.  If we can't invoke the
    # requested method, throw an error back.
    ###########################################################################
    my $fcn_name = $body->{'soap_typename'};
    my $function = $self->can( $fcn_name );

    if (!defined $function)
    {
        die "Method '$fcn_name' is not defined for this class.\n";
    }

    ###########################################################################
    # We now know that we actually can invoke the requested method on
    # ourselves.  Call off to the method to get a hashref containing the return
    # value, stick that into the body, and then send a response back to the
    # client.
    ###########################################################################
    my $return;
    $return = $self->$function( $body );
    $body->{'return'} = $return;
    $envelope->set_body( undef, $fcn_name, 0, $body );
}

###############################################################################
# Subroutine:   version ()
###############################################################################
# Returns to the caller the version number of the SOAP server that is running.
###############################################################################
sub version ()
{
    my ($self) = @_;
    return { 'num_results' => 1, 'result_1' => $VERSION };
}

###############################################################################
# Subroutine:   searchAbstract ($params)
# Parameters:   $params     - Hashref of parameters to search with
# Returns:      $results    - Hashref of results
###############################################################################
# Searches against the 'ABSTRACT' field within the packages held in the
# repository.  Within the given parameters, a key of "search" should be
# provided containing the term to search for (which can be a regex).  If no
# "search" key is provided, a complete list of all of the packages are returned
# to the caller.
#
# The return value provided from this method will be a reference to a hash
# containing the result set.  A key named "num_results" will be provided,
# stating the number of results to be found in the result set.  Each item in
# the result set will be named "result_???" where '???' is the number of that
# item in the result set.  For example, a search returning two results would
# return a reference to a hash with keys of 'num_results', 'result_1', and
# 'result_2'.
###############################################################################
sub searchAbstract
{
    my ($self, $params) = @_;
    my $field  = 'ABSTRACT';
    my $search = $params->{'search'};
    return $self->_search( $field, $search );
}

###############################################################################
# Subroutine:   searchAuthor ($params)
# Parameters:   $params     - Hashref of parameters to search with
# Returns:      $results    - Hashref of results
###############################################################################
# Searches against the 'AUTHOR' field within the packages held in the
# repository.  Within the given parameters, a key of "search" should be
# provided containing the term to search for (which can be a regex).  If no
# "search" key is provided, a complete list of all of the packages are returned
# to the caller.
#
# The return value provided from this method will be a reference to a hash
# containing the result set.  A key named "num_results" will be provided,
# stating the number of results to be found in the result set.  Each item in
# the result set will be named "result_???" where '???' is the number of that
# item in the result set.  For example, a search returning two results would
# returns a reference to a hash with keys of 'num_results', 'result_1', and
# 'result_2'.
###############################################################################
sub searchAuthor
{
    my ($self, $params) = @_;
    my $field  = 'AUTHOR';
    my $search = $params->{'search'};
    return $self->_search( $field, $search );
}

###############################################################################
# Subroutine:   searchTitle ($params)
# Parameters:   $params     - Hashref of parameters to search with
# Returns:      $results    - Hashref of results
###############################################################################
# Searches against the 'TITLE' field within the packages held in the
# repository.  Within the given parameters, a key of "search" should be
# provided containing the term to search for (which can be a regex).  If no
# "search" key is provided, a complete list of all of the packages are returned
# to the caller.
#
# The return value provided from this method will be a reference to a hash
# containing the result set.  A key named "num_results" will be provided,
# stating the number of results to be found in the result set.  Each item in
# the result set will be named "result_???" where '???' is the number of that
# item in the result set.  For example, a search returning two results would
# returns a reference to a hash with keys of 'num_results', 'result_1', and
# 'result_2'.
###############################################################################
sub searchTitle
{
    my ($self, $params) = @_;
    my $field  = 'TITLE';
    my $search = $params->{'search'};
    return $self->_search( $field, $search );
}

###############################################################################
# Subroutine:   search ($params)
# Parameters:   $params     - Hashref of parameters to search with
# Returns:      $results    - Hashref of results
###############################################################################
# Searches against _all_ of the fields within the packages held in the
# repository.  Within the given parameters, a key of "search" should be
# provided containing the term to search for (which can be a regex).  If no
# "search" key is provided, a complete list of all of the packages are returned
# to the caller.
#
# The return value provided from this method will be a reference to a hash
# containing the result set.  A key named "num_results" will be provided,
# stating the number of results to be found in the result set.  Each item in
# the result set will be named "result_???" where '???' is the number of that
# item in the result set.  For example, a search returning two results would
# returns a reference to a hash with keys of 'num_results', 'result_1', and
# 'result_2'.
###############################################################################
sub search
{
    my ($self, $params) = @_;
    my $search = $params->{'search'};
    return $self->_search( undef, $search );
}

###############################################################################
# Subroutine:   packages ()
###############################################################################
# Generates a list of all of the packages currently available in the
# repository.
#
# The return value provided from this method will be a reference to a hash
# containing the result set.  A key named "num_results" will be provided,
# stating the number of results to be found in the result set.  Each item in
# the result set will be named "result_???" where '???' is the number of that
# item in the result set.  For example, a repository with two packages in it
# would return a reference to a hash with keys of 'num_results', 'result_1',
# and 'result_2'.
###############################################################################
sub packages ()
{
    my ($self) = @_;
    my $results;
    my $counter = 0;
    my $root = $REPOSITORY_INFO;

    ###########################################################################
    # Iterate through all of the packages within the repository, adding all of
    # the names of the packages to our result set.
    ###########################################################################
    foreach my $pkg (@{$root->{'Kids'}})
    {
        if (exists $pkg->{'NAME'})
        {
            $counter ++;
            my $key = 'result_' . $counter;
            $results->{$key}{'NAME'} = $pkg->{'NAME'};
        }
    }

    ###########################################################################
    # All done, add in the total number of items in the result set and return
    # it to the caller.
    ###########################################################################
    $results->{'num_results'} = $counter;
    return $results;
}

###############################################################################
# Subroutine:   fetch_ppd ($params)
###############################################################################
# Fetches the PPD from our package list for a specific package.  The parameters
# provided should include a key named 'package', which is the name of the
# package for which we wish to fetch the PPD for.  This method returns to the
# caller a hash reference containing the matching results.  A key named
# "num_results" will be present stating the number of matching results (either
# 0 or 1).  If a PPD has been found for the requested package, a key of
# "result_1" will also be present, whose value will be the full contents of the
# PPD file (in XML format) as a scalar value.
###############################################################################
sub fetch_ppd ($)
{
    my ($self, $params) = @_;
    my $package = $params->{'package'};

    ###########################################################################
    # Iterate through the package list to find the one we're looking for.
    ###########################################################################
    my $root = $REPOSITORY_INFO;
    foreach my $pkg (@{$root->{'Kids'}})
    {
        if (exists $pkg->{'NAME'})
        {
            if ($pkg->{'NAME'} =~ /^$package$/i)
            {
                my $ppd = $self->_xml_escape( $pkg->as_text() );
                return { 'num_results' => 1,
                         'result_1'    => $ppd };
            }
        }
    }

    ###########################################################################
    # Didn't find the PPD that we were looking for, return an empty result set.
    ###########################################################################
    return { 'num_results' => 0 };
}

###############################################################################
# Subroutine:   fetch_summary ()
###############################################################################
# Fetches a summary of the entire contents of the repository.  This method
# returns to the caller a reference to a hash containing the following keys:
# 'num_results', 'result_1'.  The value of the 'result_1' key is the full
# contents of the repository summary file (in XML format) as a scalar value.
###############################################################################
sub fetch_summary ()
{
    my ($self) = @_;
    my $root = $REPOSITORY_INFO;
    my $content = $self->_xml_escape( $root->as_text() );
    return { 'num_results' => 1, 'result_1' => $content };
}

###############################################################################
# Subroutine:   _xml_escape ($val)
# Parameters:   $val        - Value to escape
# Returns:      $escaped    - Escaped version of '$val'
###############################################################################
# INTERNAL METHOD.  Cheap little function to escape out most of the things in
# the value we're passing back so that its at least "clean".  This should
# really be using some sort of XML::Entities module to do the conversion,
# though; I've just hacked this together because these are the things that I
# encountered.
###############################################################################
sub _xml_escape ($)
{
    my ($self, $val) = @_;
    $val =~ s/&/&amp;/go;
    $val =~ s/</&lt;/go;
    $val =~ s/>/&gt;/go;
    return $val;
}

###############################################################################
# Subroutine:   _search ($field, $search)
# Parameters:   $field      - Field within package description to search
#               $search     - Term to search for
# Returns:      $results    - Hashref of results
###############################################################################
# INTERNAL METHOD.  Does a general search against the fields present for a
# package within the repository, searching for a specific term (which could be
# a regex).  If no '$field' value is provided, this method searches through
# _all_ of the fields present for a given package.  If no '$search' value is
# provided, '.*' is deemed to be the matching regex (everything).
#
# The return value provided from this method will be a reference to a hash
# containing the result set.  A key named "num_results" will be provided,
# stating the number of results to be found in the result set.  Each item in
# the result set will be named "result_???" where '???' is the number of that
# item in the result set.  For example, a search returning two results would
# returns a reference to a hash with keys of 'num_results', 'result_1', and
# 'result_2'.
###############################################################################
sub _search ($$)
{
    my ($self, $field, $search) = @_;
    my $results;
    my $counter = 0;

    ###########################################################################
    # If we weren't given field/search values, use defaults instead.
    ###########################################################################
    $field  = '.*' if ((!defined $field)  || ($field eq ''));
    $search = '.*' if ((!defined $search) || ($search eq ''));

    ###########################################################################
    # Get a handle to the root of the repositories XML information so that we
    # can search against it.
    ###########################################################################
    my $root = $REPOSITORY_INFO;

# UNFINISHED -> Should facilitate "what if no packages in the repository?"

    ###########################################################################
    # Iterate through all of the packages within the repository...
    ###########################################################################
   PKG:
    foreach my $pkg (@{$root->{'Kids'}})
    {
       PKGFIELD:
        foreach my $pkgfield (@{$pkg->{'Kids'}})
        {
            ###################################################################
            # Skip this field if its not the field type we're searching.
            ###################################################################
            my $type = ref($pkgfield);
            $type =~ s/.*:://go;
            next PKGFIELD if ($type eq 'Characters');
            next PKGFIELD if ($type !~ /$field/i);
# UNFINISHED -> Doing a 'content()' on 'IMPLEMENTATION' elements blows up.
#               Cause of problem should be identified and fixed prior to final
#               release.
next PKGFIELD if ($type eq 'IMPLEMENTATION');

            ###################################################################
            # Skip this field if the content doesn't match the search term.
            ###################################################################
            my $val = $pkgfield->content();
            next PKGFIELD if ($val !~ /$search/);

            ###################################################################
            # Add this package to the result set and go onto the next package.
            ###################################################################
            $counter ++;
            $results->{ "result_$counter" } = $self->_pkginfo( $pkg );
            next PKG;
        }
    }

    ###########################################################################
    # Add in the total number of results into the information we're returning,
    # and return the info to the caller.
    ###########################################################################
    $results->{ 'num_results' } = $counter;
    return $results;
}

###############################################################################
# Subroutine:   _pkginfo ($package)
# Parameters:   $package        - Hashref of XML package information
# Returns:      $pkginfo        - Hashref of pertinent package info
###############################################################################
# INTERNAL METHOD.  Takes the XML object representation of a package and turns
# it into a single hash reference containing only select portions of the
# package information.  This hash reference is then returned to the caller.
###############################################################################
sub _pkginfo ($)
{
    my ($self, $package) = @_;
    my $pkginfo;

    ###########################################################################
    # Add in the name and version number of the package.
    ###########################################################################
    $pkginfo->{'NAME'}    = $package->{'NAME'};
    $pkginfo->{'VERSION'} = $package->{'VERSION'};

    ###########################################################################
    # Iterate through the various fields in the package, adding their
    # information into the package info we're going to return.
    ###########################################################################
    foreach my $field (@{$package->{'Kids'}})
    {
        my $type = ref($field);
        $type =~ s/.*:://go;

        $pkginfo->{'TITLE'}    = $field->content() if ($type eq 'TITLE');
        $pkginfo->{'ABSTRACT'} = $field->content() if ($type eq 'ABSTRACT');
        $pkginfo->{'AUTHOR'}   = $field->content() if ($type eq 'AUTHOR');
    }

    ###########################################################################
    # All done, return the hashref to the caller.
    ###########################################################################
    return $pkginfo;
}

###############################################################################
# Subroutine:   _loadRepository ()
###############################################################################
# INTERNAL METHOD.  Loads up information about the contents of the repository,
# stuffing them into the global namespace.  If the repository has already been
# loaded, this method simply returns without doing anything.  NOTE, that this
# method is _NOT_ an instance method; it's a package method.
###############################################################################
sub _loadRepository ()
{
    ###########################################################################
    # If the repository has already been loaded, don't bother to do anything.
    ###########################################################################
    return if (defined $REPOSITORY_INFO);

    ###########################################################################
    # Create a new XML parser to read in the repository summary
    ###########################################################################
    my $parser = new XML::Parser( 'Style' => 'Objects',
                                  'Pkg'   => 'XML::RepositorySummary' );

    ###########################################################################
    # Read in the entire repository.
    ###########################################################################
    my $rc   = $parser->parsefile( $REPOSITORY_DATA );
    $REPOSITORY_INFO = $rc->[0];
}

1;
__END__;

###############################################################################
# POD Documentation
###############################################################################

=head1 NAME

PPM::SOAPServer - SOAP server for PPM repository

=head1 SYNOPSIS

  use SOAP::Transport::HTTP::CGI;
  my $safe_classes = {
    'PPM::SOAPServer' => undef,
    };
  SOAP::Transport::HTTP::CGI->handler( $safe_classes );

=head1 DESCRIPTION

C<PPM::SOAPServer> is a module that provides an implementation of a SOAP
server to hold the PPM repository.  Note that it is not required that you
actually instantiate a copy of the server object yourself; the SOAP modules
will take care of this for you when they instantiate the SOAP server.  All of
the 'search*' methods that are provided by this module are made available
through the SOAP interface and can be accessed through a SOAP client.

=head1 METHODS

=over 4

=item new ()

Instantiates a new PPM::SOAPServer object, returning a reference to the
newly created object to the caller. During instantiation, we also read in a
full copy of the information held within the repository so that we can run
queries against it later. 

=item handle_request ($hdrs, $body, $envelope)

Handles the complete request provided through the SOAP interface. This
method determines which method is to be invoked and calls off to that
method to generate the response which is to be returned to the caller. Once
the response has been generated, we stuff this back into the envelope so
that it can be returned via the SOAP server. 

=item version ()

Returns to the caller the version number of the SOAP server that is
running. 

=item searchAbstract ($params)

Searches against the 'C<ABSTRACT>' field within the packages held in the
repository. Within the given parameters, a key of "search" should be
provided containing the term to search for (which can be a regex). If no
"search" key is provided, a complete list of all of the packages are
returned to the caller. 

The return value provided from this method will be a reference to a hash
containing the result set. A key named "num_results" will be provided,
stating the number of results to be found in the result set. Each item in
the result set will be named "result_???" where 'C<???>' is the number of
that item in the result set. For example, a search returning two results
would return a reference to a hash with keys of 'C<num_results>',
'C<result_1>', and 'C<result_2>'. 

=item searchAuthor ($params)

Searches against the 'C<AUTHOR>' field within the packages held in the
repository. Within the given parameters, a key of "search" should be
provided containing the term to search for (which can be a regex). If no
"search" key is provided, a complete list of all of the packages are
returned to the caller. 

The return value provided from this method will be a reference to a hash
containing the result set. A key named "num_results" will be provided,
stating the number of results to be found in the result set. Each item in
the result set will be named "result_???" where 'C<???>' is the number of
that item in the result set. For example, a search returning two results
would returns a reference to a hash with keys of 'C<num_results>',
'C<result_1>', and 'C<result_2>'. 

=item searchTitle ($params)

Searches against the 'C<TITLE>' field within the packages held in the
repository. Within the given parameters, a key of "search" should be
provided containing the term to search for (which can be a regex). If no
"search" key is provided, a complete list of all of the packages are
returned to the caller. 

The return value provided from this method will be a reference to a hash
containing the result set. A key named "num_results" will be provided,
stating the number of results to be found in the result set. Each item in
the result set will be named "result_???" where 'C<???>' is the number of
that item in the result set. For example, a search returning two results
would returns a reference to a hash with keys of 'C<num_results>',
'C<result_1>', and 'C<result_2>'. 

=item search ($params)

Searches against _all_ of the fields within the packages held in the
repository. Within the given parameters, a key of "search" should be
provided containing the term to search for (which can be a regex). If no
"search" key is provided, a complete list of all of the packages are
returned to the caller. 

The return value provided from this method will be a reference to a hash
containing the result set. A key named "num_results" will be provided,
stating the number of results to be found in the result set. Each item in
the result set will be named "result_???" where 'C<???>' is the number of
that item in the result set. For example, a search returning two results
would returns a reference to a hash with keys of 'C<num_results>',
'C<result_1>', and 'C<result_2>'. 

=item packages ()

Generates a list of all of the packages currently available in the
repository. 

The return value provided from this method will be a reference to a hash
containing the result set. A key named "num_results" will be provided,
stating the number of results to be found in the result set. Each item in
the result set will be named "result_???" where 'C<???>' is the number of
that item in the result set. For example, a repository with two packages in
it would return a reference to a hash with keys of 'C<num_results>',
'C<result_1>', and 'C<result_2>'. 

=item fetch_ppd ($params)

Fetches the PPD from our package list for a specific package. The
parameters provided should include a key named 'C<package>', which is the
name of the package for which we wish to fetch the PPD for. This method
returns to the caller a hash reference containing the matching results. A
key named "num_results" will be present stating the number of matching
results (either 0 or 1). If a PPD has been found for the requested package,
a key of "result_1" will also be present, whose value will be the full
contents of the PPD file (in XML format) as a scalar value. 

=item fetch_summary ()

Fetches a summary of the entire contents of the repository. This method
returns to the caller a reference to a hash containing the following keys:
'C<num_results>', 'C<result_1>'. The value of the 'C<result_1>' key is the
full contents of the repository summary file (in XML format) as a scalar
value. 

=item _xml_escape ($val)

B<INTERNAL METHOD.> Cheap little function to escape out most of the things
in the value we're passing back so that its at least "clean". This should
really be using some sort of XML::Entities module to do the conversion,
though; I've just hacked this together because these are the things that I
encountered. 

=item _search ($field, $search)

B<INTERNAL METHOD.> Does a general search against the fields present for a
package within the repository, searching for a specific term (which could
be a regex). If no 'C<$field>' value is provided, this method searches
through _all_ of the fields present for a given package. If no 'C<$search>'
value is provided, 'C<.*>' is deemed to be the matching regex (everything). 

The return value provided from this method will be a reference to a hash
containing the result set. A key named "num_results" will be provided,
stating the number of results to be found in the result set. Each item in
the result set will be named "result_???" where 'C<???>' is the number of
that item in the result set. For example, a search returning two results
would returns a reference to a hash with keys of 'C<num_results>',
'C<result_1>', and 'C<result_2>'. 

=item _pkginfo ($package)

B<INTERNAL METHOD.> Takes the XML object representation of a package and
turns it into a single hash reference containing only select portions of
the package information. This hash reference is then returned to the
caller. 

=item _loadRepository ()

B<INTERNAL METHOD.> Loads up information about the contents of the
repository, stuffing them into the global namespace. If the repository has
already been loaded, this method simply returns without doing anything.
NOTE, that this method is _NOT_ an instance method; it's a package method. 

=back

=head1 AUTHOR

Graham TerMarsch (gtermars@home.com)

=head1 SEE ALSO

L<PPM::SOAPClient>,
L<SOAP>.

=cut
