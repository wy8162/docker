export ORACLE_BASE=/opt/app/oracle
export ORACLE_HOME=$ORACLE_BASE/wls12120
export MW_HOME=$ORACLE_HOME
export WLS_HOME=$MW_HOME/wlserver
export WL_HOME=$WLS_HOME
export DOMAIN_BASE=/home/oracle/wls
export DOMAIN_HOME=$DOMAIN_BASE/mydomain

export PATH=$PATH:$DOMAIN_HOME/bin:$WLS_HOME/common/bin

$DOMAIN_HOME/bin/setDomainEnv.sh