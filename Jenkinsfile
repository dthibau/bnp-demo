@Library('UTIL') _
def dataCenters
def integrationUrl

pipeline {
   agent none 
    tools {
        jdk 'JDK17'
        maven 'MAVEN3'
    }


    stages {
        stage('Compile et tests') {
            agent any
            steps {
                echo 'Unit test et packaging'
                sh 'mvn -Dmaven.test.failure.ignore=true clean package'
                dir('application/target') {
                    stash includes: '*.jar', name: 'app'
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
        
        stage('Analyse qualité et vulnérabilités') {
            parallel {
                stage('Vulnérabilités') {
                    agent any
                    steps {
                        echo 'Tests de Vulnérabilités OWASP'
                        sh 'mvn -DskipTests verify'
                    }
                    
                }
                 stage('Analyse Sonar') {
                    agent any
                    environment {
                        SONAR_TOKEN = credentials('SONAR_TOKEN')
                    }
                     steps {
                        echo 'Analyse sonar'
                        sh 'mvn -Dsonar.token=${SONAR_TOKEN} clean integration-test sonar:sonar'
                        script {
                            checkSonarQualityGate()
                        }
                     }
                    
                }
            }
            
        }

        stage('Read conf') {
            agent any
            steps {
                echo "Lecture des dataCenters"
                script {
                    def jsonData = readJSON file: './deployment.json'
                    integrationUrl = jsonData['integrationURL'];
                    dataCenters = jsonData['dataCenters']
                    echo "dataCenters ${dataCenters}"
                }
            }
        }
        stage ('Release') {
            agent any

            steps {
                createTarGz(
                    sourceDir: 'library/src/main/java',
                    extensions: ['java'],
                    outputDir: '.',
                    outputFile: 'lib-src-dist'
                )
                sh "cp lib-src-dist.tar.gz /home/dthibau/Formations/Jenkins/MyWork"
            }
        }
        stage('Validation déploiement') {
/*            when {
                branch 'main'
                beforeOptions true
                beforeInput true
                beforeAgent true
            } */
            agent none
            steps {
                input message: "Voulez vous déployer vers $dataCenters", ok: 'Déployer'
                echo "Déploiement intégration validé"
            }
        }

        stage('Déploiement intégration') {
/*            when {
                branch 'main'
                beforeOptions true
                beforeInput true
                beforeAgent true
            } */
            agent any
            steps {
                echo "Déploiement intégration vers les data centers"
                unstash 'app'
                script {
                    for ( dataCenter in dataCenters ) {
                        sh "cp *.jar $integrationUrl/${dataCenter}.jar"
                    }
                }
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

