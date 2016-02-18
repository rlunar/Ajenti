<?php
/*
###############################################################################
# Copyright 2006-2016, Way to the Web Limited
# URL: http://www.configserver.com
# Email: sales@waytotheweb.com
###############################################################################
*/

//Store required Environment Variables
putenv("QUERY_STRING=".$_SERVER['QUERY_STRING']);
putenv("REMOTE_ADDR=".$_SERVER['REMOTE_ADDR']);
putenv("POST=".file_get_contents('php://input'));

//Run the csf UI
system("perl /etc/csf/cwp/cwp_csf.cgi");

?>
