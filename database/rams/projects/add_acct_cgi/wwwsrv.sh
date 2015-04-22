#Use the command to create the link in /usr/wwwsrv area
( cd /usr/wwwsrv/ ;		\
	chmod 777 cgi-su ;	\
	cd cgi-su ;		\
	chmod 777 costing ;	\
	su costing -c "cd /usr/wwwsrv/cgi-su/costing/alpha;\
	ln -s x acct_add" ;	\
	cd /usr/wwwsrv/cgi-su ;	\
	chmod 755 costing ;	\
	cd /usr/wwwsrv ;	\
	chmod 700 cgi-su 	\
)
