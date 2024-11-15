def dataCenters
def integrationUrl

pipeline {
   agent none 

    stages {
        stage('Compile et tests') {
            agent {
                kubernetes {
                    inheritFrom 'maven3-jdk17-agent'
                }
            }
            steps {
                container('maven3-openjdk-17') {
                   echo 'Unit test et packaging'
                    sh 'mvn -Dmaven.test.failure.ignore=true clean package'
                    dir('application/target') {
                        stash includes: '*.jar', name: 'app'
                    }
                }
                
            }
            post {
                always {
                    junit '**/target/surefire-reports/*.xml'                }
                success {
                    archiveArtifacts artifacts: '**/target/*.jar', followSymlinks: false
                }
                unsuccessful {
                    mail bcc: '', body: 'Please review', cc: '', from: '', replyTo: '', subject: 'Build failed', to: 'david.thibau@sparks.com'
                }
            }
        }
        
    }  
}
