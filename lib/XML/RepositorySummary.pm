#
# XML::PPMConfig
#
# Definition of the PPMConfig file format; configuration options for the Perl
# Package Manager.
#
###############################################################################

$XML::RepositorySummary::revision = '$Id: RepositorySummary.pm,v 1.1.1.1 2000/01/26 17:39:19 graham Exp $';
$XML::RepositorySummary::VERSION  = '0.01';

###############################################################################
# Import everything from XML::PPD into our own namespace.
###############################################################################
package XML::RepositorySummary;
use XML::PPD ':elements';

###############################################################################
# RepositorySummary Element: Characters
###############################################################################
package XML::RepositorySummary::Characters;
@ISA = qw( XML::Element );

###############################################################################
# RepositorySummary Element: REPOSITORYSUMMARY
###############################################################################
package XML::RepositorySummary::REPOSITORYSUMMARY;
@ISA = qw( XML::ValidatingElement );
@okids  = qw( SOFTPKG );

__END__
