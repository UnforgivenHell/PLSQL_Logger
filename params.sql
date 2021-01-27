def sid           = develop

-- tablespaces
def data_tbs      = users
def index_tbs     = users
def temp_tbs      = TEMP

-- work data connect 
def user_name     = test_user
def user_psw      = test_user

def debug         = true

set serveroutput on size 1000000
spool _Log\&2..log
set ver off

@&1

spool off

exit
