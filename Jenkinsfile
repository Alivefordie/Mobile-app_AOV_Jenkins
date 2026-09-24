pipeline {
    agent {
        docker {
            image 'node:20-alpine'
            label 'linux-agent'
        }
    }

    stages {
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
                    sh 'npm test'
                }
            }
        }
    }
}