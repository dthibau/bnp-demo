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

def checkSonarQualityGate(){
    // Get properties from report file to call SonarQube 
    def sonarReportProps = readProperties  file: 'target/sonar/report-task.txt'
    def sonarServerUrl = sonarReportProps['serverUrl']
    def ceTaskUrl = sonarReportProps['ceTaskUrl']
    def ceTask

    // Get task informations to get the status
    timeout(time: 4, unit: 'MINUTES') {
        waitUntil {
            withCredentials ([string(credentialsId: 'SONAR_TOKEN', variable : 'token')]) {
                def response = sh(script: "curl -u ${token}: ${ceTaskUrl}", returnStdout: true).trim()
                ceTask = readJSON text: response
            }

            echo ceTask.toString()
              return "SUCCESS".equals(ceTask['task']['status'])
        }
    }

    // Get project analysis informations to check the status
    def ceTaskAnalysisId = ceTask['task']['analysisId']
    def qualitygate

    withCredentials ([string(credentialsId: 'SONAR_TOKEN', variable : 'token')]) {
        def response = sh(script: "curl -u ${token}: ${sonarServerUrl}/api/qualitygates/project_status?analysisId=${ceTaskAnalysisId}", returnStdout: true).trim()
        qualitygate =  readJSON text: response
    }

    echo qualitygate.toString()
    if ("ERROR".equals(qualitygate['projectStatus']['status'])) {
        unstable "Quality Gate failure"
    }
}

