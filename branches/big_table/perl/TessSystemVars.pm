use warnings;
use strict;

package TessSystemVars;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(%abbr $fs_html $fs_cgi $fs_perl $fs_xsl $fs_text $fs_tmp $fs_data $url_html $url_cgi $url_css $url_xsl $url_text $url_images $url_tmp &uniq &intersection);

my $fs_base	= '/Users/chris/Desktop/tesserae';

our $fs_cgi 	= $fs_base . '/cgi-bin';
our $fs_data	= $fs_base . '/data';
our $fs_html 	= $fs_base . '/html';
our $fs_perl 	= $fs_base . '/perl';
our $fs_text	= $fs_base . '/texts';
our $fs_tmp  	= $fs_base . '/tmp';
our $fs_xsl  	= $fs_base . '/xsl';

my $url_base	= 'http://tesserae.caset.buffalo.edu';

our $url_cgi	= $url_base . '/cgi-bin';
our $url_css	= $url_base . '/css';
our $url_html	= $url_base;
our $url_images	= $url_base . '/images';
our $url_text	= $url_base . '/texts';
our $url_tmp	= $url_base . '/tmp';
our $url_xsl	= $url_base . '/xsl';


our %abbr = (

	'catullus.carmina'      	=> 'catull. '		,
	'ennius.annales'		=> 'enn. ann. '		,
	'horace.ars_poetica'    	=> 'hor. ars p. '	,
        'horace.carmen_saeculare' 	=> 'hor. carm. saec. '	,
        'horace.epistles'       	=> 'hor. epist. '	,
        'horace.epodes'         	=> 'hor. epod. '	,
        'horace.odes'           	=> 'hor. carm. '	,
        'horace.satires'        	=> 'hor. sat. '		,
        'juvenal'			=> 'juv. '		,
        'lucan.pharsalia'       	=> 'luc. '		,  
        'lucan.bc.1'       	=> 'luc. '		,  
        'lucretius.de_rerum_natura'     => 'lucr. '		,    
	'martial.epigrams'		=> 'mart. '		,
        'ovid.amores'           	=> 'ov. am. '		,
        'ovid.ars_amatoria'     	=> 'ov. ars am. '	,
	'ovid.fasti'			=> 'ov. fast. '		,
        'ovid.heroides'         	=> 'ov. her. '		,  
        'ovid.medicamina_faciei_femineae'       
                                	=> 'ov. medic. '	,
	'ovid.metamorphoses'		=> 'ov. met.'		,
	'paul.carmina'			=> 'paul c.'		,
	'propertius.elegies'    	=> 'prop. '		,
        'silius_italicus.punica'	=> 'sil. pun. '		,
        'statius.thebaid'       	=> 'stat. theb. '	,
        'tibullus'              	=> 'tib. '		,
        'vergil.aeneid'         	=> 'verg. aen. '	,
        'vergil.eclogues'       	=> 'verg. ecl. '	,
        'vergil.georgics'       	=> 'verg. g. '		,          
        'valerius_flaccus'      	=> 'valerius flaccus '
);

our %top;

$top{'10words'} = q/et in non nec est cum si ut sed per ad tibi quae iam quod/;
$top{'20words'} = q/et in non nec est cum si ut sed per ad tibi quae iam quod atque te mihi qui nunc aut haec quid me ille quam sic hic hoc tamen tu at ab de illa ipse esse tum quoque quo erat dum se sub ac a ego ubi ne sit ante qua nam arma o inter quem quis ex tua fuit sunt neque saepe manus mea hinc ora omnia sua modo cui/;
$top{'30words'} = q/et in non nec est cum si ut sed per ad tibi quae iam quod atque te mihi qui nunc aut haec quid me ille quam sic hic hoc tamen tu at ab de illa ipse esse tum quoque quo erat dum se sub ac a ego ubi ne sit ante qua nam arma o inter quem quis ex tua fuit sunt neque saepe manus mea hinc ora omnia sua modo cui ipsa erit enim sine tunc sanguine etiam quos omnis pater uel tam nobis inde armis pro ore simul semper nulla hunc caput e corpore haud sibi habet fata corpora super manu an his ait una magis multa amor post prima tantum licet bella nomen iamque nil res nos omnes uenit cur pectore pectora terra dedit uix pars dies uerba nisi rerum procul nostra signa tellus hanc dixit illi tela membra seu uos contra magna deus primum ergo ire quibus tempora opus tot moenia unde quas tempore fortuna proelia uis puer satis turba litora toto genus lumina ferro uirum caelo ira postquam nihil corpus rebus bene fama belli inquit ecce hac omne huc heu forte suo cura oculos causa posse quamuis dextra domus regna terga auras undis unda iter terras magno sidera aequora artus nocte circum medio tandem sacra noua quantum namque idem urbem suis longa facta illis es deos ferre mare sola deum numquam nomine parte ulla undas ignis natura siue quia iuppiter alta quondam saxa uoce uiri quaeque iouis tota talia uidit summa pariter carmina illum amore mater huic/;
$top{'10stems'} = q/et qu in non es nec ill si me cum/;
$top{'20stems'} = q/et qu in non es nec ill si me cum tu ut de sed su pe iam ad tib te omn ips quod atque au mih quid nunc man haec or magn uir prim se sol arm nostr terr/;
$top{'30stems'} = q/et qu in non es nec ill si me cum tu ut de sed su pe iam ad tib te omn ips quod atque au mih quid nunc man haec or magn uir prim se sol arm nostr terr sic hic hoc bell tamen anim und ab mult cu tant at null un dum aur long ess nam di era corpor tum tot quoque ne sub ac ir alt eg a ub mor ferr ant fat urb mod sin pector ign fer medi cael inte uis o uel dom ex art uer nat op ali tempor loc pr saep mal neque par fui/;

our %new_stoplist = (	'word'	=> [qw/et in non est nec cum per ad ut si quae atque iam tibi mihi sed te quod qui aut nunc me haec ab tamen ille quam de quoque quid sub sic hic se erat Et illa ac hoc ubi ego ipse quo tu esse a Nec tum ante/],
						'stem'  => [qw/et qui2 quis1 quis2 qui1 sum1 in hic tu edo1 neque non ego ille atque cum ut fero do1 jam si per sion1 video ad omnis ipse sed ab quo amo magnus aurum suus dico2 multus venio tuus do2 possum omne sui meus nunc facio deus aut magnus1 nus/]);
for (@{$new_stoplist{'stem'}}) { s/(\d)/\#$1/ }

########################################
# subroutines
########################################

sub uniq
{									
	# removes redundant elements

   my @array = @{$_[0]};			# dereference array to be evaluated

#	print STDERR "uniq: \$#array=$#array\n";

   my %hash;							# temporary
   my @uniq;							# create a new array to hold return value

	for (@array)	
	{ 
		$hash{$_} = 1; 
#		print STDERR "\tuniq: \$hash{$_}=$hash{$_}\n"; 
	}
											
#	print STDERR "uniq: keys(\%hash)=" . join(",", keys %hash). "\n";

   @uniq = sort( keys %hash);   # retrieve keys, sort them

#	print STDERR "uniq: \$#uniq=$#uniq\n";

   return \@uniq;
}


sub intersection 
{              

	# arguments are any number of arrays,
	# returns elements common to all as 
	# a reference to a new array

   my %count;			# temporary, local
   my @intersect;		# create the new array

   for my $array (@_) {         # for each array

      for (@$array) {           # for each of its elements (assume no dups)
         $count{$_}++;          # add one to count
      }
   }

   @intersect = grep { $count{$_} == 2 } keys %count;  
				# keep elements whose count is equal to the number of arrays

   @intersect = sort @intersect;        # sort results

   return \@intersect;
}
1;
