use warnings;
use strict;

package TessSystemVars;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(%top $fs_html $fs_cgi $fs_perl $fs_xsl $fs_test $fs_text $fs_tmp $fs_data $url_html $url_cgi $url_css $url_xsl $url_text $url_image $url_tmp $apache_user);

our @EXPORT_OK = qw(uniq intersection tcase lcase beta_to_uni);

our $apache_user = "www-data";

my $fs_base	= '/var/www/tesserae';

our $fs_cgi 	= $fs_base . '/cgi-bin';
our $fs_data	= $fs_base . '/data';
our $fs_html 	= $fs_base . '/html';
our $fs_perl 	= $fs_base . '/perl';
our $fs_test	= $fs_base . '/testing';
our $fs_text	= $fs_base . '/texts';
our $fs_tmp  	= $fs_base . '/tmp';
our $fs_xsl  	= $fs_base . '/xsl';

my $url_base	= 'http://tess.tamias';

our $url_cgi	= $url_base . '/cgi-bin';
our $url_css	= $url_base . '/css';
our $url_html	= $url_base . '/html';
our $url_image	= $url_base . '/images';
our $url_text	= $url_base . '/texts';
our $url_tmp	= $url_base . '/tmp';
our $url_xsl	= $url_base . '/xsl';

our %top;

$top{'la_word'} = [qw{et in non nec est cum ut per si ad quae sed atque iam tibi quod te qui mihi nunc aut haec ille quid me quam sic hic ab tamen at hoc de illa tum tu quoque quo ipse sub ac se erat dum ubi ego a esse ante ne qua nam arma sit inter o ex quem quis neque fuit manus hinc omnia ora mea tua sunt sua saepe cui ipsa modo enim sine sanguine tunc etiam pater erit armis quos simul e omnis inde corpore haud caput pro hunc super semper corpora ore his nobis fata amor nulla ait sibi multa iamque bella manu tam una magis post an habet tantum prima pectora pectore nomen terra pars nos res omnes procul rerum signa cur dies tellus nil membra tela dedit illi dixit contra deus nisi seu licet moenia hanc primum nostra quibus magna ire tempora tempore unde litora tot proelia fortuna quas lumina verba genus ira rebus corpus postquam opus ergo caelo huc ferro omne belli vel inquit heu oculos toto satis venit regna fama terga forte dextra turba cura auras terras undis iter ecce causa puer unda posse magno aequora hac circum artus bene namque vix sacra sidera tandem mare domus medio ignis suo illis deum suis ulla urbem natura facta nocte quia idem deos vos undas nomine amore illum parte alta longa quantum ferre saxa iuppiter huic quaeque sola quondam summa mater talia inque numquam bello terris tecta pariter mox quin nox interea nihil dea ita tenet}];
$top{'la_stem'} = [qw{et qui quis sum in hic edo tu neque non ego ille cos atque cum ut fero do iam si sion video per ad omnis ipse magnus sed ab quo aurum venio dico suus multus tuus possum omne sui meus nunc facio deus aut nus primus suum terra manus arma os huc corpus eo alo vir quam meum superus bellum noster for bellus illic at sic res ex volo tamen sue habeo tantus sua omnes nullus solus teneo unus longus nos de nam illa tum amo medius dum pectus virus armo amor ago pars neo altus sub oro ubius ora pater vis totus parvus ubi unda moveo animus duco tempus solum prima nox nomen peto omnia caelum ferrum ne ante multa ignis is auris labor alius suo fatum qua urbs quisque mitto auro cado caelus voco sino modus natus sto sanguis altum mens inter pono iuppiter vox malus vinco vivo o nequeo dies multo sol medion medium nosco vus domus nascor rex iubeo sequor mater verus fata summus reor sacer telum dexter rapio patrius artus tego alto subeo credo bonus turbo miser solo novus aequor paro malum saepis meo dux pareo hinc verum litus caput talis saevus sero ira saepes lego supo latus aqua cura saepe morus oculus cano equus fugio capio dextera puer armus ferus rego quaero caedo campus mei refero idem modo umbra mors fortis sinum uno locus hostis nihil sive ito verbum tellus gens populus ventus sinis enim vultus summum vulnus lumen quantus viso nitor regnum sine annus}];

$top{'grc_word'} = [qw{d' kai\\ de\\ te me\\n e)n de/ oi( t' w(\\s ga\\r e)pi\\ a)ll' to\\n dh\\ au)ta\\r toi moi min e)pei\\ e)s e)k ge h)= a)/r' e)ni\\ nu=n a)/ra kata\\ ou) w(s tis kai/ per ou)d' o(\\ oi(\\ ou)/ ga/r ken e)p' ei) ti o(/te e)gw\\ ou)de/ g' o( a)lla\\ peri\\ h)\\ ou)k o(/ o(/s e)/peita *)axaiw=n a)ndrw=n a)po\\ e)/nqa ma/la me/ga h)de\\ tw=| r(' me ke e)c au)to\\s th\\n ei)s mh/ a)\\n u(po\\ ei)/ a)mfi\\ meta\\ su\\ m' ou)de\\ se e)/ti to\\ pa/nta me/n tw=n dh/ su\\n mh\\ *dio\\s para\\ ta\\ polla\\ o(\\s w(/s oi(/ k' r(a tou= q' pro\\s ti/ qumw=| o)/fra qumo\\n pa/ntes h( h)d' tou\\s gai=an ti/s *trw/wn prose/fh e)/nq' au)=te dia\\ to/te fi/lon *zeu\\s ma/l' *(/ektwr h)/dh au)tw=| *)aqh/nh *)odusseu/s h(/ qew=n i(/ppous au)= e)/fat' a)/lloi fa/to w)= di=os h(\\ e)/pos au)tou= h)e\\ qumo\\s nh=as mu=qon qeoi\\ a)/ge kat' eu)= au)=tis u(p' a)na\\ me/nos tw\\ s' nh=a a)lla/ toi=si pri\\n th=| proshu/da a)nh\\r o)/fr' au)=t' met' a(/ma i(/na toi\\ bh= au)ti/ka ou)/t' ui(o\\s ou)/te nu/ pou ei)=nai xei=ras o(\\n e)gw\\n sfin o(/t' patro\\s e)pei/ e)moi\\ a)ta\\r pa/ntas te/ e)/rga ai)ei\\ h)=en fresi\\ kako\\n ai)/ ai)=ya to/t' pa/ros e)/gxos soi\\ *trw=es nho\\s e)gw/ a(/m' a)/llos prose/eipe e)/pea xalkw=| ke/ to/de a)p' h)/toi w(=| a)\\y *thle/maxos ui(o\\n *(/hrh e)/peit' a)/stu pot' a)mf' douri\\ par' ptero/enta e)/t' r(a/ path\\r *)apo/llwn ei)pw\\n mh/thr xersi\\n kaka\\ qea\\ toi=sin h)/ qeo\\s a)/llwn e)/ni ta/ a)pameibo/menos *)odusseu\\s pole/moio ke/n e)/faq' law=n e)o/nta polu\\ pa/ntwn to/n i)dw\\n *)axaioi\\ a)/nac w(=s ma/xesqai du/w dw=ma ei)/h}];
$top{'grc_stem'} = [qw{de/ o( kai/ o(/s te su/ ei)mi/ e)gw/ ei)s me/n e)n w(s tis e)pi/ a)/ra a)/n ti/s ga/r a)lla/ ou) au)to/s ou)do/s ou)de/ a)/ron ras nau=s pa=s a)nh/r e)k toi/ dh/ ge ei) kata/ polu/s a)/llos me/gas a)ta/r nu=n e)/rxomai fhmi/ xei/r ui(o/s toi qumo/s e)/xw h)/ ai)/rw min qeo/s e)pei/ u(po/ ei)=mi a)po/ tw=| a)ro/w ippus i(/ppos ris o(/te a)na/ me/ghs o(/ste pe/r ba/llw h)mi/ fi/los a)/ros mh/ e)/nqa e)mo/s para/ i(/sthmi meta/ i(/hmi h)= zeu/s so/s ma/lh ai(re/w ma/la ales a)/gw a)mfi/ peri/ e)/peita h)de/ o(/de ei)=pon ei)=don pro/teros di/dwmi pro/s bai/nw sfei=s e)/pos qea/ phro/s e)/ti e)a/n do/ru e(tai=ros po/lemos au)=te lao/s pou/s fe/rw o)/fra gai=a ma/xomai kako/s pai=s a)ndro/w path/r o)/rnumi ti/qhmi prw=tos dia/ oi)=da o(/sos du/w nao/s di=os su/n o(/stis mu=qos e)/gxos gi/gnomai frh/n ne/w to/te i(kne/omai pei/qw o(/ti teu/xw po/lis a)/nac lei/pw ou)/te pa/thr teu=xos e(/pomai e)qe/lw a(/ma nax ou(=tos e(/kastos pi/ptw kalo/s xa/lkeos xalko/s pote/ a)ei/ me/nos sth=qos au)ti/ka a)/ristos h)=mar e)lau/nw e(o/s olis pri/n oi(=os h)e/ kratero/s h(/rws qe/a e)a/w eron e)/rgon a)llh/lwn ge/rwn e)kei=nos pu=r e)/peimi xe/w eu)= mh/thr me/sos pe/lw potamo/s e)ru/w e)gw/ge a(/ls a)qa/natos ma/xh me/nw kei=mai w)= edium xru/seos pedi/on w)=mos dama/zw au)=qis oi)=os bou=s toi=os no/os feu/gw e)me/w i)/sos a)/pios h)/toi ko/rh summaxe/w pis gunh/ qoo/s o)cu/s kei=nos a)/stu pro/sfhmi o)/ros a)/ge du/o metai/ ti/ktw ristus ou)/tis i(/na e(/ poto/s i(ero/s th=| peda/w w)ku/s lu/w tei=xos xalkou=s kale/w me/las u(pe/r keleu/w h)=dos ei(=s a)/kros pou/ nu/c ou)/ti eu)/xomai ai)=ya ai)/ ale klisi/a eu)ru/s noe/w me/maa di=on o)/llumi qe/w}];

########################################
# subroutines
########################################

sub uniq
{									
	# removes redundant elements

   my @array = @{$_[0]};			# dereference array to be evaluated

   my %hash;							# temporary
   my @uniq;							# create a new array to hold return value

	for (@array)	
	{ 
		$hash{$_} = 1; 
	}
											
   @uniq = sort( keys %hash);   # retrieve keys, sort them

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

	# keep elements whose count is equal to the number of arrays

   @intersect = grep { $count{$_} == 2 } keys %count;

	# sort results

   @intersect = sort @intersect;

   return \@intersect;
}

#
# language-specific lower-case and title-case functions
#

sub lcase
{
	my $lang = shift;

	my @string = @_;

	for (@string)
	{
	
		if ($lang eq 'la')
		{
			tr/A-Z/a-z/;
			tr/jJ/iI/;
		}
	
		if ($lang eq 'grc')
		{
			s/^\*([\(\)\/\\\|\=\+]*)([a-z])/$2$1/;
		}
	}

	return wantarray ? @string : shift @string;
}

sub tcase
{
	my $lang = shift;

	my @string = @_;
	
	for (@string)
	{

		$_ = lcase($lang, $_);

		if ($lang eq 'la')
		{
			s/^([a-z])/uc($1)/e;
		}
	
		if ($lang eq 'grc')
		{
			s/^([a-z])([\(\)\/\\\|\=\+]*)/\*$2$1/;
		}
	}

	return wantarray ? @string : shift @string;
}

sub beta_to_uni
{
	
	my @text = @_;
	
	for (@text)	{
		
		s/(\*)([^a-z ]+)/$2$1/g;
		
		s/\)/\x{0313}/ig;
		s/\(/\x{0314}/ig;
		s/\//\x{0301}/ig;
		s/\=/\x{0342}/ig;
		s/\\/\x{0300}/ig;
		s/\+/\x{0308}/ig;
		s/\|/\x{0345}/ig;
	
		s/\*a/\x{0391}/ig;	s/a/\x{03B1}/ig;  
		s/\*b/\x{0392}/ig;	s/b/\x{03B2}/ig;
		s/\*g/\x{0393}/ig; 	s/g/\x{03B3}/ig;
		s/\*d/\x{0394}/ig; 	s/d/\x{03B4}/ig;
		s/\*e/\x{0395}/ig; 	s/e/\x{03B5}/ig;
		s/\*z/\x{0396}/ig; 	s/z/\x{03B6}/ig;
		s/\*h/\x{0397}/ig; 	s/h/\x{03B7}/ig;
		s/\*q/\x{0398}/ig; 	s/q/\x{03B8}/ig;
		s/\*i/\x{0399}/ig; 	s/i/\x{03B9}/ig;
		s/\*k/\x{039A}/ig; 	s/k/\x{03BA}/ig;
		s/\*l/\x{039B}/ig; 	s/l/\x{03BB}/ig;
		s/\*m/\x{039C}/ig; 	s/m/\x{03BC}/ig;
		s/\*n/\x{039D}/ig; 	s/n/\x{03BD}/ig;
		s/\*c/\x{039E}/ig; 	s/c/\x{03BE}/ig;
		s/\*o/\x{039F}/ig; 	s/o/\x{03BF}/ig;
		s/\*p/\x{03A0}/ig; 	s/p/\x{03C0}/ig;
		s/\*r/\x{03A1}/ig; 	s/r/\x{03C1}/ig;
		s/s\b/\x{03C2}/ig;
		s/\*s/\x{03A3}/ig; 	s/s/\x{03C3}/ig;
		s/\*t/\x{03A4}/ig; 	s/t/\x{03C4}/ig;
		s/\*u/\x{03A5}/ig; 	s/u/\x{03C5}/ig;
		s/\*f/\x{03A6}/ig; 	s/f/\x{03C6}/ig;
		s/\*x/\x{03A7}/ig; 	s/x/\x{03C7}/ig;
		s/\*y/\x{03A8}/ig; 	s/y/\x{03C8}/ig;
		s/\*w/\x{03A9}/ig; 	s/w/\x{03C9}/ig;
	
	}

	return wantarray ? @text : $text[0];
}

1;
