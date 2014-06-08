define postgresplus::hba_config (
  $type        = '',
  $database    = '',
  $user        = 'enterprisedb',
  $group       = '',
  $auth_method = '',
  $address     = undef,
  $description = 'none',
  $auth_option = undef,
  $order       = '150',
  # Needed for testing primarily, support for multiple files is not really
  # working.
  $target      = $postgresplus::pg_hba_conf_path,
  $hba_group       = 'enterprisedb',
  $hba_user        = 'enterprisedb',
) {

  include concat::setup
  validate_re($type, '^(local|host|hostssl|hostnossl)$',
  "The type [${type}] is incorect for pg_hba.conf")

  if($type =~ /^host/ and $address == undef) {
    fail('You must specify an address property when type is host based')
  }
  $fragname = "pg_hba_rule_${name}" 
  
  concat::fragment { $fragname:
    target  => $target,
    content => template('postgresplus/pg_hba_rule.conf'),
    order   => $order,
    notify  => Service["$postgresplus::service::service"],
  }
}
