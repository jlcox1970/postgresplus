# == Class: postgresplus
#
# Install PostgresPlus (EnterpriseDB) server with streaming replication targets.
# This requires that use are using PuppetDB.
#
# === Parameters
# [file_name]
#   This the base part of the file name that will be used for the installer
#     ie ppametta is the base for ppasmeta-9.3.1.3-linux-x64.tar.gz
#
# [version]
#   The version of the file that is to be used for installing 
#
# [arch]
#   Install architecture
#
# [url_base]
#   URL location for downloading the installer from (less actual file name)
#
# [superpassword]
#   Database super user password
#
# [webusername]
#   User name for accessing the Enterprise DB website.
#   This is required for installing the appliaction.
#
# [webpassword]
#   Password for the above account
#
# [serverport]
#   SQL server port. Default 5444
#
# [key]
#   installation key
#
# [with_jre]
#   install JRE to enable JRE DB tools
#
# [java_package]
#   JRE to install
#
# [install_path]
#   Path to install PostgrePlus into
#
# [user]
#   install user and account to run database as
#
# [group]
#   install group and account to run database as
#
# [replication]
#   enable replication. Defaults to false
#
# [repl_mode]
#   mode for the replication on this server. Defaults to master
#
# [repl_user]
#   User to be setup in the master for the replication
#
# [repl_pass]
#   Password for the above user
#
# [repl_target_address]
#   ACL address for the replication link
#
# [auth_method]
#   ACL auth method
#
# === Authors
#
# Jason Cox <j_cox@bigpond.com>
#
# === Copyright
#
# Copyright 2014 Jason Cox, unless otherwise noted.
#
# http://get.enterprisedb.com/ga/ppasmeta-9.3.1.3-linux-x64.tar.gz

class postgresplus (
  $file_name = 'ppasmeta',
  $version = '9.3.1.3',
  $arch = 'linux-x64',
  $url_base = 'http://get.enterprisedb.com/ga',
  $superpassword = '',
  $webusername = '',
  $webpassword = '',
  $serverport = '5444',
  $key = '',
  $with_jre = false,
  $java_package = 'java-1.6.0-openjdk',
  $install_path = '/opt/PostgresPlus',
  $user = 'enterprisedb',
  $group = 'enterprisedb',
  $replication = false,
  $repl_mode = 'master',
  $repl_user = 'replicator',
  $repl_pass = 'replicator',
  $repl_target_address = 'all',
  $repl_auth_method = 'trust',
  $auth_method = 'trust',
  $encoding = undef,
  $locale = undef,
  $database = ''
){
 
  include concat::setup

  $inst_mode = 'unattened'
  $v_number         = split ( $version , '[.]' )
  $v_major          = $v_number[0]
  $v_minor          = $v_number [1]
  $ver              = "$v_number[0].$v_number[1]"
  $pg_hba_conf_path = "$install_path/${v_major}.${v_minor}AS/data/pg_hba.conf"
  $pg_conf_path     = "$install_path/${v_major}.${v_minor}AS/data/postgresql.conf"
  $ppa_service      = "ppas-${v_major}.${v_minor}"
  $datadir          = "$install_path/${v_major}.${v_minor}AS/data"
  $bindir           = "$install_path/${v_major}.${v_minor}AS/bin"
  $psql_path        = "$bindir/psql"
  $bin_file         = "${file_name}-${version}-${arch}"
  $createdb_path    = "${bindir}/createdb"
  
  unless $superpassword {
    class {postgresplus::clean :}
    fail ( " Super User password not set")
  }
  unless $webusername {
    class {postgresplus::clean :}
    fail ( "Web User Name not set")
  }
  unless $webpassword {
    class {postgresplus::clean :}
    fail ("Web Password not set")
  }
  unless $key {
    class {postgresplus::clean :}
    fail ("Product Key not set")
  }
  $productkey = "--productkey \"${key}\""
  $SP         = "--superpassword \"${superpassword}\""
  $wuser      = "--webusername \"${webusername}\""
  $wpass      = "--webpassword \"${webpassword}\""
  $port       = "--serverport \"${serverport}\""

  if ( $repl_mode == 'master' ){
    class { postgresplus::service :
    }
  }

  if $with_jre == true {

    package { $java_package :
    }->
    exec {'Download PPA':
      cwd     => '/tmp',
      command => "wget ${url_base}/${bin_file}.tar.gz -O ${bin_file}.tar.gz",
      path    => '/usr/bin',
      creates => "/tmp/${bin_file}.tar.gz",
      require => Package[$java_package],
    }
  }
  else {
    exec {'Download PPA':
      cwd     => '/tmp',
      command => "wget ${url_base}/${bin_file}.tar.gz -O ${bin_file}.tar.gz",
      path    => '/usr/bin',
      creates => "/tmp/${bin_file}.tar.gz",
    }
  }

  anchor { 'postgresplus::start' : } ->
  exec {'Unpack PPA':
    cwd         => '/tmp',
    command     => "tar zxf ${bin_file}.tar.gz",
    path        => '/bin',
    subscribe   => Exec['Download PPA'],
    refreshonly => true,
  }->
  exec {'SeLinux Permissive':
    path        => '/usr/sbin',
    command     => 'setenforce Permissive',
    subscribe   => Exec['Unpack PPA'],
    refreshonly => true,
  }->
  exec {'Install PPA':
    cwd       => "/tmp/${bin_file}",
    command   => "${bin_file}.run --mode unattended ${SP} ${wuser} ${wpass} ${port} ${productkey} ",
    path      => "/tmp/${bin_file}:/usr/bin:/bin",
    onlyif    => "test ! -d /opt/PostgresPlus/${v_major}.${v_minor}AS",
  }->
  exec {'SeLinux Enforcing':
    path        => '/usr/sbin',
    command     => 'setenforce Enforcing',
    subscribe   => Exec['Install PPA'],
    refreshonly => true,
  }->
  concat { $pg_hba_conf_path:
    owner   => $user,
    group   => $group,
    mode    => '0600',
  }->
  Service <| tag == 'ppa_service' |> ->
  anchor { 'postgresplus::end' : }
}
