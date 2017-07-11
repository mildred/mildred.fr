// vim: tw=0:ft=groovy
pipeline {
  agent {
    // Requires 'ps' to be able to function correctly (package procps)
    dockerfile { dir 'build' }
  }
  stages {
    stage('Dependencies') {
      steps {
        sh 'make install'
      }
    }
    stage('Build') {
      steps {
        sh 'make check=0 check_out=0'
      }
    }
    stage('Deploy') {
      steps {
        sshagent(credentials: ['ssh_deploy_www.mildred.fr']){
          sh 'rsync -e "ssh -o UserKnownHostsFile=build/known_hosts" -ra --delete out/ rsync@perrin2.mildred.fr:'
        }
      }
    }
  }
}

