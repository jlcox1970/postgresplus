class postgresplus::replication (
  $user           = $postgresplus::user,
  $repl_mode      = $postgresplus::repl_mode,
  $replication    = $postgresplus::replication,
  $repl_mode      = $postgresplus::repl_mode,
  $repl_user      = $postgresplus::repl_user,
  $repl_pass      = $postgresplus::repl_pass,
  $datadir        = $postgresplus::datadir,
  $bindir         = $postgresplus::bindir,
  $serverport        = $postgresplus::serverport,
  $repl_target_address = pick($postgresplus::repl_target_address, 'all'),
  $repl_auth_method    = pick($postgresplus::repl_auth_method , 'trust'),
  $ppa_service         = $postgresplus::ppa_service,
) {

  $recovery_conf = "${datadir}/recovery.conf"

  if ( $repl_mode != false) {
    if ( $repl_mode == 'master' ) {
      if ( $repl_target_address != undef ) {
        notify { "setting up tags for target" :}
        @@exec { 'create_postgres_target':
          cwd     => '/tmp',
          command => "${bindir}/pg_basebackup -h ${ipaddress} -U ${repl_user} -D ${datadir} -c fast -Xs ",
          notify  => [
            Service["${postgresplus::ppa_service}"],
          ],
          tag    => 'create_postgres_target',
#          before => Exec["setup perms on DB files"],
          onlyif => "/usr/bin/test ! -f ${recovery_conf}",
        }
        @@file { "${recovery_conf}" :
          ensure  => file,
          content => template('postgresplus/recovery.conf.erb'),
          tag     => "recovery_conf",
          before  => Exec["setup perms on DB files"],
        }
        postgresplus::hba_config { 'allow replication access':
          description => "Open up postgresql for replication PPAS",
          type        => 'host',
          database    => 'replication',
          user        => "${repl_user}",
          address     => "${repl_target_address}",
          auth_method => "${repl_auth_method}",
        }->
        postgresplus::hba_config { 'allow local trust access':
         type         => 'local',
         database     => 'all',
         user         => 'all',
         auth_method  => 'trust',
         description  => "Open up postgresql for local trust access",
        }->
        exec {'replication restart':
          command => "/sbin/service ${postgresplus::ppa_service} restart",
        }->
        postgresplus::role { "${repl_user}":
          replication   => true,
          password_hash => postgresql_password ( "${repl_user}", "mypassword" ),
        }
      }
    } else {
      if ( $repl_mode == 'target' ) {
        exec {'stop replication target server' :
          command  => "/sbin/service ${postgresplus::ppa_service} stop ; /bin/true",
          onlyif   => "/usr/bin/test ! -f ${recovery_conf}",
        }->
        exec {'remove non replicated database' :
          command => "/bin/rm -fr ${datadir}/* ",
          onlyif   => "/usr/bin/test ! -f ${recovery_conf}",
        }->
        notify { "applying tags to target" :} ->
        Exec <<| tag == 'create_postgres_target' |>> ->
        File <<| tag == "recovery_conf" |>> ->
        exec {'setup perms on DB files' :
          command => "/bin/chown -R ${postgresplus::user}:${postgresplus::group} ${datadir}",
        } ->
        service { $ppa_service :
          ensure => runnning,
          enable => tue
        }
      }
    }
  }

}
