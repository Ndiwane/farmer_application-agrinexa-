pipeline {
    agent any

    environment {
        FLUTTER_HOME = 'C:\\flutter_windows_3.41.2-stable\\flutter'
        PATH = "${FLUTTER_HOME}\\bin;${env.PATH}"
    }

    stages {
        stage('Fix Git Safe Directory') {
            steps {
                bat 'git config --global --add safe.directory C:/flutter_windows_3.41.2-stable/flutter'
                bat 'git config --global --add safe.directory *'
            }
        }

        stage('Clone Code') {
            steps {
                echo 'Cloning AgriNexa repository...'
                checkout scm
            }
        }

        stage('Flutter Doctor') {
            steps {
                bat 'flutter doctor'
            }
        }

        stage('Analyze Code') {
            steps {
             bat 'flutter analyze || exit 0'
            }
        }
        stage('Analyze Code') {
            steps {
                bat 'flutter analyze'
            }
        }

        stage('Run Tests') {
            steps {
                bat 'flutter test'
            }
        }

        stage('Build APK') {
            steps {
                bat 'flutter build apk --release'
            }
        }
    }

    post {
        success {
            echo '✅ AgriNexa Build Successful!'
        }
        failure {
            echo '❌ AgriNexa Build Failed! Check the logs.'
        }
    }
}