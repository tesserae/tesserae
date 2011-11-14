use warnings;
use strict;

package TessSystemVars;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(%abbr %top $fs_html $fs_cgi $fs_perl $fs_xsl $fs_test $fs_text $fs_tmp $fs_data $url_html $url_cgi $url_css $url_xsl $url_text $url_images $url_tmp);

our @EXPORT_OK = qw(&uniq &intersection);

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
our $url_html	= $url_base;
our $url_images	= $url_base . '/images';
our $url_text	= $url_base . '/texts';
our $url_tmp	= $url_base . '/tmp';
our $url_xsl	= $url_base . '/xsl';


our %abbr = (

		'catullus.carmina'      	=> 'catull. '			,
		'ennius.annales'				=> 'enn. ann. '		,
		'horace.ars_poetica'    	=> 'hor. ars p. '		,
		'horace.carmen_saeculare' 	=> 'hor. carm. saec. '	,
		'horace.epistles'       	=> 'hor. epist. '		,
		'horace.epodes'         	=> 'hor. epod. '		,
		'horace.odes'           	=> 'hor. carm. '		,
		'horace.satires'        	=> 'hor. sat. '		,
		'juvenal'						=> 'juv. '				,
		'lucan.pharsalia'       	=> 'luc. '				,  
		'lucretius.de_rerum_natura'     => 'lucr. '		,    
		'martial.epigrams'			=> 'mart. '				,
		'ovid.amores'           	=> 'ov. am. '			,
		'ovid.ars_amatoria'     	=> 'ov. ars am. '		,
		'ovid.fasti'					=> 'ov. fast. '		,
		'ovid.heroides'         	=> 'ov. her. '			,  
		'ovid.medicamina_faciei_femineae'       
                                	=> 'ov. medic. '		,
		'ovid.metamorphoses'			=> 'ov. met.'			,
		'paul.carmina'					=> 'paul c.'			,
		'propertius.elegies'    	=> 'prop. '				,
		'silius_italicus.punica'	=> 'sil. pun. '		,
		'statius.thebaid'       	=> 'stat. theb. '		,
		'tibullus'              	=> 'tib. '				,
		'vergil.aeneid'         	=> 'verg. aen. '		,
		'vergil.eclogues'       	=> 'verg. ecl. '		,
		'vergil.georgics'       	=> 'verg. g. '			,         
		'valerius_flaccus'      	=> 'valerius flaccus '
);

our %top;

$top{'la_word'} = [qw{et in non nec est cum ut per si ad quae sed atque iam tibi quod te qui mihi nunc aut haec ille quid me quam sic hic ab tamen at hoc de illa tum tu quoque quo ipse sub ac se erat dum ubi ego a esse ante ne qua nam arma sit inter o ex quem quis neque fuit manus hinc omnia ora mea tua sunt sua saepe cui ipsa modo enim sine sanguine tunc etiam pater erit armis quos simul e omnis inde corpore haud caput pro hunc super semper corpora ore his nobis fata amor nulla ait sibi multa iamque bella manu tam una magis post an habet tantum prima pectora pectore nomen terra pars nos res omnes procul rerum signa cur dies tellus nil membra tela dedit illi dixit contra deus nisi seu licet moenia hanc primum nostra quibus magna ire tempora tempore unde litora tot proelia fortuna quas lumina verba genus ira rebus corpus postquam opus ergo caelo huc ferro omne belli vel inquit heu oculos toto satis venit regna fama terga forte dextra turba cura auras terras undis iter ecce causa puer unda posse magno aequora hac circum artus bene namque vix sacra sidera tandem mare domus medio ignis suo illis deum suis ulla urbem natura facta nocte quia idem deos vos undas nomine amore illum parte alta longa quantum ferre saxa iuppiter huic quaeque sola quondam summa mater talia inque numquam bello terris tecta pariter mox quin nox interea nihil dea ita}];
$top{'la_stem'} = [qw{et qui.2 quis.1 quis.2 sum.1 qui.1  in hic tu edo.1 neque non ego ille atque cum ut fero do.1 jam si sion.1 video per ad omnis ipse magnus sed ab quo amo aurum venio suus dico.2 multus tuus possum do.2 omne sui magnus.1 meus nunc facio deus aut nus nequeo primus suum manus.1 terra arma huc corpus eo.1 os.1 alo vir quam meum superus bellum noster for bellus illic at sic res ex tamen habeo tantus sua omnes nullus teneo unus longus solus.1 nos de.2 de.1 nam illa tum dum medius pectus virus volo.1 armo amor ago pars neo.1 altus.1 sub oro ora.1 lux pater vis totus.2 totus.1 parvus ubi unda moveo animus duco tempus solum.1 prima nox nomen peto omnia caelum.2 ferrum ne.1 ante ignis is auris suo alius.2 fatum qua urbs quisque mitto auro cado caelum.1 caelus voco sino modus natus.1 natus sto sanguis multa altum inter mens pono vox malus o dies multo.2 vinco sol multa.1 vivo medion.1 medium malus.1 nosco vus domus nascor rex jubeo sequor mater verus reor sacer summus dexter telum patrius.2 patrius.1 rapio tego alto subeo credo bonus solo.1 miser novus aequor malum malum.2 saepis paro.2 paro.1 dux artus.1 hinc pareo meo verum.2 verum caput saevus talis ira saepes supo litus.3 aqua cura oculus saepe morus.1 equus.1 cano fugio capio capio.1 dextera.1 dextera puer armus ferus rego caedo campus.2 quaero campus.1 mei idem refero lego.2 modo umbra mors fortis uno locus hostis sinum nihil sive verbum ito tellus ventus gens populus.1 populus.2}];

for (@{$top{'la_stem'}})	{ s/\./\#/g }

$top{'grc_word'} = [qw{d' kai\\ de\\ te me\\n e)n de/ oi( t' w(\\s ga\\r e)pi\\ a)ll' to\\n dh\\ au)ta\\r toi moi min e)pei\\ e)s e)k ge h)= a)/r' e)ni\\ nu=n a)/ra kata\\ ou) w(s tis kai/ per ou)d' o(\\ oi(\\ ou)/ ga/r ken e)p' ei) ti o(/te e)gw\\ ou)de/ g' o( a)lla\\ peri\\ h)\\ ou)k o(/ o(/s e)/peita *)axaiw=n a)ndrw=n a)po\\ e)/nqa ma/la me/ga h)de\\ tw=| r(' me ke e)c au)to\\s th\\n ei)s mh/ a)\\n u(po\\ ei)/ a)mfi\\ meta\\ su\\ m' ou)de\\ se e)/ti to\\ pa/nta me/n tw=n dh/ su\\n mh\\ *dio\\s para\\ ta\\ polla\\ o(\\s w(/s oi(/ k' r(a tou= q' pro\\s ti/ qumw=| o)/fra qumo\\n pa/ntes h( h)d' tou\\s gai=an ti/s *trw/wn prose/fh e)/nq' au)=te dia\\ to/te fi/lon *zeu\\s ma/l' *(/ektwr h)/dh au)tw=| *)aqh/nh *)odusseu/s h(/ qew=n i(/ppous au)= e)/fat' a)/lloi fa/to w)= di=os h(\\ e)/pos au)tou= h)e\\ qumo\\s nh=as mu=qon qeoi\\ a)/ge kat' eu)= au)=tis u(p' a)na\\ me/nos tw\\ s' nh=a a)lla/ toi=si pri\\n th=| proshu/da a)nh\\r o)/fr' au)=t' met' a(/ma i(/na toi\\ bh= au)ti/ka ou)/t' ui(o\\s ou)/te nu/ pou ei)=nai xei=ras o(\\n e)gw\\n sfin o(/t' patro\\s e)pei/ e)moi\\ a)ta\\r pa/ntas te/ e)/rga ai)ei\\ h)=en fresi\\ kako\\n ai)/ ai)=ya to/t' pa/ros e)/gxos soi\\ *trw=es nho\\s e)gw/ a(/m' a)/llos prose/eipe e)/pea xalkw=| ke/ to/de a)p' h)/toi w(=| a)\\y *thle/maxos ui(o\\n *(/hrh e)/peit' a)/stu pot' a)mf' douri\\ par' ptero/enta e)/t' r(a/ path\\r *)apo/llwn ei)pw\\n mh/thr xersi\\n kaka\\ qea\\ toi=sin h)/ qeo\\s a)/llwn e)/ni ta/ a)pameibo/menos *)odusseu\\s pole/moio ke/n e)/faq' law=n e)o/nta polu\\ pa/ntwn to/n i)dw\\n *)axaioi\\ a)/nac w(=s ma/xesqai du/w dw=ma ei)/h}];
$top{'grc_stem'} = [qw{de/ o( kai/ o(/s te su/ ei)mi/ e)gw/ ei)s e)n tis w(s me/n a)/ra ti/s e)pi/ a)/n1 ga/r a)lla/ ou) au)to/s ou)do/s1 ou)do/s2 a)/ron ou)de/ pa=s nau=s a)nh/r dh/ ge e)/rxomai e)k toi/ toi a)ta/r a)/llos kata/ polu/s ei)  fhmi/ nu=n e)pei/ me/gas qeo/s qumo/s e)/xw h)/1 *zeu/s min ai)/rw h)mi/ xei/r *)axaio/s fi/los ei)=mi *)odusseu/s e)mo/s ui(o/s h)= a)ro/w a)/ros so/s *trw/s tw=| a)na/ e)/nqa o(/te o(/ste o(/de pe/r mh/ ei)=pon u(po/ h)de/ a)po/ a)/gw ma/lh ma/la para/ e)/peita ba/llw di/dwmi pro/s h)/2 ei)=don meta/ i(/sthmi e)/pos i(/hmi e(tai=ros peri/ i(/ppos bai/nw ai(re/w kako/s a)mfi/ *(/ektwr e(/ktwr pro/teros qea/ fe/rw ti/qhmi di=os phro/s e)/ti o)/fra sfei=s oi)=da e)a/n gai=a path/r au)=te *)axilleu/s i(kne/omai a)xaia/ *)axai/a a)/n2 a)ndro/w frh/n ou(=tos mu=qos pai=s gi/gnomai to/te *)aqh/nh o(/sos pa/thr ou)/te pou/s kalo/s me/garon prw=tos ne/w3 lao/s e)qe/lw du/w2 nao/s do/ru su/n e)gw/ge o(/stis o)/rnumi dw=ma gunh/ po/lemos o(/ti2 dia/ w)= teu/xw a(/ma e)kei=nos e(/kastos po/lis pei/qw a)ei/ pote/ e)/rgon e(/pomai a)/nac ma/xomai au)ti/ka e)a/w lei/pw h)=mar *)aqh=nai thle/maxos *thle/maxos oi(=os mh/thr e)/gxos xe/w ce/nos2 *)/arhs qe/a kei=nos a)/ristos ce/nos1 a)/ge eu)= pro/sfhmi h)e/1 e)lau/nw mnhsth/r Athenian pri/n kei=mai ge/rwn xalko/s a)qa/natos *)argei=os h(/lios xa/lkeos bou=s i(/na pi/ptw me/nw o(/ti1 prosei=pon h)=dos ne/w2 me/nos *)atrei/dhs e)me/w sth=qos teu=xos a)/nqrwpos oi)=os pou/ *ai)/as h)/dh a)llh/lwn e(o/s patri/s ou)/tis keleu/w me/las a)goreu/w a)kou/w ko/rh no/os au)=2 e)/peimi2 a)mei/bw au)=1 pu=r a(/ls *mene/laos qoo/s do/mos fai/nw xru/seos poto/s po/ntos ai)=ya ou)/ti e)ru/w metai/ h(/rws au)tou= toi=os *)agame/mnwn h)e/lios o)/llumi pe/lw fwne/w a)nta/w nu/c prosauda/w feu/gw}];

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
