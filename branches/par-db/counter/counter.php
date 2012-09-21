<?php
$filename= "counter/counter.txt" ;
$fd = fopen ($filename , "r") or die ("Can't open $filename to read") ;
$fstring = fread ($fd , filesize ($filename)) ;
echo "<br><right><b>Visits to date: $fstring</b></right>" ;
fclose($fd) ;

$fd = fopen ($filename , "w") or die ("Can't open $filename to write") ;
$fcounted = $fstring + 1 ;
$fout= fwrite ($fd , $fcounted ) ;
fclose($fd) ;

?>
</html>
