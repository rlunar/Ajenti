/*
	* Copyright 2006-2016, Way to the Web Limited
	* URL: http://www.configserver.com
	* Email: sales@waytotheweb.com
*/
#include <stdio.h>
#include <sys/types.h>
#include <unistd.h>
#include <string.h>
#include <pwd.h>
main ()
{
	uid_t ruid;
	char name[] = "ispconfig";
	struct passwd *pw;
	int admin = 0;

	ruid = getuid();
	pw = getpwuid(ruid);

	if (strcmp(pw->pw_name, name) == 0) admin = 1;

	if (admin == 1)
	{
		setuid(0);
		setgid(0);
		//setegid(0);
		//seteuid(0);
		execv("/usr/local/ispconfig/interface/web/csf/ispconfig_csf.cgi", NULL);
	} else {
		printf("Permission denied [User:%s UID:%d]\n", pw->pw_name, ruid);
	}
	return 0;
}
