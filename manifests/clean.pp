# This will clean up a failed install so the redepolyment is tried

class postgresplus::clean {
  exec {'remove installer':
    cwd     => '/tmp',
    command => 'rm /tmp/ppa* -fr',
  }
}
