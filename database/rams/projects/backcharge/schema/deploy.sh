#!/bin/sh

#add a new entry to local machine cgi-su/costing
chmod 777 /usr/wwwsrv/cgi-su/; \
(su costing -c 'cd /usr/wwwsrv/cgi-su/costing/alpha;ln -s x report');\
chmod 700 /usr/wwwsrv/cgi-su/
