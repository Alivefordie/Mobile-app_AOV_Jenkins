pipeline {
    agent {
        docker {
            image 'node:20-alpine'
            label 'linux-agent'
        }
    }

    environment {
        APP_NAME = 'taskflow-api'
        NODE_ENV = 'test'
    }

    options {
        // A pipeline should never run unbounded because a hung build can waste agent resources indefinitely.
        timeout(time: 10, unit: 'MINUTES')
    }

    stages {
        stage('Environment') {
            steps {
                echo "APP_NAME=${APP_NAME}, NODE_ENV=${NODE_ENV}"
            }
        }

        stage('Install') {
            steps {
                dir('backend') {
                    sh 'npm ci'
                }
            }
        }

        stage('Lint') {
            steps {
                dir('backend') {
                    sh 'npm run lint'
                }
            }
        }

    stage('Unit Test') {
        steps {
            dir('backend') {
                sh 'npm test -- --coverage --reporters=jest-junit'
            }
        }

        post {
            always {
                dir('backend') {
                    junit 'reports/junit.xml'

                    recordCoverage(
                        tools: [[
                            parser: 'COBERTURA',
                            pattern: 'coverage/cobertura-coverage.xml'
                        ]]
                    )
                }
            }
        }
    }

    stage('SonarQube Analysis') {
        steps {
            dir('backend') {
                withSonarQubeEnv('SonarQube') {
                    sh '''
                       sonar-scanner \
                        -Dsonar.projectKey=taskflow-api \
                        -Dsonar.sources=src \
                        -Dsonar.tests=src \
                        -Dsonar.exclusions=**/*.spec.ts \
                        -Dsonar.test.inclusions=**/*.spec.ts \
                        -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info
                    '''
                }
            }
        }
    }

    stage('Quality Gate') {
        steps {
            timeout(time: 5, unit: 'MINUTES') {
                waitForQualityGate abortPipeline: true
            }
        }
    }
}
    post {
        success {
            echo "${env.APP_NAME} Pipeline completed successfully on ${env.NODE_ENV} environment."
        }

        failure {
            echo "${env.APP_NAME} Pipeline failed at stage: ${env.STAGE_NAME}."
        }

        always {
            archiveArtifacts artifacts: '**/npm-debug.log*',
                             allowEmptyArchive: true
        }
    }
}